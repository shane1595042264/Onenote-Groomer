import 'dart:io';
import 'lib/services/onenote_service.dart';

void main() async {
  print('Testing JSON data loading...');
  
  final service = OneNoteService();
  
  try {
    // Test loading from the extracted JSON file
    final pages = await service.readOneNoteFile('June 2025.one');
    
    print('\n=== Results ===');
    print('Total pages extracted: ${pages.length}');
    
    if (pages.isNotEmpty) {
      print('\nFirst few pages:');
      for (int i = 0; i < pages.length && i < 3; i++) {
        final page = pages[i];
        print('\n--- Page ${i + 1} ---');
        print('Title: ${page.title}');
        print('Section: ${page.parentSection}');
        print('Content preview: ${page.content.substring(0, page.content.length > 200 ? 200 : page.content.length)}...');
      }
      
      // Check if we're getting real business data
      final hasRealData = pages.any((page) => 
        page.content.contains('Qualfon') || 
        page.content.contains('Farbman') || 
        page.content.contains('Total Security') ||
        page.content.contains('American Containers')
      );
      
      print('\n=== Data Quality Check ===');
      print('Contains real business data: $hasRealData');
      
      if (hasRealData) {
        print('✅ SUCCESS: Real business data found!');
      } else {
        print('❌ WARNING: No real business data found');
      }
    } else {
      print('❌ No pages were extracted');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    service.dispose();
  }
}
