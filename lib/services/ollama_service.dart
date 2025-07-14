import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/onenote_page.dart';
import '../models/excel_template.dart';

class OllamaService {
  late http.Client _httpClient;
  final String baseUrl;
  final List<http.Request> _pendingRequests = [];

  OllamaService({this.baseUrl = 'http://localhost:11434'}) {
    _httpClient = http.Client();
  }

  Future<List<Map<String, dynamic>>> processPages(
    List<OneNotePage> pages,
    ExcelTemplate? template,
    String customPrompt,
  ) async {
    final results = <Map<String, dynamic>>[];
    const model = 'llama2:latest';

    for (final page in pages) {
      try {
        final prompt = _buildPrompt(page, template, customPrompt);
        final response = await _makeRequest(prompt, model);

        if (response.statusCode == 200) {
          final result = _processResponse(response, page, template, customPrompt);
          results.add(result);
        } else {
          print('Error processing page ${page.title}: ${response.statusCode}');
          results.add({
            'page_title': page.title,
            'error': 'HTTP ${response.statusCode}: ${response.body}',
          });
        }
      } catch (e) {
        print('Exception processing page ${page.title}: $e');
        results.add({
          'page_title': page.title,
          'error': 'Exception: $e',
        });
      }
    }

    return results;
  }

