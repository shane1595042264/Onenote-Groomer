import 'dart:io';
import 'lib/services/onenote_service.dart';

void main() async {
  print('Testing OneNote extraction in detail...');
  
  final oneNoteService = OneNoteService();
  final oneNoteFile = File('June 2025.one');
  
  if (!oneNoteFile.existsSync()) {
    print('OneNote file not found: ${oneNoteFile.path}');
    return;
  }
  
  try {
    final pages = await oneNoteService.readOneNoteFile(oneNoteFile.path);
    print('Extracted ${pages.length} pages from OneNote file\n');
    
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      print('=== PAGE ${i + 1}: ${page.title} ===');
      print('Section: ${page.parentSection}');
      print('Content length: ${page.content.length}');
      print('Content preview (first 500 chars):');
      print(page.content.substring(0, page.content.length > 500 ? 500 : page.content.length));
      print('\n');
    }
    
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
