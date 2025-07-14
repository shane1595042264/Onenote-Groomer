import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing complete default pipeline (no template) with Excel export...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
  try {
    // Step 1: Get business data
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    // Step 2: Process first 3 pages with default AI (no template)
    print('\n=== Processing 3 pages with default AI ===');
    final allResults = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 3 && i < pages.length; i++) {
      print('Processing page ${i + 1}: ${pages[i].title}');
      
      final processedData = await ollamaService.processPages(
        [pages[i]],
        null, // No template
        'Extract key business information for insurance underwriting',
      );
      
      if (processedData.isNotEmpty) {
        allResults.add(processedData.first);
      }
    }
    
    // Step 3: Show all extracted columns
    print('\n=== All Dynamic Columns Generated ===');
    final allColumns = <String>{};
    for (final result in allResults) {
      allColumns.addAll(result.keys);
    }
    
    print('Total unique columns: ${allColumns.length}');
    for (final column in allColumns) {
      print('  - $column');
    }
    
    // Step 4: Export to Excel
    print('\n=== Exporting to Excel ===');
    await excelService.writeExcelFile(
      'default_structured_output.xlsx',
      allResults,
      allColumns.toList(),
    );
    
    print('✅ Excel file created: default_structured_output.xlsx');
    print('✅ Default processing now creates structured data instead of dumping everything in one column!');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
