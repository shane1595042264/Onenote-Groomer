// Test the value cleanup functionality
import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing value cleanup in Excel export...');
  
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
      print('\nProcessing first page...');
      
      final processedData = await ollamaService.processPages(
        [pages[0]],
        null,
        prompt,
      );

      final data = <String, dynamic>{};
      if (processedData.isNotEmpty) {
        data.addAll(Map<String, dynamic>.from(processedData.first));
      }
      
      print('\nRAW AI output (before cleanup):');
      data.forEach((key, value) {
        final valueStr = value.toString();
        print('$key: "${valueStr}" (length: ${valueStr.length})');
        if (valueStr.length > 50) {
          print('  Preview: "${valueStr.substring(0, 50)}..."');
        }
      });
      
      // Write to Excel with cleanup
      final outputPath = r'C:\Users\douvle\Documents\Project\onenote_to_excel\test_cleaned_output.xlsx';
      print('\nWriting Excel file with cleanup: $outputPath');
      
      await excelService.writeExcelFile(
        outputPath,
        [data],
        null,
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
