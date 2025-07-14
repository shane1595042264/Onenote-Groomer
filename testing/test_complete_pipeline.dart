import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing complete OneNote to Excel pipeline...');
  
  final oneNoteService = OneNoteService();
  final excelService = ExcelService();
  
  try {
    // Step 1: Extract data from OneNote
    print('\n=== Step 1: Extracting OneNote Data ===');
    final pages = await oneNoteService.readOneNoteFile('June 2025.one');
    print('Extracted ${pages.length} pages');
    
    if (pages.isEmpty) {
      print('❌ No pages extracted');
      return;
    }
    
    // Step 2: Display sample of extracted data
    print('\n=== Step 2: Sample Business Data ===');
    for (int i = 0; i < pages.length && i < 3; i++) {
      final page = pages[i];
      print('\n--- Business Record ${i + 1} ---');
      print('Title: ${page.title}');
      print('Section: ${page.parentSection}');
      
      // Extract key business info from content
      final lines = page.content.split('\n');
      for (final line in lines.take(10)) {
        if (line.trim().isNotEmpty && 
            (line.contains('Broker:') || 
             line.contains('Company:') || 
             line.contains('Effective Date:') ||
             line.contains('Underwriter:'))) {
          print(line.trim());
        }
      }
    }
    
    // Step 3: Test Excel export
    print('\n=== Step 3: Testing Excel Export ===');
    
    // Convert pages to data format for Excel
    final excelData = pages.map((page) => {
      'Title': page.title,
      'Section': page.parentSection,
      'Content': page.content.length > 1000 ? '${page.content.substring(0, 1000)}...' : page.content,
      'Created': page.createdTime.toString(),
      'Modified': page.lastModifiedTime.toString(),
    }).toList();
    
    await excelService.writeExcelFile(
      'test_real_business_data.xlsx',
      excelData,
      ['Title', 'Section', 'Content', 'Created', 'Modified'],
    );
    print('✅ Excel file created: test_real_business_data.xlsx');
    
    // Step 4: Verify Excel file exists
    final excelFile = File('test_real_business_data.xlsx');
    if (await excelFile.exists()) {
      final fileSize = await excelFile.length();
      print('✅ Excel file confirmed - Size: $fileSize bytes');
    } else {
      print('❌ Excel file was not created');
    }
    
    print('\n=== Pipeline Test Complete ===');
    print('✅ Successfully processed real business data from OneNote to Excel!');
    
  } catch (e) {
    print('❌ Error in pipeline: $e');
  } finally {
    oneNoteService.dispose();
  }
}
