import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing RAW extraction with custom prompt...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
  try {
    // Load business data (now completely raw)
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages with RAW content');
    
    // Show sample of raw content
    if (pages.isNotEmpty) {
      print('\n=== Sample RAW Content ===');
      final sample = pages.first.content;
      print(sample.substring(0, sample.length > 300 ? 300 : sample.length));
      print('...\n');
    }
    
    // Test with multiple pages
    final testPages = pages.take(5).toList();
    
    // Your exact custom prompt
    final customPrompt = '''Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items''';
    
    print('Processing ${testPages.length} pages with AI...');
    
    // Process WITHOUT template (null) - pure custom prompt
    final processedData = await ollamaService.processPages(
      testPages,
      null,  // No template - use custom prompt
      customPrompt,
    );
    
    print('Processed ${processedData.length} pages');
    
    // Show results
    print('\n=== AI Results from Raw Data ===');
    if (processedData.isNotEmpty) {
      final sample = processedData.first;
      sample.forEach((key, value) {
        if (key != 'page_title' && key != 'source_file') {
          print('$key: $value');
        }
      });
    }
    
    // Check for any remnants of forced structure
    final allFields = <String>{};
    for (final pageData in processedData) {
      allFields.addAll(pageData.keys);
    }
    
    final hasArtificialStructure = allFields.any((f) => 
      f.contains('Primary Contact') || 
      f.contains('Secondary Contact') || 
      f.contains('Business Name') ||
      f.contains('Underwriter') ||
      f.contains('Broker'));
    
    print('\n=== Structure Analysis ===');
    print('All fields: ${allFields.where((f) => f != 'page_title' && f != 'source_file').join(', ')}');
    
    if (hasArtificialStructure) {
      print('❌ Still contains artificial structure');
    } else {
      print('✅ Pure AI-generated structure based on your prompt');
    }
    
    // Create Excel file
    await excelService.writeExcelFile('test_raw_extraction.xlsx', processedData, null);
    print('\n=== Excel File Created ===');
    print('File: test_raw_extraction.xlsx');
    print('This should have clean columns matching your prompt exactly!');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
