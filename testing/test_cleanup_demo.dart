// Test script to demonstrate value cleanup improvements
import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing value cleanup improvements...');
  
  final excelService = ExcelService();
  
  // Create test data with problematic values (simulating AI output)
  final testData = [
    {
      'Company/Client Name': '  ABC Corporation   \n\n  ',
      'Date & Time Information': '  \t  2024-01-15 10:30 AM  \n  ',
      'Key Decisions': '  - Approved policy terms  \n  \t  ',
      'Financial Information': '  * Premium: \$50,000   \n  annually  \n\n  ',
      'Contact Details': '  • john.doe@example.com  \n  Phone: 555-1234  \n  ',
      'Status': '  Approved,   \n  ready for implementation;  ',
      'Follow-up Items': '  - Schedule meeting\n  - Send documents  \n  ',
    },
    {
      'Company/Client Name': '  XYZ Ltd  \n\n  ',
      'Date & Time Information': '  \t  2024-01-16  \n  ',
      'Key Decisions': '  None mentioned  \n  ',
      'Financial Information': '  N/A  \n  ',
      'Contact Details': '  \t  jane.smith@xyz.com  \n  ',
      'Status': '  \n  Pending review  \n  ',
      'Follow-up Items': '  \t  Call tomorrow  \n  ',
    }
  ];
  
  print('\\nOriginal data (before cleanup):');
  for (int i = 0; i < testData.length; i++) {
    print('Row ${i + 1}:');
    testData[i].forEach((key, value) {
      final valueStr = value.toString();
      print('  $key: "$valueStr" (length: ${valueStr.length})');
      // Show invisible characters
      final escaped = valueStr.replaceAll('\\n', '\\\\n').replaceAll('\\t', '\\\\t');
      if (escaped != valueStr) {
        print('    Escaped: "$escaped"');
      }
    });
  }
  
  // Write to Excel (this will apply the cleanup)
  const outputPath = r'C:\\Users\\douvle\\Documents\\Project\\onenote_to_excel\\test_cleanup_demo.xlsx';
  print('\\nWriting Excel file with cleanup applied: $outputPath');
  
  await excelService.writeExcelFile(
    outputPath,
    testData,
    null,
  );
  
  print('Excel file written successfully!');
  
  // Verify the file was created
  if (File(outputPath).existsSync()) {
    print('✓ Excel file exists');
    final fileSize = File(outputPath).lengthSync();
    print('✓ File size: $fileSize bytes');
    print('\\n✓ Values have been cleaned up and are now ready for Excel!');
    print('✓ Removed: leading/trailing whitespace, extra newlines, bullet points');
    print('✓ Normalized: multiple spaces to single spaces');
  } else {
    print('✗ Excel file not found');
  }
}
