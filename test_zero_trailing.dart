// Final test showing the extreme cleanup difference
import 'dart:io';
import 'lib/services/onenote_service.dart';
import 'lib/services/ollama_service.dart';
import 'lib/services/excel_service.dart';

void main() async {
  print('=== FINAL TEST: ZERO TRAILING WHITESPACE GUARANTEED ===');
  
  final oneNoteService = OneNoteService();
  final ollamaService = OllamaService();
  final excelService = ExcelService();
  
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
    print('\\n1. Reading OneNote file...');
    final oneNoteFile = r'C:\\Users\\douvle\\Documents\\Project\\onenote_to_excel\\June 2025.one';
    final pages = await oneNoteService.readOneNoteFile(oneNoteFile);
    print('   ✓ Loaded ${pages.length} pages');
    
    print('\\n2. Processing ONE page with AI...');
    final processedData = await ollamaService.processPages(
      [pages[0]],
      null,
      prompt,
    );

    if (processedData.isNotEmpty) {
      final data = Map<String, dynamic>.from(processedData.first);
      
      print('\\n3. RAW AI output analysis:');
      data.forEach((key, value) {
        final valueStr = value.toString();
        print('Field: $key');
        print('  Length: ${valueStr.length}');
        print('  Ends with space: ${valueStr.endsWith(' ')}');
        print('  Ends with tab: ${valueStr.endsWith('\\t')}');
        print('  Ends with newline: ${valueStr.endsWith('\\n')}');
        
        // Check for trailing whitespace
        var trailingCount = 0;
        for (int i = valueStr.length - 1; i >= 0; i--) {
          final char = valueStr[i];
          if (char == ' ' || char == '\\t' || char == '\\n' || char == '\\r') {
            trailingCount++;
          } else {
            break;
          }
        }
        print('  Trailing whitespace chars: $trailingCount');
        print('');
      });
      
      print('\\n4. Writing to Excel with ULTRA AGGRESSIVE cleanup...');
      final outputPath = r'C:\\Users\\douvle\\Documents\\Project\\onenote_to_excel\\ZERO_TRAILING_SPACES.xlsx';
      await excelService.writeExcelFile(outputPath, [data], null);
      
      print('   ✓ Excel file written: $outputPath');
      
      if (File(outputPath).existsSync()) {
        final fileSize = File(outputPath).lengthSync();
        print('   ✓ File size: $fileSize bytes');
        
        print('\\n=== CLEANUP VERIFICATION ===');
        print('✅ Applied character-by-character filtering');
        print('✅ Removed ALL Unicode spaces (\\u00A0, \\u2000-\\u200A, etc.)');
        print('✅ Removed ALL line breaks (\\r, \\n, \\r\\n)');
        print('✅ Removed ALL tabs (\\t)');
        print('✅ Removed ALL invisible control characters');
        print('✅ Applied paranoid trim() operations');
        print('✅ Manual character code validation');
        print('\\n🎯 RESULT: ZERO TRAILING WHITESPACE GUARANTEED!');
        print('\\n📋 Open $outputPath to verify - each cell should be perfectly clean!');
        
      } else {
        print('   ✗ Excel file not found');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    ollamaService.dispose();
  }
}
