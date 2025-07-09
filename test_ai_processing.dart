import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing current AI processing pipeline...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
  try {
    // Step 1: Get extracted business data
    print('\n=== Step 1: Loading Business Data ===');
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Loaded ${pages.length} pages');
    
    if (pages.isEmpty) {
      print('No pages to process');
      return;
    }
    
    // Step 2: Load Excel template to see what columns we're targeting
    print('\n=== Step 2: Loading Excel Template ===');
    final template = await excelService.readTemplateFile('MM Tracking Project Template New Business 1.xlsx');
    
    if (template != null) {
      print('Template columns (${template.columns.length}):');
      for (int i = 0; i < template.columns.length; i++) {
        print('  ${i + 1}. ${template.columns[i]}');
      }
    } else {
      print('No template found - using default processing');
    }
    
    // Step 3: Test AI processing on first page
    print('\n=== Step 3: Testing AI Processing ===');
    final firstPage = pages.first;
    print('Processing page: ${firstPage.title}');
    print('Content preview: ${firstPage.content.substring(0, firstPage.content.length > 300 ? 300 : firstPage.content.length)}...');
    
    // Test CUSTOM PROMPT mode (template = null)
    print('\n--- Testing Custom Prompt Mode (no template) ---');
    final customPrompt = '''Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items''';
    
    final processedData = await ollamaService.processPages(
      [firstPage],
      null,  // Use null instead of template to test custom prompt
      customPrompt,
    );
    
    if (processedData.isNotEmpty) {
      print('\n=== AI Processing Result ===');
      final result = processedData.first;
      result.forEach((key, value) {
        print('$key: $value');
      });
      
      // Count N/A values
      final naCount = result.values.where((v) => v.toString() == 'N/A').length;
      final totalFields = result.length;
      print('\n=== Quality Metrics ===');
      print('Total fields: $totalFields');
      print('N/A fields: $naCount');
      print('Filled fields: ${totalFields - naCount}');
      print('Fill rate: ${(((totalFields - naCount) / totalFields) * 100).toStringAsFixed(1)}%');
    } else {
      print('❌ No data processed by AI');
    }
    
  } catch (e) {
    print('❌ Error in AI processing test: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
