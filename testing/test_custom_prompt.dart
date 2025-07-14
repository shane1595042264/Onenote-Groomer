import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';

void main() async {
  print('Testing dynamic column generation based on custom GUI prompt...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  
  try {
    // Get business data
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    // Test with the exact prompt from the GUI screenshot
    const customPrompt = '''Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items''';
    
    print('\n=== Testing with Custom GUI Prompt ===');
    print('Custom Prompt: $customPrompt');
    
    // Process first page with custom prompt (no template)
    final firstPage = pages.first;
    print('\nProcessing page: ${firstPage.title}');
    
    final processedData = await ollamaService.processPages(
      [firstPage],
      null, // No template - should use custom prompt to generate columns
      customPrompt,
    );
    
    if (processedData.isNotEmpty) {
      print('\n=== AI Generated Columns Based on Custom Prompt ===');
      final result = processedData.first;
      
      print('Generated ${result.length} columns:');
      result.forEach((key, value) {
        print('$key: $value');
      });
      
      // Check if columns match what user requested
      final userRequestedFields = [
        'company', 'client', 'date', 'time', 'decision', 'action', 
        'financial', 'contact', 'status', 'outcome', 'follow', 'up'
      ];
      
      var matchedFields = 0;
      for (final key in result.keys) {
        final keyLower = key.toLowerCase();
        if (userRequestedFields.any((field) => keyLower.contains(field))) {
          matchedFields++;
        }
      }
      
      print('\n=== Prompt Alignment Check ===');
      print('Fields matching user prompt: $matchedFields/${result.length}');
      print('Alignment score: ${((matchedFields / result.length) * 100).toStringAsFixed(1)}%');
      
      if (matchedFields > 0) {
        print('✅ AI is responding to custom prompt!');
      } else {
        print('❌ AI is not following custom prompt');
      }
    } else {
      print('❌ No data processed');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
