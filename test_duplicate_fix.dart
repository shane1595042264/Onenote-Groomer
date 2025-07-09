import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';

void main() async {
  print('Testing duplicate field fix...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  
  try {
    // Step 1: Get a single page
    print('Loading business data...');
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    
    if (pages.isEmpty) {
      print('No pages found');
      return;
    }
    
    final firstPage = pages.first;
    print('Processing: ${firstPage.title}');
    
    // Step 2: Test with custom prompt that might cause duplicates
    final customPrompt = 'Extract key business information for insurance underwriting';
    
    final processedData = await ollamaService.processPages(
      [firstPage],
      null,  // No template - use custom prompt
      customPrompt,
    );
    
    if (processedData.isNotEmpty) {
      print('\n=== AI Result (should have no duplicate fields) ===');
      final result = processedData.first;
      print('Total fields: ${result.length}');
      
      result.forEach((key, value) {
        print('$key: $value');
      });
      
      // Check for potential duplicates
      final fieldNames = result.keys.toList();
      final duplicates = <String>[];
      
      for (int i = 0; i < fieldNames.length; i++) {
        for (int j = i + 1; j < fieldNames.length; j++) {
          final field1 = fieldNames[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final field2 = fieldNames[j].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          
          if (field1.contains('company') && field2.contains('company')) {
            duplicates.add('${fieldNames[i]} / ${fieldNames[j]}');
          }
          if (field1.contains('contact') && field2.contains('contact')) {
            duplicates.add('${fieldNames[i]} / ${fieldNames[j]}');
          }
        }
      }
      
      if (duplicates.isEmpty) {
        print('\n✅ No duplicate fields detected!');
      } else {
        print('\n❌ Potential duplicates found:');
        for (final dup in duplicates) {
          print('  - $dup');
        }
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
