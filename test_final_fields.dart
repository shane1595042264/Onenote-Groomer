import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing final field consolidation...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
  try {
    // Load business data
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    // Test with multiple pages to see field consolidation
    final testPages = pages.take(5).toList();
    
    // Use the EXACT prompt from the user
    final customPrompt = '''Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items''';
    
    print('Processing ${testPages.length} pages...');
    
    // Process WITHOUT template (null)
    final processedData = await ollamaService.processPages(
      testPages,
      null,  // No template - use custom prompt
      customPrompt,
    );
    
    print('Processed ${processedData.length} pages');
    
    // Analyze the field structure
    final allFields = <String>{};
    for (final pageData in processedData) {
      for (final field in pageData.keys) {
        if (field != 'page_title' && field != 'source_file') {
          allFields.add(field);
        }
      }
    }
    
    print('\n=== Final Field Structure ===');
    print('Total unique fields: ${allFields.length}');
    print('Fields:');
    for (final field in allFields) {
      print('  - $field');
    }
    
    // Check for expected fields from the prompt
    final expectedFields = [
      'Company/Client name',
      'Date and time information', 
      'Key decisions or actions',
      'Financial information',
      'Contact details',
      'Status or outcomes',
      'Any follow-up items'
    ];
    
    print('\n=== Field Matching Analysis ===');
    for (final expected in expectedFields) {
      final words = expected.toLowerCase().split(' ');
      final found = allFields.any((field) => 
        field.toLowerCase().contains(words[0]) ||
        (words.length > 1 && field.toLowerCase().contains(words[1]))
      );
      print('${found ? "✅" : "❌"} $expected');
    }
    
    // Create Excel file
    await excelService.writeExcelFile('test_final_fields.xlsx', processedData, null);
    print('\n=== Excel File Created ===');
    print('File: test_final_fields.xlsx');
    print('Check the Excel file to verify:');
    print('1. No duplicate columns');
    print('2. Column names match your prompt exactly');
    print('3. No "| something" suffixes in column names');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
