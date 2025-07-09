// Test the current pipeline with strict field filtering
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';

void main() async {
  print('Testing OneNote to Excel with strict field filtering...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  
  // Test the specific prompt from the app
  final prompt = '''
Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items

Structure the data appropriately for Excel export.
''';
  
  try {
    // Read the OneNote file
    final oneNoteFile = r'C:\Users\douvle\Documents\Project\onenote_to_excel\June 2025.one';
    print('Reading OneNote file: $oneNoteFile');
    
    final pages = await oneNoteService.readOneNoteFile(oneNoteFile);
    print('Found ${pages.length} pages');
    
    if (pages.isNotEmpty) {
      print('\nProcessing first page: ${pages[0].title}');
      print('Content length: ${pages[0].content.length} characters');
      
      // Process just the first page
      final result = await ollamaService.processPages([pages[0]], null, prompt);
      
      if (result.isNotEmpty) {
        print('\nProcessing result:');
        final data = result[0];
        print('Number of fields returned: ${data.keys.length}');
        
        print('\nActual fields returned:');
        data.forEach((key, value) {
          print('  "$key": "$value"');
        });
        
        // Check if we're getting only the expected fields
        final expectedFields = [
          'Company/Client Name',
          'Date & Time Information', 
          'Key Decisions / Actions',
          'Financial Information',
          'Contact Details',
          'Status / Outcomes',
          'Follow-up Items'
        ];
        
        print('\nExpected ${expectedFields.length} fields, got ${data.keys.length} fields');
        
        // Check for any extra fields
        final extraFields = data.keys.where((key) => 
          !expectedFields.any((expected) => 
            key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '') == 
            expected.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')
          )
        ).toList();
        
        if (extraFields.isNotEmpty) {
          print('\nExtra fields found (should be filtered out):');
          for (final field in extraFields) {
            print('- "$field"');
          }
        } else {
          print('\n✓ No extra fields found - filtering is working correctly!');
        }
      } else {
        print('No result from AI processing');
      }
    } else {
      print('No pages found in OneNote file');
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    ollamaService.dispose();
  }
}
