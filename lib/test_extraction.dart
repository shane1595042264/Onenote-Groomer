import 'services/onenote_service.dart';

void main() async {
  print('Testing OneNote service...');
  
  final service = OneNoteService();
  
  // Test with the existing OneNote file
  try {
    final pages = await service.readOneNoteFile('June 2025.one');
    print('Extracted ${pages.length} pages:');
    
    for (final page in pages) {
      print('\n--- Page: ${page.title} ---');
      print('Content preview: ${page.content.length > 200 ? '${page.content.substring(0, 200)}...' : page.content}');
    }
  } catch (e) {
    print('Error: $e');
  }
  
  service.dispose();
}
