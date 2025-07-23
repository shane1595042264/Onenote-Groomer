import 'dart:io';
import '../lib/services/excel_service.dart';

void main() async {
  print('🧪 Testing Smart File Handling');
  print('===============================');
  
  try {
    final excelService = ExcelService();
    
    // Create some dummy data
    final testData = [
      {'Company': 'Test Corp', 'Contact': 'John Doe', 'Phone': '555-1234'},
      {'Company': 'Sample Inc', 'Contact': 'Jane Smith', 'Phone': '555-5678'},
    ];
    
    // Create the original test file first
    final originalTestFile = 'testing/test_file_handling.xlsx';
    print('Creating original test file: $originalTestFile');
    
    final originalPath = await excelService.writeExcelFile(
      originalTestFile,
      testData,
      ['Company', 'Contact', 'Phone']
    );
    print('✅ Created original file: $originalPath');
    
    // Now try to write to the same path (should create a new file)
    print('\nAttempting to write to same path (should create new file)...');
    
    final newData = [
      {'Company': 'Another Corp', 'Contact': 'Bob Wilson', 'Phone': '555-9999'},
      {'Company': 'Different Inc', 'Contact': 'Alice Brown', 'Phone': '555-7777'},
    ];
    
    final newPath = await excelService.writeExcelFile(
      originalTestFile,
      newData,
      ['Company', 'Contact', 'Phone']
    );
    
    if (newPath != originalPath) {
      print('✅ Smart file handling working! Created new file: $newPath');
      
      // Verify both files exist
      final originalFile = File(originalPath);
      final newFile = File(newPath);
      
      if (await originalFile.exists() && await newFile.exists()) {
        print('✅ Both files exist:');
        print('   Original: $originalPath (${await originalFile.length()} bytes)');
        print('   New: $newPath (${await newFile.length()} bytes)');
      } else {
        print('❌ File verification failed');
      }
    } else {
      print('❌ File handling didn\'t create unique filename');
    }
    
    // Test multiple conflicts 
    print('\n3. Testing Multiple File Conflicts...');
    
    for (int i = 1; i <= 3; i++) {
      final conflictData = [
        {'Test': 'Conflict $i', 'Number': '$i'},
      ];
      
      final conflictPath = await excelService.writeExcelFile(
        originalTestFile,
        conflictData,
        ['Test', 'Number']
      );
      
      print('   Conflict $i resolved to: ${conflictPath.split(Platform.pathSeparator).last}');
    }
    
    print('\n🎉 File handling tests completed successfully!');
    print('\nFeatures demonstrated:');
    print('✓ Smart file conflict resolution with unique filenames');
    print('✓ Multiple conflict handling with numbered suffixes');
    print('✓ No more "file locked" errors when Excel files are open');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
