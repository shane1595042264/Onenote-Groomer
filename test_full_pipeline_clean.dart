// Test the full pipeline with Excel export
import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing full pipeline with Excel export...');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
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
      print('\nProcessing first 3 pages...');
      
      final extractedData = <Map<String, dynamic>>[];
      for (int i = 0; i < 3 && i < pages.length; i++) {
        print('Processing page ${i + 1}: ${pages[i].title}');
        
        final processedData = await ollamaService.processPages(
          [pages[i]],
          null,
          prompt,
        );

        final data = <String, dynamic>{};
        if (processedData.isNotEmpty) {
          data.addAll(Map<String, dynamic>.from(processedData.first));
        }
        
        // No technical columns will be added since they're not in the prompt
        
        extractedData.add(data);
      }
      
      print('\nExtracting data summary:');
      for (int i = 0; i < extractedData.length; i++) {
        print('Page ${i + 1}: ${extractedData[i].keys.length} fields');
        print('  Fields: ${extractedData[i].keys.join(', ')}');
      }
      
      // Write to Excel
      final outputPath = r'C:\Users\douvle\Documents\Project\onenote_to_excel\test_clean_output.xlsx';
      print('\nWriting Excel file: $outputPath');
      
      await excelService.writeExcelFile(
        outputPath,
        extractedData,
        null, // no template columns
      );
      
      print('Excel file written successfully!');
      
      // Verify the file was created
      if (File(outputPath).existsSync()) {
        print('✓ Excel file exists');
        final fileSize = File(outputPath).lengthSync();
        print('✓ File size: $fileSize bytes');
      } else {
        print('✗ Excel file not found');
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
