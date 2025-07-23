import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';
import 'lib/models/excel_template.dart';

void main() async {
  print('Testing full pipeline...');
  
  // Test OneNote extraction
  print('\n1. Testing OneNote extraction...');
  final oneNoteService = OneNoteService();
  final oneNoteFile = File('June 2025.one');
  
  if (!oneNoteFile.existsSync()) {
    print('OneNote file not found: ${oneNoteFile.path}');
    return;
  }
  
  try {
    final pages = await oneNoteService.readOneNoteFile(oneNoteFile.path);
    print('Extracted ${pages.length} pages from OneNote file');
    
    if (pages.isNotEmpty) {
      print('First page: ${pages.first.title}');
      print('Content preview: ${pages.first.content.substring(0, 200)}...');
    }
    
    // Test Ollama service
    print('\n2. Testing Ollama service...');
    final ollamaService = OllamaService();
    
    // Create a simple template
    final template = ExcelTemplate(
      columns: ['Business Name', 'Address', 'Contact', 'Notes'],
      sampleData: {}
    );
    
    const customPrompt = '''
Extract business information from the following OneNote content. 
Please provide the information in this format:
Business Name: [name]
Address: [address] 
Contact: [contact info]
Notes: [any other relevant info]
''';
    
    // Test with just first page
    final testPages = pages.take(1).toList();
    final results = await ollamaService.processPages(testPages, template, customPrompt);
    
    print('AI processing results:');
    for (final result in results) {
      print('Page: ${result['page_title']}');
      if (result.containsKey('error')) {
        print('Error: ${result['error']}');
      } else {
        result.forEach((key, value) {
          print('  $key: $value');
        });
      }
    }
    
    // Test Excel export
    print('\n3. Testing Excel export...');
    final excelService = ExcelService();
    final outputFile = File('test_output.xlsx');
    
    final actualOutputPath = await excelService.writeExcelFile(outputFile.path, results, template.columns);
    
    final actualOutputFile = File(actualOutputPath);
    if (actualOutputFile.existsSync()) {
      print('Excel file created successfully: $actualOutputPath');
      print('File size: ${actualOutputFile.lengthSync()} bytes');
    } else {
      print('Failed to create Excel file');
    }
    
  } catch (e, stackTrace) {
    print('Error in pipeline test: $e');
    print('Stack trace: $stackTrace');
  }
}
