// Create a script to clean up existing Excel files (for testing purposes)
import 'dart:io';
import 'lib/services/excel_service.dart';

void main() async {
  print('Creating new cleaned Excel output...');
  
  final excelService = ExcelService();
  
  // Read the existing problematic Excel file and clean it up
  final existingFile = r'C:\Users\douvle\Documents\Project\onenote_to_excel\June 2025_extracted.xlsx';
  
  if (!File(existingFile).existsSync()) {
    print('File not found: $existingFile');
    return;
  }
  
  try {
    // Read the existing template
    final template = await excelService.readTemplateFile(existingFile);
    
    if (template != null) {
      print('Read existing file with ${template.columns.length} columns');
      print('Columns: ${template.columns.join(', ')}');
      
      // Create sample cleaned data
      final cleanedData = [
        {
          'Company/Client Name': 'ABC Corporation',
          'Date & Time Information': '2024-01-15 10:30 AM',
          'Key Decisions / Actions': 'Approved policy terms',
          'Financial Information': 'Premium: \$50,000 annually',
          'Contact Details': 'john.doe@example.com',
          'Status / Outcomes': 'Approved, ready for implementation',
          'Follow-up Items': 'Schedule meeting, Send documents',
        },
        {
          'Company/Client Name': 'XYZ Ltd',
          'Date & Time Information': '2024-01-16',
          'Key Decisions / Actions': 'None mentioned',
          'Financial Information': 'N/A',
          'Contact Details': 'jane.smith@xyz.com',
          'Status / Outcomes': 'Pending review',
          'Follow-up Items': 'Call tomorrow',
        }
      ];
      
      // Write cleaned data
      final outputPath = r'C:\Users\douvle\Documents\Project\onenote_to_excel\cleaned_sample_output.xlsx';
      await excelService.writeExcelFile(outputPath, cleanedData, null);
      
      print('\\nCleaned Excel file created: $outputPath');
      
      if (File(outputPath).existsSync()) {
        print('✓ File created successfully');
        final fileSize = File(outputPath).lengthSync();
        print('✓ File size: $fileSize bytes');
      }
      
    } else {
      print('Could not read template file');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
