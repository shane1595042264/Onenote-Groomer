// Test XLSB file support
import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing XLSB file support...');
  
  final excelService = ExcelService();
  
  // Test with the XLSB file the user is trying to use
  final testFile = r'C:\Users\douvle\Documents\Arch\MM INnovation lab stuff\M90 Listing Midwest US (4Q25) 20250505 1.xlsb';
  
  print('Testing file: $testFile');
  
  if (!File(testFile).existsSync()) {
    print('XLSB test file does not exist at that path!');
    
    // Try to find any .xlsb files in the project directory
    final directory = Directory(r'C:\Users\douvle\Documents\Project\onenote_to_excel');
    final xlsbFiles = directory
        .listSync()
        .where((file) => file.path.endsWith('.xlsb'))
        .toList();
    
    if (xlsbFiles.isNotEmpty) {
      print('Found .xlsb files in project directory:');
      for (final file in xlsbFiles) {
        print('  - ${file.path}');
      }
      // Use the first one for testing
      final testPath = xlsbFiles.first.path;
      await testXlsbFile(excelService, testPath);
    } else {
      print('No .xlsb files found for testing');
    }
  } else {
    await testXlsbFile(excelService, testFile);
  }
  
  excelService.dispose();
}

Future<void> testXlsbFile(ExcelService excelService, String filePath) async {
  print('\nTesting XLSB file: ${filePath.split('\\').last}');
  
  try {
    print('Attempting to read XLSB file...');
    final data = await excelService.readExcelFile(filePath);
    print('✅ SUCCESS! XLSB file read successfully');
    print('Sheet: ${data['sheetName']}');
    print('Rows: ${data['totalRows']}');
    print('Columns: ${data['columns']}');
    print('Headers: ${data['headers']}');
    
  } catch (e) {
    print('❌ ERROR reading XLSB file: $e');
    print('The excel package might not support .xlsb format');
    print('Consider converting .xlsb to .xlsx format');
  }
}
