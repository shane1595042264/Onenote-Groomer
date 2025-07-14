// Test Excel file reading directly
import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing Excel file reading...');
  
  final excelService = ExcelService();
  
  // Test with the existing Excel file in the workspace
  const testFile = r'C:\Users\douvle\Documents\Project\onenote_to_excel\June 2025_extracted.xlsx';
  
  print('Testing file: $testFile');
  
  if (!File(testFile).existsSync()) {
    print('Test file does not exist!');
    return;
  }
  
  try {
    print('Reading Excel file...');
    final data = await excelService.readExcelFile(testFile);
    print('Success! Excel data:');
    print('Sheet: ${data['sheetName']}');
    print('Rows: ${data['totalRows']}');
    print('Columns: ${data['columns']}');
    print('Headers: ${data['headers']}');
    
    if (data['sampleData'] != null) {
      print('Sample data:');
      for (int i = 0; i < (data['sampleData'] as List).length && i < 3; i++) {
        print('  Row ${i + 1}: ${data['sampleData'][i]}');
      }
    }
    
  } catch (e) {
    print('Error reading Excel file: $e');
    print('Stack trace: ${StackTrace.current}');
  } finally {
    excelService.dispose();
  }
}
