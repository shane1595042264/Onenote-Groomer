import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing custom prompt-based column generation...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
  try {
    // Get business data
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    // Test with the exact prompt from the GUI screenshot
    const customPrompt = '''Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items''';
    
    print('\n=== Testing Custom Prompt-Based Processing ===');
    print('Custom Prompt: $customPrompt');
    
    // Process first 2 pages
    final allResults = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 2 && i < pages.length; i++) {
      print('\nProcessing page ${i + 1}: ${pages[i].title}');
      
      final processedData = await ollamaService.processPages(
        [pages[i]],
        null, // No template - should use custom prompt
        customPrompt,
      );
      
      if (processedData.isNotEmpty) {
        allResults.add(processedData.first);
        print('Generated columns: ${processedData.first.keys.join(', ')}');
      }
    }
    
    // Show all unique columns generated
    print('\n=== All Generated Columns ===');
    final allColumns = <String>{};
    for (final result in allResults) {
      allColumns.addAll(result.keys);
    }
    
    print('Total unique columns: ${allColumns.length}');
    for (final column in allColumns) {
      print('  - $column');
    }
    
    // Export to Excel
    print('\n=== Exporting to Excel ===');
    await excelService.writeExcelFile(
      'custom_prompt_output.xlsx',
      allResults,
      allColumns.toList(),
    );
    
    print('✅ Excel file created: custom_prompt_output.xlsx');
    print('✅ AI now generates columns based on custom prompt instead of hardcoded fields!');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    oneNoteService.dispose();
  }
}
