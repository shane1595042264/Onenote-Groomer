import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('=== OneNote Extraction Test ===');
  
  // Check if test file exists
  final testFile = File('June 2025.one');
  if (!await testFile.exists()) {
    print('Test file not found: June 2025.one');
    exit(1);
  }
  
  print('Found test file: ${testFile.path}');
  
  // Test OneNote extraction
  final oneNoteService = OneNoteService();
  print('\n1. Testing OneNote extraction...');
  
  final pages = await oneNoteService.readOneNoteFile(testFile.path);
  print('Extracted ${pages.length} pages from OneNote file');
  
  if (pages.isNotEmpty) {
    print('\nFirst few pages:');
    for (int i = 0; i < pages.length && i < 5; i++) {
      final page = pages[i];
      print('Page ${i + 1}: "${page.title}" (${page.content.length} chars)');
      if (page.content.isNotEmpty) {
        final preview = page.content.substring(0, 
            page.content.length > 200 ? 200 : page.content.length);
        print('  Content preview: ${preview.replaceAll('\n', ' ')}...');
      }
    }
    
    if (pages.length > 5) {
      print('... and ${pages.length - 5} more pages');
    }
  }
  
  // Test template extraction
  print('\n2. Testing Excel template loading...');
  try {
    final templateFile = File('MM Tracking Project Template New Business 1.xlsx');
    if (await templateFile.exists()) {
      final excelService = ExcelService();
      final template = await excelService.readTemplateFile(templateFile.path);
      
      if (template != null) {
        print('Template loaded with ${template.columns.length} columns:');
        for (int i = 0; i < template.columns.length && i < 10; i++) {
          print('  - ${template.columns[i]}');
        }
        if (template.columns.length > 10) {
          print('  ... and ${template.columns.length - 10} more columns');
        }
        
        // Test AI processing with template on first few pages
        print('\n3. Testing AI processing with template...');
        final ollamaService = OllamaService();
        
        // Check if Ollama is running
        print('Checking Ollama connection...');
        final isConnected = await ollamaService.checkConnection();
        if (!isConnected) {
          print('Ollama is not running. Please start Ollama first.');
          return;
        }
        print('Ollama connected successfully');
        
        // Process first 3 pages with template
        final pagesToTest = pages.take(3).toList();
        print('Processing ${pagesToTest.length} pages with AI...');
        
        final results = await ollamaService.processPages(
          pagesToTest, 
          template, 
          'Extract business information'
        );
        
        print('\nAI Processing Results:');
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          print('\nResult ${i + 1}:');
          print('  Page: ${result['page_title']}');
          
          if (result.containsKey('error')) {
            print('  Error: ${result['error']}');
          } else {
            // Print template fields
            for (final column in template.columns) {
              if (result.containsKey(column)) {
                final value = result[column];
                print('  $column: ${value?.toString() ?? 'N/A'}');
              }
            }
          }
        }
      } else {
        print('Failed to load template');
      }
    } else {
      print('Template file not found: ${templateFile.path}');
    }
  } catch (e) {
    print('Error with template: $e');
  }
  
  // Test without template
  print('\n4. Testing AI processing without template...');
  try {
    final ollamaService = OllamaService();
    
    final pagesToTest = pages.take(2).toList();
    final results = await ollamaService.processPages(
      pagesToTest, 
      null, 
      'Extract key business information'
    );
    
    print('\nUnstructured Processing Results:');
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      print('\nResult ${i + 1}:');
      print('  Page: ${result['page_title']}');
      
      if (result.containsKey('error')) {
        print('  Error: ${result['error']}');
      } else if (result.containsKey('content')) {
        final content = result['content'];
        print('  Extracted content: ${content?.toString() ?? 'None'}');
      }
    }
    
  } catch (e) {
    print('Error in unstructured processing: $e');
  }
  
  print('\n=== Test Complete ===');
}