  Future<http.Response> _makeRequest(String prompt, String model) async {
    return await _httpClient.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'stream': false,
        'options': {
          'temperature': 0.1,
          'num_predict': 1000,
        }
      }),
    ).timeout(const Duration(seconds: 30));
  }

  Map<String, dynamic> _processResponse(
    http.Response response,
    OneNotePage page,
    ExcelTemplate? template,
    String customPrompt,
  ) {
    try {
      final responseData = jsonDecode(response.body);
      final extractedText = responseData['response'] ?? '';

      final result = <String, dynamic>{};

      if (template != null && template.columns.isNotEmpty) {
        // Parse structured response based on template
        result.addAll(_parseStructuredResponse(extractedText, template));
      } else {
        // For no template, create dynamic structured output based on custom prompt
        result.addAll(_parseCustomPromptResponse(extractedText, customPrompt));
      }

      return result;
    } catch (e) {
      return {
        'page_title': page.title,
        'error': 'Failed to parse response: $e',
        'raw_response': response.body,
      };
    }
  }

  Map<String, dynamic> _parseStructuredResponse(String text, ExcelTemplate template) {
    final result = <String, dynamic>{};
    
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0 && colonIndex < line.length - 1) {
        final fieldName = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        
        for (final column in template.columns) {
          if (_fieldMatches(fieldName, column)) {
            result[column] = _cleanValue(value);
            break;
          }
        }
      }
    }
    
    for (final column in template.columns) {
      if (!result.containsKey(column)) {
        result[column] = 'N/A';
      }
    }
    
    return result;
  }

  Map<String, dynamic> _parseCustomPromptResponse(String text, String customPrompt) {
    final result = <String, dynamic>{};
    
    // Get the allowed fields from the prompt
    final allowedFields = _extractFieldNamesFromPrompt(customPrompt);
    
    // If no fields found in prompt, create normalized versions from the response
    if (allowedFields.isEmpty) {
      return _parseResponseWithoutPromptFields(text);
    }
    
    // Parse the AI response for field:value pairs
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0 && colonIndex < line.length - 1) {
        final fieldName = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        
        // Skip obviously bad responses and generic examples
        if (value.isEmpty || value.toLowerCase().contains('not specified') || 
            value.toLowerCase().contains('none mentioned') ||
            value.toLowerCase() == 'value' ||  // Skip generic "value" responses
            value.toLowerCase().contains('[actual') ||  // Skip example placeholders
            value.toLowerCase().contains('if found') ||
            fieldName.toLowerCase().contains('note') && value.length > 100) {
          continue;
        }
        
        // STRICT FILTERING: Only allow fields that match the prompt
        final matchingPromptField = _findMatchingPromptField(fieldName, allowedFields);
        if (matchingPromptField != null) {
          final cleanedValue = _cleanValue(value);
          // Update if we don't have this field yet or if the new value is better
          if (!result.containsKey(matchingPromptField) || 
              (result[matchingPromptField] == 'N/A' && cleanedValue != 'N/A')) {
            result[matchingPromptField] = cleanedValue;
          }
        }
      }
    }
    
    // Fill in N/A for any missing fields from the prompt
    for (final field in allowedFields) {
      if (!result.containsKey(field)) {
        result[field] = 'N/A';
      }
    }
    
    // If no structured data found, create summary
    if (result.isEmpty && allowedFields.isNotEmpty) {
      result[allowedFields.first] = _cleanText(text);
    }
    
    return result;
  }

  /// Parse response without strict prompt field filtering (fallback)
  Map<String, dynamic> _parseResponseWithoutPromptFields(String text) {
    final result = <String, dynamic>{};
    
    // Parse the AI response for field:value pairs
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0 && colonIndex < line.length - 1) {
        final fieldName = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        
        // Skip obviously bad responses and generic examples
        if (value.isEmpty || value.toLowerCase().contains('not specified') || 
            value.toLowerCase().contains('none mentioned') ||
            value.toLowerCase() == 'value' ||  // Skip generic "value" responses
            value.toLowerCase().contains('[actual') ||  // Skip example placeholders
            value.toLowerCase().contains('if found') ||
            fieldName.toLowerCase().contains('note') && value.length > 100) {
          continue;
        }
        
        // Clean the field name but keep it close to what AI provided
        final cleanFieldName = _capitalizeFieldName(fieldName);
        if (cleanFieldName.isNotEmpty && cleanFieldName.length < 50) {
          // Check for duplicate or similar field names before adding
          final existingKey = _findSimilarFieldName(result.keys.toList(), cleanFieldName);
          if (existingKey != null) {
            // Update existing field if the new value is better (not N/A and not empty)
            final cleanedValue = _cleanValue(value);
            if (cleanedValue != 'N/A' && cleanedValue.isNotEmpty && 
                (result[existingKey] == 'N/A' || result[existingKey].toString().isEmpty)) {
              result[existingKey] = cleanedValue;
            }
          } else {
            result[cleanFieldName] = _cleanValue(value);
          }
        }
      }
    }
    
    // If no structured data found, create summary
    if (result.isEmpty) {
      result['Extracted Information'] = _cleanText(text);
    }
    
    return result;
  }

  /// Find the matching field from the prompt that corresponds to the AI response field
  String? _findMatchingPromptField(String responseField, List<String> promptFields) {
    final respNormalized = _normalizeFieldName(responseField);
    
    // First try exact match
    for (final promptField in promptFields) {
      if (_normalizeFieldName(promptField) == respNormalized) {
        return promptField;
      }
    }
    
    // Then try fuzzy matching
    for (final promptField in promptFields) {
      if (_fieldMatches(responseField, promptField)) {
        return promptField;
      }
    }
    
    return null;
  }

  bool _fieldMatches(String responseField, String templateColumn) {
    final respLower = responseField.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final tempLower = templateColumn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    return respLower == tempLower || 
           respLower.contains(tempLower) || 
           tempLower.contains(respLower);
  }

  String _cleanValue(String value) {
    if (value.isEmpty) return 'N/A';
    
    String cleaned = value
        .replaceAll(RegExp(r'^(none mentioned|not available|not found|not specified)', caseSensitive: false), 'N/A')
        .replaceAll(RegExp(r'^(in the text|in the provided text|in the document)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.$'), '')
        .replaceAll(RegExp(r'\r\n|\r|\n'), ' ')  // Replace all line breaks with spaces
        .replaceAll(RegExp(r'\t'), ' ')  // Replace tabs with spaces
        .replaceAll(RegExp(r'\s+'), ' ')  // Replace multiple spaces with single space
        .trim();
    
    // SUPER AGGRESSIVE cleanup - remove ALL formatting artifacts
    cleaned = cleaned
        .replaceAll(RegExp(r'^[\s\-\*\•\>\<\|\[\]\{\}]+'), '')  // Remove leading symbols/whitespace
        .replaceAll(RegExp(r'[\s\-\*\•\>\<\|\[\]\{\}]+$'), '')  // Remove trailing symbols/whitespace
        .replaceAll(RegExp(r'\s*[,;:]\s*$'), '')  // Remove trailing punctuation
        .replaceAll(RegExp(r'\s{2,}'), ' ')  // Multiple spaces to single space
        .replaceAll(RegExp(r'^\s+'), '')  // Remove any leading whitespace
        .replaceAll(RegExp(r'\s+$'), '')  // Remove any trailing whitespace
        .trim();
    
    // Final paranoid cleanup - ensure absolutely no trailing/leading whitespace
    while (cleaned.startsWith(' ') || cleaned.startsWith('\t') || cleaned.startsWith('\n')) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.endsWith(' ') || cleaned.endsWith('\t') || cleaned.endsWith('\n')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    return cleaned.isEmpty ? 'N/A' : cleaned;
  }

  String _capitalizeFieldName(String fieldName) {
    // Remove bullet points and clean the field name
    String cleaned = fieldName
        .replaceAll(RegExp(r'^[\*\-\•]\s*'), '')  // Remove bullets at start
        .trim();
    
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _cleanText(String text) {
    return text.length > 200 ? '${text.substring(0, 200)}...' : text;
  }

  String _buildPrompt(OneNotePage page, ExcelTemplate? template, String customPrompt) {
    final basePrompt = StringBuffer();
    
    if (template != null && template.columns.isNotEmpty) {
      // Template-based extraction
      basePrompt.writeln('Extract data from the following text and provide ONLY the values for each field.');
      basePrompt.writeln('Format your response as field:value pairs, one per line.');
      basePrompt.writeln('Required fields:');
      for (final column in template.columns) {
        basePrompt.writeln('$column: [value or N/A]');
      }
      basePrompt.writeln('');
      basePrompt.writeln('Text to analyze:');
      basePrompt.writeln(page.content);
    } else {
      // Custom prompt-based extraction - derive fields from user's prompt
      basePrompt.writeln('Extract ONLY the following information from the text below.');
      basePrompt.writeln('Requirements: ${customPrompt.isNotEmpty ? customPrompt : 'Extract key business information'}');
      basePrompt.writeln('');
      
      // Parse the custom prompt to suggest field names
      final suggestedFields = _extractFieldNamesFromPrompt(customPrompt);
      if (suggestedFields.isNotEmpty) {
        basePrompt.writeln('Provide EXACTLY these fields and NOTHING else:');
        for (final field in suggestedFields) {
          basePrompt.writeln('$field: [value if found, or N/A]');
        }
        basePrompt.writeln('');
        basePrompt.writeln('IMPORTANT: Only provide the ${suggestedFields.length} fields listed above.');
        basePrompt.writeln('Do not add any additional fields or information.');
        basePrompt.writeln('Do not include explanatory text or comments.');
      } else {
        // Fallback if we can't parse the prompt
        basePrompt.writeln('Provide information in field:value format.');
        basePrompt.writeln('Create appropriate field names based on the requirements above.');
      }
      
      basePrompt.writeln('');
      basePrompt.writeln('Text to analyze:');
      basePrompt.writeln(page.content);
    }
    
    return basePrompt.toString();
  }

  /// Dispose of resources and cancel any pending requests
  void dispose() {
    // Clear pending requests list
    _pendingRequests.clear();
    
    // Close the HTTP client to free up resources
    _httpClient.close();
  }

  /// Find if there's already a similar field name in the result
  String? _findSimilarFieldName(List<String> existingFields, String newFieldName) {
    final newNormalized = _normalizeFieldName(newFieldName);
    
    for (final existing in existingFields) {
      final existingNormalized = _normalizeFieldName(existing);
      
      // Exact match
      if (newNormalized == existingNormalized) {
        return existing;
      }
      
      // Check for common variations
      if (_areFieldNamesSimilar(newNormalized, existingNormalized)) {
        // Return the simpler/cleaner field name
        return _getCleanerFieldName(existing, newFieldName);
      }
    }
    
    return null;
  }
  
  /// Choose the cleaner field name between two similar ones
  String _getCleanerFieldName(String field1, String field2) {
    // Remove "| something" suffixes for comparison
    final clean1 = field1.replaceAll(RegExp(r'\s*\|\s*[^|]*$'), '');
    final clean2 = field2.replaceAll(RegExp(r'\s*\|\s*[^|]*$'), '');
    
    // Prefer the one without "| something" suffix
    if (clean1.length == field1.length && clean2.length != field2.length) {
      return field1; // field1 has no suffix
    }
    if (clean2.length == field2.length && clean1.length != field1.length) {
      return field2; // field2 has no suffix
    }
    
    // If both have or don't have suffixes, prefer the shorter one
    return field1.length <= field2.length ? field1 : field2;
  }

  /// Normalize field name for comparison
  String _normalizeFieldName(String fieldName) {
    return fieldName
        .toLowerCase()
        .replaceAll(RegExp(r'^[\*\-\•]\s*'), '')  // Remove bullet points/asterisks at start
        .replaceAll(RegExp(r'\s*\|\s*[^|]*$'), '') // Remove "| something" at end (Contact Details | Broker → Contact Details)
        .replaceAll(RegExp(r'[^a-z0-9]'), '')     // Remove special chars  
        .replaceAll('client', 'company')          // Treat client as company
        .replaceAll('details', '')                // Remove 'details' suffix
        .replaceAll('information', '')            // Remove 'information' suffix
        .replaceAll('date', 'date')               // Normalize date fields
        .replaceAll('presentation', 'date')       // Treat presentation date as date
        .replaceAll('effective', 'date');         // Treat effective date as date
  }

  /// Check if two normalized field names are similar enough to be considered duplicates
  bool _areFieldNamesSimilar(String field1, String field2) {
    // Direct substring matches
    if (field1.contains(field2) || field2.contains(field1)) {
      return true;
    }
    
    // Common company field variations
    if ((field1.contains('company') && field2.contains('company')) ||
        (field1.contains('client') && field2.contains('company')) ||
        (field1.contains('company') && field2.contains('client'))) {
      return true;
    }
    
    // Contact field variations (very aggressive - any contact-related field)
    if (field1.contains('contact') && field2.contains('contact')) {
      return true;
    }
    
    // Date field variations (including presentation date, effective date, etc.)
    if (field1.contains('date') && field2.contains('date')) {
      return true;
    }
    
    // Financial field variations
    if (field1.contains('financial') && field2.contains('financial')) {
      return true;
    }
    
    // Status/outcome variations
    if ((field1.contains('status') && field2.contains('status')) ||
        (field1.contains('outcome') && field2.contains('outcome')) ||
        (field1.contains('status') && field2.contains('outcome')) ||
        (field1.contains('outcome') && field2.contains('status'))) {
      return true;
    }
    
    // Decision/action variations
    if ((field1.contains('decision') && field2.contains('decision')) ||
        (field1.contains('action') && field2.contains('action')) ||
        (field1.contains('decision') && field2.contains('action')) ||
        (field1.contains('action') && field2.contains('decision'))) {
      return true;
    }
    
    // Follow-up variations
    if (field1.contains('follow') && field2.contains('follow')) {
      return true;
    }
    
    return false;
  }

  /// Extract potential field names from the user's custom prompt
  List<String> _extractFieldNamesFromPrompt(String customPrompt) {
    final fields = <String>[];
    final lines = customPrompt.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Look for lines that start with "- " (bullet points)
      if (trimmed.startsWith('- ')) {
        String fieldName = trimmed.substring(2).trim();
        
        // Clean up the field name
        fieldName = fieldName
            .replaceAll(RegExp(r'\s+or\s+'), ' / ')  // "Company or Client" -> "Company / Client"
            .replaceAll(RegExp(r'\s+and\s+'), ' & ')  // "Date and time" -> "Date & time"
            .replaceAll(RegExp(r'^Any\s+', caseSensitive: false), '') // Remove "Any" prefix
            .trim();
        
        // Capitalize properly
        fieldName = _capitalizeFieldName(fieldName);
        
        if (fieldName.isNotEmpty && fieldName.length < 50) {
          fields.add(fieldName);
        }
      }
    }
    
    // If no bullet points found, try to extract from other patterns
    if (fields.isEmpty) {
      // Look for patterns like "Focus on:" followed by items
      final focusMatch = RegExp(r'focus on:(.+)', caseSensitive: false).firstMatch(customPrompt);
      if (focusMatch != null) {
        final focusText = focusMatch.group(1) ?? '';
        final items = focusText.split(',');
        for (final item in items) {
          final cleaned = item.trim().replaceAll(RegExp(r'^-\s*'), '');
          if (cleaned.isNotEmpty) {
            fields.add(_capitalizeFieldName(cleaned));
          }
        }
      }
    }
    
    return fields;
  }

  /// Process Excel data using AI to map and restructure columns
  Future<List<Map<String, dynamic>>> processExcelData(
    Map<String, dynamic> excelData,
    String customPrompt, {
    int? maxRows,
  }) async {
    final results = <Map<String, dynamic>>[];
    const model = 'llama2:latest';

    try {
      final allData = excelData['allData'] as List<Map<String, dynamic>>;
      final headers = excelData['headers'] as List<String>;
      final totalRows = allData.length;
      
      // Process in batches for large datasets
      final batchSize = maxRows ?? (totalRows > 100 ? 50 : totalRows);
      final batches = <List<Map<String, dynamic>>>[];
      
      for (int i = 0; i < totalRows; i += batchSize) {
        final end = (i + batchSize < totalRows) ? i + batchSize : totalRows;
        batches.add(allData.sublist(i, end));
      }

      print('Processing ${batches.length} batches of Excel data...');

      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];
        print('Processing batch ${batchIndex + 1}/${batches.length} (${batch.length} rows)');

        try {
          final prompt = _buildExcelPrompt(batch, headers, customPrompt, batchIndex + 1);
          final response = await _makeRequest(prompt, model);

          if (response.statusCode == 200) {
            final batchResults = _processExcelResponse(response, batch, customPrompt);
            results.addAll(batchResults);
          } else {
            print('Error processing batch ${batchIndex + 1}: ${response.statusCode}');
            // Add error entries for this batch
            for (int i = 0; i < batch.length; i++) {
              results.add({
                'error': 'HTTP ${response.statusCode}',
                'batch_number': batchIndex + 1,
                'row_index': i,
                ...batch[i], // Include original data
              });
            }
          }
        } catch (e) {
          print('Exception processing batch ${batchIndex + 1}: $e');
          // Add error entries for this batch
          for (int i = 0; i < batch.length; i++) {
            results.add({
              'error': 'Exception: $e',
              'batch_number': batchIndex + 1,
              'row_index': i,
              ...batch[i], // Include original data
            });
          }
        }
      }

      print('Excel processing complete. Processed ${results.length} total rows.');
      return results;

    } catch (e) {
      print('Critical error in Excel processing: $e');
      throw Exception('Failed to process Excel data: $e');
    }
  }

  /// Build AI prompt for Excel data processing
  String _buildExcelPrompt(List<Map<String, dynamic>> batchData, List<String> headers, String customPrompt, int batchNumber) {
    final promptBuffer = StringBuffer();
    
    promptBuffer.writeln('You are processing Excel data. Your task is to map and restructure the data according to the user\'s requirements.');
    promptBuffer.writeln('');
    promptBuffer.writeln('USER REQUIREMENTS:');
    promptBuffer.writeln(customPrompt);
    promptBuffer.writeln('');
    promptBuffer.writeln('EXCEL DATA TO PROCESS (Batch $batchNumber):');
    promptBuffer.writeln('Available columns: ${headers.join(', ')}');
    promptBuffer.writeln('');
    
    // Include sample of the data
    for (int i = 0; i < batchData.length && i < 10; i++) {
      promptBuffer.writeln('Row ${i + 1}:');
      for (final header in headers) {
        final value = batchData[i][header] ?? '';
        if (value.toString().isNotEmpty) {
          promptBuffer.writeln('  $header: $value');
        }
      }
      promptBuffer.writeln('');
    }
    
    if (batchData.length > 10) {
      promptBuffer.writeln('... and ${batchData.length - 10} more rows with similar structure.');
      promptBuffer.writeln('');
    }
    
    promptBuffer.writeln('INSTRUCTIONS:');
    promptBuffer.writeln('1. Analyze the Excel data and map columns to the requested output fields');
    promptBuffer.writeln('2. Extract and transform data according to the user requirements');
    promptBuffer.writeln('3. Clean and standardize the data (remove extra spaces, normalize formats)');
    promptBuffer.writeln('4. Only include fields that are specifically requested in the user requirements');
    promptBuffer.writeln('5. If a requested field has no corresponding data, omit it or mark as empty');
    promptBuffer.writeln('6. Maintain data relationships and context from the original Excel structure');
    promptBuffer.writeln('');
    promptBuffer.writeln('OUTPUT FORMAT: Return ONLY a JSON array with the processed data. Each object should contain only the fields requested in the user requirements.');
    promptBuffer.writeln('Example: [{"field1": "value1", "field2": "value2"}, {"field1": "value3", "field2": "value4"}]');
    
    return promptBuffer.toString();
  }

  /// Process AI response for Excel data
  List<Map<String, dynamic>> _processExcelResponse(http.Response response, List<Map<String, dynamic>> originalBatch, String customPrompt) {
    try {
      final responseData = json.decode(response.body);
      final content = responseData['response'] as String? ?? '';

      if (content.isEmpty) {
        print('Empty response from AI');
        return _createFallbackExcelResults(originalBatch);
      }

      // Extract JSON from the response
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
      if (jsonMatch == null) {
        print('No JSON array found in response');
        return _createFallbackExcelResults(originalBatch);
      }

      final jsonString = jsonMatch.group(0)!;
      final parsedData = json.decode(jsonString) as List<dynamic>;

      final results = <Map<String, dynamic>>[];
      for (int i = 0; i < parsedData.length && i < originalBatch.length; i++) {
        final item = parsedData[i] as Map<String, dynamic>;
        final cleanedItem = <String, dynamic>{};

        // Clean all values and filter based on prompt requirements
        for (final entry in item.entries) {
          final cleanValue = _cleanValue(entry.value.toString());
          if (cleanValue.isNotEmpty) {
            cleanedItem[entry.key] = cleanValue;
          }
        }

        if (cleanedItem.isNotEmpty) {
          results.add(cleanedItem);
        }
      }

      return results.isNotEmpty ? results : _createFallbackExcelResults(originalBatch);

    } catch (e) {
      print('Error parsing Excel AI response: $e');
      return _createFallbackExcelResults(originalBatch);
    }
  }

  /// Create fallback results when AI processing fails
  List<Map<String, dynamic>> _createFallbackExcelResults(List<Map<String, dynamic>> originalBatch) {
    print('Creating fallback results for Excel batch');
    return originalBatch.map((row) {
      final cleaned = <String, dynamic>{};
      for (final entry in row.entries) {
        final cleanValue = _cleanValue(entry.value.toString());
        if (cleanValue.isNotEmpty) {
          cleaned[entry.key] = cleanValue;
        }
      }
      return cleaned;
    }).toList();
  }
}