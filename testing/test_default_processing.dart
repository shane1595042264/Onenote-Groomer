import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';

void main() async {
  print('Testing improved default AI processing (no template)...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  
  try {
    // Step 1: Get extracted business data
    print('\n=== Step 1: Loading Business Data ===');
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    if (pages.isEmpty) {
      print('No pages to process');
      return;
    }
    
    // Step 2: Test AI processing WITHOUT template (default mode)
    print('\n=== Step 2: Testing Default AI Processing (No Template) ===');
    final firstPage = pages.first;
    print('Processing page: ${firstPage.title}');
    
    final processedData = await ollamaService.processPages(
      [firstPage],
      null, // No template - should trigger default structured processing
      'Extract key business information for insurance underwriting',
    );
    
    if (processedData.isNotEmpty) {
      print('\n=== Default Processing Result ===');
      final result = processedData.first;
      
      print('Generated ${result.length} columns dynamically:');
      result.forEach((key, value) {
        print('$key: $value');
      });
      
      // Check if we got structured data instead of just dumping in 'content'
      final hasStructuredData = result.keys.any((key) => 
        key != 'content' && 
        key != 'page_title' && 
        key != 'source_file' &&
        key != 'error'
      );
      
      print('\n=== Quality Check ===');
      print('Has structured columns: $hasStructuredData');
      print('Total data fields: ${result.length}');
      
      if (hasStructuredData) {
        print('✅ SUCCESS: Generated structured columns dynamically!');
      } else {
        print('❌ Still dumping everything in single field');
      }
    } else {
      print('❌ No data processed by AI');
    }
    
  } catch (e) {
    print('❌ Error in default processing test: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
