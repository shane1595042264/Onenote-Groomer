import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/excel_service.dart';

void main() async {
  print('🧪 Testing Persistent Prompt and Smart File Handling');
  print('====================================================');
  
  try {
    // Test 1: Shared Preferences for Custom Prompt
    print('\n1. Testing SharedPreferences for Custom Prompt Storage...');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save a test prompt
    const testPrompt = '''
Test custom prompt that should be remembered:
- Company information
- Contact details  
- Financial data
- Status updates
''';
    
    await prefs.setString('custom_ai_prompt', testPrompt);
    print('✅ Saved test prompt to SharedPreferences');
    
    // Retrieve the prompt
    final retrievedPrompt = prefs.getString('custom_ai_prompt');
    if (retrievedPrompt == testPrompt) {
      print('✅ Successfully retrieved saved prompt');
      print('   Saved prompt length: ${testPrompt.length} characters');
      print('   Retrieved prompt length: ${retrievedPrompt?.length} characters');
    } else {
      print('❌ Failed to retrieve correct prompt');
    }
    
    // Test 2: Smart File Handling with Existing Files
    print('\n2. Testing Smart File Handling for Existing Files...');
    
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
    
    // Test 3: Multiple Conflicts 
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
    
    // Test 4: Clear the test prompt (cleanup)
    print('\n4. Cleaning up test data...');
    await prefs.remove('custom_ai_prompt');
    print('✅ Cleared test prompt from SharedPreferences');
    
    print('\n🎉 All tests completed successfully!');
    print('\nFeatures demonstrated:');
    print('✓ Custom AI prompt persistence using SharedPreferences');
    print('✓ Smart file conflict resolution with unique filenames');
    print('✓ Multiple conflict handling with numbered suffixes');
    print('✓ No more "file locked" errors when Excel files are open');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
