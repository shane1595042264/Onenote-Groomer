import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('Verifying the exported Excel file contains real business data...');
  
  final excelService = ExcelService();
  
  try {
    // Read the Excel file we just created
    final template = await excelService.readTemplateFile('test_real_business_data.xlsx');
    
    if (template != null) {
      print('\n=== Excel File Contents ===');
      print('Total rows: ${template.rows.length}');
      
      if (template.rows.isNotEmpty) {
        // Show headers
        print('\nHeaders:');
        print(template.rows[0].join(' | '));
        
        // Show first few data rows
        print('\nFirst 3 business records:');
        for (int i = 1; i < template.rows.length && i <= 3; i++) {
          final row = template.rows[i];
          print('\n--- Record $i ---');
          print('Title: ${row.isNotEmpty ? row[0] : 'N/A'}');
          print('Section: ${row.length > 1 ? row[1] : 'N/A'}');
          
          // Look for specific business companies in the content
          if (row.length > 2) {
            final content = row[2].toString();
            final hasQualfon = content.contains('Qualfon');
            final hasFarbman = content.contains('Farbman');
            final hasTotalSecurity = content.contains('Total Security');
            final hasAmericanContainers = content.contains('American Containers');
            
            print('Contains real business names: ${hasQualfon || hasFarbman || hasTotalSecurity || hasAmericanContainers}');
            
            if (content.length > 100) {
              print('Content preview: ${content.substring(0, 100)}...');
            } else {
              print('Content: $content');
            }
          }
        }
        
        // Check overall data quality
        var realBusinessCount = 0;
        for (int i = 1; i < template.rows.length; i++) {
          if (template.rows[i].length > 2) {
            final content = template.rows[i][2].toString().toLowerCase();
            if (content.contains('qualfon') || 
                content.contains('farbman') || 
                content.contains('total security') ||
                content.contains('american containers') ||
                content.contains('underwriter') ||
                content.contains('broker') ||
                content.contains('effective date')) {
              realBusinessCount++;
            }
          }
        }
        
        print('\n=== Data Quality Summary ===');
        print('Total records: ${template.rows.length - 1}');
        print('Records with real business data: $realBusinessCount');
        print('Real data percentage: ${((realBusinessCount / (template.rows.length - 1)) * 100).toStringAsFixed(1)}%');
        
        if (realBusinessCount > 0) {
          print('✅ SUCCESS: Excel file contains real business data!');
        } else {
          print('❌ WARNING: No real business data found in Excel file');
        }
      } else {
        print('❌ Excel file is empty');
      }
    } else {
      print('❌ Could not read Excel file');
    }
    
  } catch (e) {
    print('❌ Error reading Excel file: $e');
  }
}
