import 'dart:io';
import 'lib/services/onenote_service.dart';

void main() async {
  print('=== OneNote Service Test ===');
  
  final oneNoteService = OneNoteService();
  
  try {
    // Get the OneNote file path
    const oneNoteFile = 'June 2025.one';
    
    if (!await File(oneNoteFile).exists()) {
      print('ERROR: OneNote file not found: $oneNoteFile');
      print('Please ensure the file exists in the project directory.');
      exit(1);
    }
    
    print('Testing OneNote file: $oneNoteFile');
    print('File size: ${await File(oneNoteFile).length()} bytes');
    
    // Extract pages from OneNote
    print('\n--- Extracting pages from OneNote file ---');
    final pages = await oneNoteService.readOneNoteFile(oneNoteFile);
    
    print('Extracted ${pages.length} pages');
    
    if (pages.isEmpty) {
      print('WARNING: No pages extracted from the OneNote file');
      return;
    }
    
    // Analyze the extracted content
    print('\n--- Page Analysis ---');
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      print('\nPage ${i + 1}:');
      print('  Title: ${page.title}');
      print('  Section: ${page.parentSection}');
      print('  Content length: ${page.content.length} characters');
      
      // Check for business indicators
      final content = page.content.toLowerCase();
      final hasUnderwriter = content.contains('underwriter') && !content.contains('n/a');
      final hasBroker = content.contains('broker');
      final hasCompany = content.contains('company') || content.contains('client');
      final hasDate = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(page.content);
      
      print('  Has Underwriter: $hasUnderwriter');
      print('  Has Broker: $hasBroker');
      print('  Has Company: $hasCompany');
      print('  Has Date: $hasDate');
      
      // Show first 200 characters of content
      final preview = page.content.length > 200 
          ? '${page.content.substring(0, 200)}...' 
          : page.content;
      print('  Content preview: ${preview.replaceAll('\n', ' ')}');
    }
    
    // Count valid business entries
    final validEntries = pages.where((page) {
      final content = page.content.toLowerCase();
      final hasUnderwriter = content.contains('underwriter') && !content.contains('n/a');
      final hasBroker = content.contains('broker');
      final hasCompany = content.contains('company') || content.contains('client');
      final hasDate = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(page.content);
      
      return hasUnderwriter || ((hasBroker || hasCompany) && hasDate);
    }).toList();
    
    print('\n--- Summary ---');
    print('Total pages extracted: ${pages.length}');
    print('Valid business entries: ${validEntries.length}');
    
    if (validEntries.isEmpty) {
      print('\nWARNING: No valid business entries found!');
      print('This suggests the OneNote parsing is not working correctly.');
      print('The file might be in a format that requires OneNote to be installed.');
    } else {
      print('\nSUCCESS: Found ${validEntries.length} valid business entries');
    }
    
  } catch (e) {
    print('ERROR: $e');
    exit(1);
  } finally {
    oneNoteService.dispose();
  }
}
