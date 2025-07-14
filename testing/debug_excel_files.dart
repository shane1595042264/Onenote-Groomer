// Simple test to verify Excel file handling
import 'dart:io';

void main() {
  print('=== EXCEL FILE DEBUG TEST ===');
  
  // Check what Excel files are available
  final directory = Directory(r'C:\Users\douvle\Documents\Project\onenote_to_excel');
  print('Looking for Excel files in: ${directory.path}');
  
  final excelFiles = directory
      .listSync()
      .where((file) => file.path.endsWith('.xlsx') || file.path.endsWith('.xls'))
      .toList();
  
  print('Found ${excelFiles.length} Excel files:');
  for (final file in excelFiles) {
    print('  - ${file.path.split('\\').last}');
    
    // Check file extension
    final extension = file.path.substring(file.path.lastIndexOf('.'));
    print('    Extension: $extension');
    print('    Matches .xlsx: ${extension.toLowerCase() == '.xlsx'}');
    print('    Matches .xls: ${extension.toLowerCase() == '.xls'}');
    print('    In accepted list: ${['.xlsx', '.xls'].contains(extension.toLowerCase())}');
  }
  
  print('\n=== EXTENSION VALIDATION TEST ===');
  final testExtensions = ['.xlsx', '.xls', '.XLSX', '.XLS'];
  final acceptedExtensions = ['.xlsx', '.xls'];
  
  for (final ext in testExtensions) {
    final isAccepted = acceptedExtensions.contains(ext.toLowerCase());
    print('Extension $ext -> Accepted: $isAccepted');
  }
}
