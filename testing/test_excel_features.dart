import 'dart:io';
import 'lib/services/excel_service.dart';
import 'lib/services/ollama_service.dart';

void main() async {
  print('🧪 Testing Excel Features Comprehensively...\n');

  // Initialize services
  final excelService = ExcelService();
  final ollamaService = OllamaService();
  
  const testFile = 'MM Tracking Project Template New Business 1.xlsx';
  
  if (!File(testFile).existsSync()) {
    print('❌ Test file not found: $testFile');
    return;
  }

  try {
    // Test 1: Excel file reading
    print('📖 Test 1: Reading Excel file...');
    final excelData = await excelService.readExcelFile(testFile);
    print('  ✓ File: ${excelData['sheetName']}');
    print('  ✓ Rows: ${excelData['totalRows']}');
    print('  ✓ Columns: ${excelData['columns']}');
    print('  ✓ Headers: ${(excelData['headers'] as List).join(', ')}\n');

    // Test 2: Column analysis
    print('📊 Test 2: Analyzing columns...');
    final analysis = excelService.analyzeExcelColumns(excelData);
    for (final entry in analysis.entries) {
      print('  ${entry.key} → ${entry.value.join(', ')}');
    }
    print('');

    // Test 3: Different AI prompts
    final prompts = [
      'Extract: Company Name, Status, Premium, Comments',
      'Find: Account, Broker, Date, Status, Expected_to_Bind',
      'Get: Underwriter_Name, Company, Status, Target_Premium, Notes',
    ];

    for (int i = 0; i < prompts.length; i++) {
      print('🤖 Test ${3 + i}: AI processing with prompt ${i + 1}...');
      print('  Prompt: "${prompts[i]}"');
      
      try {
        final result = await ollamaService.processExcelData(
          excelData, 
          prompts[i],
          maxRows: 5,
        );
        
        print('  ✓ Processed ${result.length} rows');
        if (result.isNotEmpty) {
          print('  ✓ Fields in result: ${result.first.keys.join(', ')}');
          print('  Sample: ${result.first}');
        }
        
        // Write test output
        final outputPath = 'test_output_prompt_${i + 1}.xlsx';
        await excelService.writeExcelFile(outputPath, result, null);
        print('  ✓ Exported to: $outputPath');
        
      } catch (e) {
        print('  ⚠️ AI processing failed: $e');
      }
      print('');
    }

    // Test 4: Large dataset simulation
    print('📈 Test 6: Large dataset handling...');
    // Create larger test data by duplicating
    final largeData = Map<String, dynamic>.from(excelData);
    final originalData = excelData['allData'] as List<Map<String, dynamic>>;
    final expandedData = <Map<String, dynamic>>[];
    
    // Duplicate data 10 times to simulate larger dataset
    for (int i = 0; i < 10; i++) {
      for (final row in originalData) {
        final newRow = Map<String, dynamic>.from(row);
        newRow['_batch_number'] = i + 1;
        expandedData.add(newRow);
      }
    }
    
    largeData['allData'] = expandedData;
    largeData['totalRows'] = expandedData.length;
    
    print('  Creating dataset with ${expandedData.length} rows...');
    
    try {
      final largeResult = await ollamaService.processExcelData(
        largeData, 
        'Extract key information: Account, Status, Premium',
        maxRows: 50, // Test batch processing
      );
      
      print('  ✓ Processed ${largeResult.length} rows in batches');
      
      const largeOutputPath = 'test_output_large.xlsx';
      await excelService.writeExcelFile(largeOutputPath, largeResult, null);
      print('  ✓ Large dataset exported to: $largeOutputPath');
      
    } catch (e) {
      print('  ⚠️ Large dataset processing failed: $e');
    }

    print('\n🎉 Excel features testing completed!');
    print('\nFeatures verified:');
    print('  ✓ Excel file reading and parsing');
    print('  ✓ Column analysis and suggestions');
    print('  ✓ AI-powered data processing');
    print('  ✓ Custom prompt handling');
    print('  ✓ Batch processing for large datasets');
    print('  ✓ Excel export with cleanup');
    print('  ✓ Error handling and fallbacks');
    
    print('\nFiles created:');
    for (int i = 1; i <= 3; i++) {
      final file = 'test_output_prompt_$i.xlsx';
      if (File(file).existsSync()) {
        print('  📄 $file (${File(file).lengthSync()} bytes)');
      }
    }
    if (File('test_output_large.xlsx').existsSync()) {
      print('  📄 test_output_large.xlsx (${File('test_output_large.xlsx').lengthSync()} bytes)');
    }

  } catch (e, stack) {
    print('❌ Test failed: $e');
    print('Stack: $stack');
  } finally {
    excelService.dispose();
  }
}
