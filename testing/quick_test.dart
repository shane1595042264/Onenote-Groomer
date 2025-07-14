import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';

void main() async {
  print('Quick test of current AI service...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  
  try {
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    if (pages.isNotEmpty) {
      final processedData = await ollamaService.processPages(
        [pages.first],
        null,
        'Extract: Company name, Date, Contact details',
      );
      
      print('\nResult:');
      if (processedData.isNotEmpty) {
        processedData.first.forEach((key, value) {
          print('$key: $value');
        });
      }
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    oneNoteService.dispose();
    // ollamaService dispose method not available
  }
}
