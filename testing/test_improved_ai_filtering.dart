import 'dart:io';
import '../lib/services/onenote_service.dart';
import '../lib/services/ollama_service.dart';
import '../lib/services/excel_service.dart';

void main() async {
  print('Testing improved AI filtering for template content...');
  
  try {
    // Initialize services
    final oneNoteService = OneNoteService();
    final ollamaService = OllamaService();
    final excelService = ExcelService();
    
    print('Loading OneNote pages...');
    final pages = await oneNoteService.readOneNoteFile('output_samples/June 2025.one');
    print('Loaded ${pages.length} pages');
    
    if (pages.isNotEmpty) {
      print('\nTesting AI processing with improved filtering...');
      
      // Test with a small subset first
      final testPages = pages.take(3).toList();
      
      final prompt = 'Extract: Company Name, Broker Name, Effective Date, Premium Amount';
      
      print('Processing ${testPages.length} test pages...');
      final results = await ollamaService.processPages(testPages, null, prompt);
      
      print('\n=== RESULTS ===');
      for (int i = 0; i < results.length; i++) {
        print('\nPage ${i + 1}: ${testPages[i].title}');
        print('Fields extracted:');
        
        results[i].forEach((key, value) {
          if (key != 'page_title' && key != 'error') {
            print('  $key: $value');
            
            // Check for problematic content
            final valueStr = value.toString();
            if (valueStr.length > 100) {
              print('    ⚠️  WARNING: Value is too long (${valueStr.length} chars)');
            }
            if (valueStr.toLowerCase().contains('pricing') && valueStr.toLowerCase().contains('position')) {
              print('    ❌ ERROR: Contains template text!');
            }
            if (valueStr.split(' ').length > 20) {
              print('    ⚠️  WARNING: Value contains too many words (${valueStr.split(' ').length})');
            }
          }
        });
      }
      
      // Create test output file
      print('\nCreating test Excel file...');
      await excelService.writeExcelFile(
        'testing/test_improved_filtering.xlsx',
        results, 
        null
      );
      print('Test file created: testing/test_improved_filtering.xlsx');
    }
    
    oneNoteService.dispose();
    ollamaService.dispose();
    
    print('\n✅ Test completed successfully!');
    
  } catch (e) {
    print('❌ Error during test: $e');
  }
}
