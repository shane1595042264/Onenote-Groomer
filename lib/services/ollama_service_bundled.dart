import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/onenote_page.dart';
import '../models/excel_template.dart';

class OllamaService {
  late http.Client _httpClient;
  final String baseUrl;
  final List<http.Request> _pendingRequests = [];
  Process? _ollamaProcess;
  bool _isBundledOllama = false;
  String? _bundledOllamaPath;

  OllamaService({this.baseUrl = 'http://localhost:11434'}) {
    _httpClient = http.Client();
    _initializeBundledOllama();
  }

  /// Initialize bundled Ollama if available
  Future<void> _initializeBundledOllama() async {
    try {
      // Check for bundled Ollama in app directory
      final executableDir = path.dirname(Platform.resolvedExecutable);
      final bundledOllamaPath = path.join(executableDir, 'ollama', 'ollama.exe');
      
      if (await File(bundledOllamaPath).exists()) {
        _bundledOllamaPath = bundledOllamaPath;
        _isBundledOllama = true;
        print('Found bundled Ollama at: $bundledOllamaPath');
        await _startBundledOllama();
      } else {
        print('No bundled Ollama found, using system Ollama');
      }
    } catch (e) {
      print('Error initializing bundled Ollama: $e');
    }
  }

  /// Start the bundled Ollama process
  Future<bool> _startBundledOllama() async {
    if (!_isBundledOllama || _bundledOllamaPath == null) return false;

    try {
      // Set up environment for bundled Ollama
      final executableDir = path.dirname(Platform.resolvedExecutable);
      final ollamaHome = path.join(executableDir, 'ollama');
      
      final environment = Map<String, String>.from(Platform.environment);
      environment['OLLAMA_HOME'] = ollamaHome;
      environment['OLLAMA_MODELS'] = path.join(ollamaHome, 'models');
      environment['OLLAMA_HOST'] = '127.0.0.1:11434';

      print('Starting bundled Ollama...');
      _ollamaProcess = await Process.start(
        _bundledOllamaPath!,
        ['serve'],
        environment: environment,
        workingDirectory: ollamaHome,
      );

      // Wait a moment for Ollama to start
      await Future.delayed(const Duration(seconds: 3));
      
      // Verify Ollama is running
      final isRunning = await _checkOllamaHealth();
      if (isRunning) {
        print('Bundled Ollama started successfully');
        return true;
      } else {
        print('Failed to start bundled Ollama');
        return false;
      }
    } catch (e) {
      print('Error starting bundled Ollama: $e');
      return false;
    }
  }

