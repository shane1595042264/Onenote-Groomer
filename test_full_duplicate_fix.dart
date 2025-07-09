import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing full pipeline with duplicate fix...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
  try {
    // Load business data
    print('Loading business data...');
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    if (pages.isEmpty) {
      print('No pages found');
      return;
    }
    
    // Take first 3 pages to test
    final testPages = pages.take(3).toList();
    print('Testing with ${testPages.length} pages');
    
    // Process with custom prompt (no template)
    final customPrompt = 'Extract key business information for insurance underwriting';
    print('Processing pages with AI...');
    
    final processedData = await ollamaService.processPages(
      testPages,
      null,  // No template - use custom prompt
      customPrompt,
    );
    
    print('Processed ${processedData.length} pages');
    
    // Analyze for duplicates across all pages
    final allFieldNames = <String>{};
    final duplicateGroups = <String, List<String>>{};
    
    for (final pageData in processedData) {
      for (final fieldName in pageData.keys) {
        if (fieldName != 'page_title' && fieldName != 'source_file') {
          allFieldNames.add(fieldName);
        }
      }
    }
    
    // Group similar field names
    final fieldList = allFieldNames.toList();
    for (int i = 0; i < fieldList.length; i++) {
      for (int j = i + 1; j < fieldList.length; j++) {
        final field1 = fieldList[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final field2 = fieldList[j].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        
        if ((field1.contains('company') && field2.contains('company')) ||
            (field1.contains('contact') && field2.contains('contact')) ||
            (field1.contains('date') && field2.contains('date'))) {
          final key = field1.length < field2.length ? fieldList[i] : fieldList[j];
          duplicateGroups.putIfAbsent(key, () => []).addAll([fieldList[i], fieldList[j]]);
        }
      }
    }
    
    print('\n=== Field Analysis ===');
    print('Total unique field names: ${allFieldNames.length}');
    print('Field names found:');
    for (final field in allFieldNames) {
      print('  - $field');
    }
    
    if (duplicateGroups.isEmpty) {
      print('\n✅ No duplicate field groups detected!');
    } else {
      print('\n❌ Potential duplicate groups:');
      duplicateGroups.forEach((key, fields) {
        print('  Group "$key": ${fields.join(", ")}');
      });
    }
    
    // Create Excel output
    await excelService.writeExcelFile('test_no_duplicates.xlsx', processedData, null);
    print('\n=== Excel Created ===');
    print('File: test_no_duplicates.xlsx');
    print('Check the file to see if there are any duplicate columns!');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
