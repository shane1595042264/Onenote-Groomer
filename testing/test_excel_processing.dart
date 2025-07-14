// Test Excel file processing functionality
import 'dart:io';
import 'lib/services/excel_service.dart';
import 'lib/services/ollama_service.dart';

void main() async {
  print('Testing Excel file processing...');
  
  final excelService = ExcelService();
  final ollamaService = OllamaService();
  
  // Test with a sample Excel file (you'll need to create one)
  const testExcelPath = r'C:\Users\douvle\Documents\Project\onenote_to_excel\MM Tracking Project Template New Business 1.xlsx';
  
  if (!File(testExcelPath).existsSync()) {
    print('Test Excel file not found: $testExcelPath');
    print('Please create a sample Excel file with some data to test.');
    return;
  }
  
  try {
    // Step 1: Read and analyze Excel file
    print('\n1. Reading Excel file...');
    final excelData = await excelService.readExcelFile(testExcelPath);
    
    print('✓ Excel file loaded successfully');
    print('  Sheet: ${excelData['sheetName']}');
    print('  Rows: ${excelData['totalRows']}');
    print('  Columns: ${excelData['columns']}');
    print('  Headers: ${(excelData['headers'] as List<String>).join(', ')}');
    
    // Step 2: Analyze column patterns
    print('\n2. Analyzing column patterns...');
    final columnAnalysis = excelService.analyzeExcelColumns(excelData);
    
    for (final entry in columnAnalysis.entries) {
      print('  ${entry.key} → ${entry.value.join(', ')}');
    }
    
    // Step 3: Show sample data
    print('\n3. Sample data preview:');
    final sampleData = excelData['sampleData'] as List<Map<String, dynamic>>;
    for (int i = 0; i < sampleData.length && i < 3; i++) {
      print('  Row ${i + 1}:');
      for (final entry in sampleData[i].entries) {
        print('    ${entry.key}: ${entry.value}');
      }
      print('');
    }
    
    // Step 4: Test AI processing with custom prompt
    print('4. Testing AI processing...');
    const customPrompt = '''
Transform this Excel data and extract:
- Contact information (names, emails, phones)
- Company or organization names
- Any dates mentioned
- Financial amounts or costs
- Status or progress indicators
- Action items or tasks

Organize the data clearly and remove duplicates.
''';
    
    print('Processing ${excelData['totalRows']} rows with AI...');
    
    final processedData = await ollamaService.processExcelData(
      excelData,
      customPrompt,
      maxRows: 50, // Limit for testing
    );
    
    print('✓ AI processing complete');
    print('  Input rows: ${excelData['totalRows']}');
    print('  Output rows: ${processedData.length}');
    
    // Step 5: Show processed results
    print('\n5. Processed data sample:');
    for (int i = 0; i < processedData.length && i < 3; i++) {
      print('  Processed row ${i + 1}:');
      for (final entry in processedData[i].entries) {
        print('    ${entry.key}: ${entry.value}');
      }
      print('');
    }
    
    // Step 6: Export to Excel
    print('6. Exporting processed data...');
    final outputPath = testExcelPath.replaceAll('.xlsx', '_ai_processed.xlsx');
    
    await excelService.writeExcelFile(
      outputPath,
      processedData,
      null, // No template columns
    );
    
    print('✓ Export complete: $outputPath');
    
    // Verify output file
    if (File(outputPath).existsSync()) {
      final fileSize = File(outputPath).lengthSync();
      print('✓ Output file verified (${(fileSize / 1024).round()} KB)');
    }
    
    print('\n🎉 Excel processing test completed successfully!');
    print('\nNext steps:');
    print('1. Check the output file: $outputPath');
    print('2. Compare with original: $testExcelPath');
    print('3. Test with different prompts');
    print('4. Try larger Excel files');
    
  } catch (e) {
    print('❌ Error during testing: $e');
  } finally {
    ollamaService.dispose();
  }
}
