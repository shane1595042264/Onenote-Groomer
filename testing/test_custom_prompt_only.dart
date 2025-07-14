import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing CUSTOM PROMPT processing (no template)...');
  
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
    
    // Step 2: Test CUSTOM PROMPT (no template)
    print('\n=== Step 2: Testing Custom Prompt Processing ===');
    const customPrompt = '''Extract business data from OneNote pages. Focus on:
- Company/Client name
- Date and time information
- Key decisions or actions
- Financial information
- Contact details
- Status or outcomes
- Any follow-up items''';
    
    print('Custom Prompt:');
    print(customPrompt);
    
    final firstPage = pages.first;
    print('\nProcessing page: ${firstPage.title}');
    print('Content preview: ${firstPage.content.substring(0, firstPage.content.length > 300 ? 300 : firstPage.content.length)}...');
    
    // IMPORTANT: Pass null for template to use custom prompt mode
    final processedData = await ollamaService.processPages(
      [firstPage],
      null,  // ← NO TEMPLATE - use custom prompt
      customPrompt,
    );
    
    if (processedData.isNotEmpty) {
      print('\n=== AI Processing Result (Custom Prompt Mode) ===');
      final result = processedData.first;
      
      print('Fields extracted by AI (should match your prompt requirements):');
      result.forEach((key, value) {
        if (key != 'page_title' && key != 'source_file') {
          print('  $key: $value');
        }
      });
      
      // Check if fields match the custom prompt
      final expectedFields = [
        'company', 'client', 'date', 'time', 'decision', 'action', 
        'financial', 'contact', 'status', 'outcome', 'follow'
      ];
      
      final extractedFields = result.keys.where((k) => k != 'page_title' && k != 'source_file').toList();
      
      print('\n=== Field Analysis ===');
      print('Expected field types from prompt: ${expectedFields.join(", ")}');
      print('Actual fields extracted: ${extractedFields.join(", ")}');
      
      // Check alignment
      bool hasCompanyField = extractedFields.any((f) => f.toLowerCase().contains('company') || f.toLowerCase().contains('client'));
      bool hasDateField = extractedFields.any((f) => f.toLowerCase().contains('date') || f.toLowerCase().contains('time'));
      bool hasContactField = extractedFields.any((f) => f.toLowerCase().contains('contact'));
      bool hasFinancialField = extractedFields.any((f) => f.toLowerCase().contains('financial'));
      
      print('\n=== Prompt Alignment Check ===');
      print('Company/Client field: ${hasCompanyField ? "✅" : "❌"}');
      print('Date/Time field: ${hasDateField ? "✅" : "❌"}');
      print('Contact field: ${hasContactField ? "✅" : "❌"}');
      print('Financial field: ${hasFinancialField ? "✅" : "❌"}');
      
      if (hasCompanyField && hasDateField) {
        print('\n✅ Fields are aligned with custom prompt!');
      } else {
        print('\n❌ Fields do NOT match custom prompt requirements');
      }
      
    } else {
      print('❌ No data processed by AI');
    }
    
    // Step 3: Test with multiple pages and create Excel
    print('\n=== Step 3: Testing Multiple Pages ===');
    final testPages = pages.take(3).toList();
    final multipleResults = await ollamaService.processPages(
      testPages,
      null,  // No template
      customPrompt,
    );
    
    // Create Excel file
    await excelService.writeExcelFile('test_custom_prompt_only.xlsx', multipleResults, null);
    print('Excel file created: test_custom_prompt_only.xlsx');
    print('Check this file - columns should match your custom prompt, not template fields!');
    
  } catch (e) {
    print('❌ Error in custom prompt test: $e');
  } finally {
    oneNoteService.dispose();
    ollamaService.dispose();
  }
}
