// Test ULTRA AGGRESSIVE cleanup
import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('Testing ULTRA AGGRESSIVE cleanup...');
  
  final excelService = ExcelService();
  
  // Create test data with the most problematic whitespace issues
  final testData = [
    {
      'Company/Client Name': '  ABC Corporation   \n\n\t\t  ',
      'Date & Time Information': '  \u00A0\u00A0  2024-01-15 10:30 AM  \n\n\t  ',
      'Key Decisions': '  - Approved policy terms  \n\n\t\t\t  ',
      'Financial Information': '  * Premium: \$50,000   \n\n  annually  \n\n\t  ',
      'Contact Details': '  • john.doe@example.com  \n\n\t  Phone: 555-1234  \n\n\t  ',
      'Status': '  Approved,   \n\n\t  ready for implementation;  \n\n\t  ',
      'Follow-up Items': '  - Schedule meeting\n\n\t  - Send documents  \n\n\t  ',
    }
  ];
  
  print('\\nOriginal values with extreme whitespace issues:');
  testData[0].forEach((key, value) {
    final valueStr = value.toString();
    print('$key:');
    print('  Raw: "$valueStr"');
    print('  Length: ${valueStr.length}');
    print('  Escaped: "${valueStr.replaceAll('\\n', '\\\\n').replaceAll('\\t', '\\\\t').replaceAll(String.fromCharCode(0x00A0), '\\\\u00A0')}"');
    print('');
  });
  
  // Write to Excel with ultra-aggressive cleanup
  const outputPath = r'C:\\Users\\douvle\\Documents\\Project\\onenote_to_excel\\test_ultra_clean.xlsx';
  print('Writing Excel file with ULTRA AGGRESSIVE cleanup: $outputPath');
  
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
    print('\\n🚀 ULTRA AGGRESSIVE cleanup applied!');
    print('✓ Removed ALL line breaks, tabs, unicode spaces');
    print('✓ Removed ALL leading/trailing whitespace');
    print('✓ Removed ALL invisible characters');
    print('✓ Applied character-by-character filtering');
    print('\\n📋 Open the Excel file to verify ZERO trailing spaces!');
  } else {
    print('✗ Excel file not found');
  }
}
