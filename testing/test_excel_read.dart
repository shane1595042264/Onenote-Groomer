import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  final file = File('test_output.xlsx');
  if (!file.existsSync()) {
    print('Excel file not found');
    return;
  }
  
  try {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    print('Excel sheets: ${excel.tables.keys.toList()}');
    
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) {
      print('No sheet found');
      return;
    }
    
    print('Sheet rows: ${sheet.rows.length}');
    
    for (int i = 0; i < sheet.rows.length && i < 10; i++) {
      final row = sheet.rows[i];
      print('Row $i: ${row.map((cell) => cell?.value ?? '').toList()}');
    }
    
  } catch (e) {
    print('Error reading Excel file: $e');
  }
}
