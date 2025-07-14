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

      final result = <String, dynamic>{
        'page_title': page.title,
        'source_file': page.parentSection,
      };

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
    
    // Parse the AI response for field:value pairs
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0 && colonIndex < line.length - 1) {
        final fieldName = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        
        // Skip obviously bad responses
        if (value.isEmpty || value.toLowerCase().contains('not specified') || 
            value.toLowerCase().contains('none mentioned') ||
            fieldName.toLowerCase().contains('note') && value.length > 100) {
          continue;
        }
        
        // Clean the field name but keep it close to what AI provided
        final cleanFieldName = _capitalizeFieldName(fieldName);
        if (cleanFieldName.isNotEmpty && cleanFieldName.length < 50) {
          result[cleanFieldName] = _cleanValue(value);
        }
      }
    }
    
    // If no structured data found, create summary
    if (result.isEmpty) {
      result['Extracted Information'] = _cleanText(text);
    }
    
    return result;
  }

  bool _fieldMatches(String responseField, String templateColumn) {
    final respLower = responseField.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final tempLower = templateColumn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    return respLower == tempLower || 
           respLower.contains(tempLower) || 
           tempLower.contains(respLower);
  }

  String _cleanValue(String value) {
    String cleaned = value
        .replaceAll(RegExp(r'^(none mentioned|not available|not found|not specified)', caseSensitive: false), 'N/A')
        .replaceAll(RegExp(r'^(in the text|in the provided text|in the document)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.$'), '')
        .trim();
    
    return cleaned.isEmpty ? 'N/A' : cleaned;
  }

  String _capitalizeFieldName(String fieldName) {
    return fieldName.split(' ').map((word) {
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
      // Custom prompt-based extraction
      basePrompt.writeln('Extract information from the text according to these requirements:');
      basePrompt.writeln(customPrompt.isNotEmpty ? customPrompt : 'Extract key business information');
      basePrompt.writeln('');
      basePrompt.writeln('Respond in this format:');
      basePrompt.writeln('Field Name: value');
      basePrompt.writeln('Another Field: value');
      basePrompt.writeln('');
      basePrompt.writeln('Only include information that exists in the text. Do not add explanations.');
      basePrompt.writeln('');
      basePrompt.writeln('Text to analyze:');
      basePrompt.writeln(page.content);
    }
    
    return basePrompt.toString();
  }
}