  /// Check if Ollama is healthy and responsive
  Future<bool> _checkOllamaHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Ensure required model is available
  Future<bool> ensureModelAvailable(String modelName) async {
    try {
      // Check if model exists
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List?;
        
        if (models != null) {
          final hasModel = models.any((model) => 
            model['name']?.toString().startsWith(modelName) == true);
          
          if (hasModel) {
            return true;
          }
        }
      }

      // Model not found, try to pull it (for bundled Ollama, should be pre-installed)
      if (_isBundledOllama) {
        print('Model $modelName not found in bundled Ollama. This should not happen.');
        return false;
      } else {
        print('Pulling model $modelName...');
        return await _pullModel(modelName);
      }
    } catch (e) {
      print('Error checking model availability: $e');
      return false;
    }
  }

  /// Pull a model from Ollama registry
  Future<bool> _pullModel(String modelName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pull'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': modelName}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error pulling model: $e');
      return false;
    }
  }

  /// Get Ollama status for UI display
  Future<Map<String, dynamic>> getOllamaStatus() async {
    final isHealthy = await _checkOllamaHealth();
    
    return {
      'isRunning': isHealthy,
      'isBundled': _isBundledOllama,
      'version': _isBundledOllama ? 'Bundled' : 'System',
      'url': baseUrl,
    };
  }

  Future<List<Map<String, dynamic>>> processPages(
    List<OneNotePage> pages,
    ExcelTemplate? template,
    String customPrompt,
  ) async {
    // Ensure Ollama is ready
    final isReady = await _checkOllamaHealth();
    if (!isReady) {
      if (_isBundledOllama) {
        await _startBundledOllama();
      } else {
        throw Exception('Ollama is not running. Please start Ollama first.');
      }
    }

    // Ensure required model is available
    const model = 'llama2:latest';
    final hasModel = await ensureModelAvailable(model);
    if (!hasModel) {
      throw Exception('Required model $model is not available.');
    }

    final results = <Map<String, dynamic>>[];

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
    final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));
    request.headers['Content-Type'] = 'application/json';
    request.body = json.encode({
      'model': model,
      'prompt': prompt,
      'stream': false,
      'options': {
        'temperature': 0.1,
        'top_p': 0.9,
        'num_predict': 2048,
      },
    });

    _pendingRequests.add(request);

    try {
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return response;
    } finally {
      _pendingRequests.remove(request);
    }
  }

  String _buildPrompt(OneNotePage page, ExcelTemplate? template, String customPrompt) {
    final buffer = StringBuffer();
    
    // Define exact field names from custom prompt
    final requiredFields = [
      'Client or company name',
      'Deal value or pricing',
      'Sales stage or status',
      'Contact information',
      'Next steps or actions',
      'Closing date'
    ];
    
    buffer.writeln('EXTRACT THE FOLLOWING INFORMATION:');
    for (final field in requiredFields) {
      buffer.writeln('- $field');
    }
    buffer.writeln();
    
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln(customPrompt);
    buffer.writeln();
    
    buffer.writeln('PAGE CONTENT:');
    buffer.writeln('Title: ${page.title}');
    buffer.writeln('Content: ${page.content}');
    buffer.writeln();
    
    buffer.writeln('IMPORTANT: Return ONLY a JSON object using these EXACT field names:');
    buffer.writeln('{');
    for (int i = 0; i < requiredFields.length; i++) {
      final comma = i < requiredFields.length - 1 ? ',' : '';
      buffer.writeln('  "${requiredFields[i]}": "value"$comma');
    }
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('Do NOT use variations like "Client Name", "client_name", "Company Name", etc.');
    buffer.writeln('Use the EXACT field names listed above.');
    
    return buffer.toString();
  }

  /// Process Excel data using AI to map and restructure columns
  Future<List<Map<String, dynamic>>> processExcelData(
    Map<String, dynamic> excelData,
    String customPrompt, {
    int? maxRows,
  }) async {
    // Ensure Ollama is ready
    final isReady = await _checkOllamaHealth();
    if (!isReady) {
      if (_isBundledOllama) {
        await _startBundledOllama();
      } else {
        throw Exception('Ollama is not running. Please start Ollama first.');
      }
    }

    // Ensure required model is available
    const model = 'llama2:latest';
    final hasModel = await ensureModelAvailable(model);
    if (!hasModel) {
      throw Exception('Required model $model is not available.');
    }

    final results = <Map<String, dynamic>>[];

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
          final prompt = _buildExcelPrompt(batch, headers, customPrompt);
          final response = await _makeRequest(prompt, model);

          if (response.statusCode == 200) {
            final batchResults = _processExcelResponse(response, batch, batchIndex);
            results.addAll(batchResults);
          } else {
            print('Error processing batch ${batchIndex + 1}: ${response.statusCode}');
            // Add error entries for this batch
            for (int i = 0; i < batch.length; i++) {
              results.add({
                'row_index': batchIndex * batchSize + i,
                'error': 'HTTP ${response.statusCode}: ${response.body}',
                'original_data': batch[i],
              });
            }
          }
        } catch (e) {
          print('Exception processing batch ${batchIndex + 1}: $e');
          // Add error entries for this batch
          for (int i = 0; i < batch.length; i++) {
            results.add({
              'row_index': batchIndex * batchSize + i,
              'error': 'Exception: $e',
              'original_data': batch[i],
            });
          }
        }

        // Small delay between batches to prevent overwhelming the AI
        if (batchIndex < batches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      print('Error in processExcelData: $e');
      throw Exception('Failed to process Excel data: $e');
    }

    return results;
  }

  String _buildExcelPrompt(List<Map<String, dynamic>> batch, List<String> headers, String customPrompt) {
    final buffer = StringBuffer();
    
    buffer.writeln('EXCEL DATA PROCESSING TASK:');
    buffer.writeln('Headers: ${headers.join(', ')}');
    buffer.writeln();
    buffer.writeln('CUSTOM INSTRUCTIONS:');
    buffer.writeln(customPrompt);
    buffer.writeln();
    buffer.writeln('DATA TO PROCESS (${batch.length} rows):');
    
    for (int i = 0; i < batch.length; i++) {
      buffer.writeln('Row ${i + 1}: ${batch[i]}');
    }
    
    buffer.writeln();
    buffer.writeln('Please process this data according to the custom instructions and return a JSON array where each element corresponds to a processed row.');
    buffer.writeln('Format: [{"processed_field1": "value1", "processed_field2": "value2"}, ...]');
    
    return buffer.toString();
  }

  List<Map<String, dynamic>> _processExcelResponse(
    http.Response response,
    List<Map<String, dynamic>> batch,
    int batchIndex,
  ) {
    final results = <Map<String, dynamic>>[];
    
    try {
      final responseData = json.decode(response.body);
      final generatedText = responseData['response'] as String?;
      
      if (generatedText == null) {
        // Return error entries for the entire batch
        for (int i = 0; i < batch.length; i++) {
          results.add({
            'row_index': batchIndex * batch.length + i,
            'error': 'No response from AI model',
            'original_data': batch[i],
          });
        }
        return results;
      }

      try {
        // Try to extract JSON array from response
        final jsonStart = generatedText.indexOf('[');
        final jsonEnd = generatedText.lastIndexOf(']');
        
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = generatedText.substring(jsonStart, jsonEnd + 1);
          final extractedArray = json.decode(jsonString) as List;
          
          for (int i = 0; i < batch.length; i++) {
            if (i < extractedArray.length) {
              results.add({
                'row_index': batchIndex * batch.length + i,
                'processed_data': extractedArray[i],
                'original_data': batch[i],
                'raw_response': generatedText,
              });
            } else {
              results.add({
                'row_index': batchIndex * batch.length + i,
                'error': 'No processed data for this row',
                'original_data': batch[i],
              });
            }
          }
        } else {
          // Fallback: return the text response for each row
          for (int i = 0; i < batch.length; i++) {
            results.add({
              'row_index': batchIndex * batch.length + i,
              'processed_data': {'content': generatedText},
              'original_data': batch[i],
              'raw_response': generatedText,
              'parse_warning': 'Could not parse as JSON array',
            });
          }
        }
      } catch (e) {
        // JSON parsing failed, return error for each row
        for (int i = 0; i < batch.length; i++) {
          results.add({
            'row_index': batchIndex * batch.length + i,
            'processed_data': {'content': generatedText},
            'original_data': batch[i],
            'raw_response': generatedText,
            'parse_error': 'JSON parsing failed: $e',
          });
        }
      }
    } catch (e) {
      // Response processing failed
      for (int i = 0; i < batch.length; i++) {
        results.add({
          'row_index': batchIndex * batch.length + i,
          'error': 'Failed to process response: $e',
          'original_data': batch[i],
        });
      }
    }
    
    return results;
  }

  Map<String, dynamic> _processResponse(
    http.Response response,
    OneNotePage page,
    ExcelTemplate? template,
    String customPrompt,
  ) {
    try {
      final responseData = json.decode(response.body);
      final generatedText = responseData['response'] as String?;
      
      if (generatedText == null) {
        return {
          'page_title': page.title,
          'error': 'No response from AI model',
        };
      }

      try {
        // Try to parse as JSON first
        final jsonStart = generatedText.indexOf('{');
        final jsonEnd = generatedText.lastIndexOf('}');
        
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = generatedText.substring(jsonStart, jsonEnd + 1);
          final extractedData = json.decode(jsonString) as Map<String, dynamic>;
          
          // Return the extracted data directly as separate columns
          final result = <String, dynamic>{
            'page_title': page.title,
            'raw_response': generatedText,
          };
          
          // Use exact field names - no fuzzy matching
          final requiredFields = [
            'Client or company name',
            'Deal value or pricing',
            'Sales stage or status',
            'Contact information',
            'Next steps or actions',
            'Closing date'
          ];
          
          for (final expectedField in requiredFields) {
            result[expectedField] = extractedData[expectedField]?.toString() ?? '';
          }
          
          return result;
        } else {
          // No JSON found, try to parse the text format the AI is actually using
          return _parseTextResponse(generatedText, page, template, customPrompt);
        }
      } catch (e) {
        // JSON parsing failed, try text parsing
        return _parseTextResponse(generatedText, page, template, customPrompt);
      }
    } catch (e) {
      return {
        'page_title': page.title,
        'error': 'Failed to process response: $e',
      };
    }
  }

  void cancelAllRequests() {
    // Clear pending requests (HTTP requests can't be easily cancelled in Dart)
    _pendingRequests.clear();
  }

  /// Stop bundled Ollama process
  Future<void> stopBundledOllama() async {
    if (_ollamaProcess != null) {
      print('Stopping bundled Ollama...');
      _ollamaProcess!.kill();
      _ollamaProcess = null;
    }
  }

  void dispose() {
    cancelAllRequests();
    stopBundledOllama();
    _httpClient.close();
  }

  /// Parse AI text response when JSON parsing fails
  Map<String, dynamic> _parseTextResponse(String text, OneNotePage page, ExcelTemplate? template, String customPrompt) {
    final result = <String, dynamic>{
      'page_title': page.title,
      'raw_response': text,
    };
    
    // Extract field:value pairs from text like '"Client": "Value"' or 'Client: Value'
    final fieldPattern = RegExp(r'(?:"?([^":]+)"?\s*:\s*"?([^"\n]+)"?)', caseSensitive: false);
    final matches = fieldPattern.allMatches(text);
    
    final extractedData = <String, String>{};
    
    for (final match in matches) {
      final fieldName = match.group(1)?.trim() ?? '';
      final fieldValue = match.group(2)?.trim() ?? '';
      
      if (fieldName.isNotEmpty && fieldValue.isNotEmpty && fieldValue != 'value') {
        extractedData[fieldName] = fieldValue;
      }
    }
    
    // Map extracted data to expected fields using exact matching only
    final requiredFields = [
      'Client or company name',
      'Deal value or pricing',
      'Sales stage or status',
      'Contact information',
      'Next steps or actions',
      'Closing date'
    ];
    
    for (final expectedField in requiredFields) {
      result[expectedField] = extractedData[expectedField] ?? '';
    }
    
    return result;
  }

  /// Extract field names from custom prompt (looks for bullet points with field names)
  List<String> _extractFieldNamesFromCustomPrompt(String customPrompt) {
    final fieldNames = <String>[];
    final lines = customPrompt.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      // Look for bullet points or dashes that start field descriptions
      if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
        final fieldPart = trimmed.substring(2).trim();
        // Extract the field name (everything before 'or', ':', or common descriptive words)
        final fieldName = _cleanFieldName(fieldPart);
        if (fieldName.isNotEmpty && !fieldNames.contains(fieldName)) {
          fieldNames.add(fieldName);
        }
      }
    }
    
    return fieldNames;
  }

  /// Clean and standardize field names from custom prompt
  String _cleanFieldName(String rawField) {
    // Remove descriptive parts after "or" and common words
    final cleanPatterns = [
      ' or ',
      ':',
      ' - ',
      ' (',
      ' details',
      ' information',
      ' data',
    ];
    
    String cleaned = rawField.toLowerCase();
    for (final pattern in cleanPatterns) {
      final index = cleaned.indexOf(pattern);
      if (index != -1) {
        cleaned = cleaned.substring(0, index);
        break;
      }
    }
    
    // Capitalize each word
    return cleaned.split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .trim();
  }

  /// Remove duplicate fields with similar meanings
  Map<String, dynamic> _deduplicateFields(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    final processedKeys = <String>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final normalizedKey = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      
      // Skip if we've already processed a similar key
      bool isDuplicate = false;
      for (final processed in processedKeys) {
        final processedNormalized = processed.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        if (normalizedKey == processedNormalized || 
            (normalizedKey.length > 3 && processedNormalized.length > 3 && 
             (normalizedKey.contains(processedNormalized) || processedNormalized.contains(normalizedKey)))) {
          isDuplicate = true;
          break;
        }
      }
      
      if (!isDuplicate) {
        result[key] = entry.value;
        processedKeys.add(key);
      }
    }
    
    return result;
  }
}
