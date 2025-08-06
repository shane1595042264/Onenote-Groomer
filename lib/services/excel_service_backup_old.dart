import 'dart:io';
import 'package:excel/excel.dart';
import '../models/excel_template.dart';

class ExcelService {
  // Keep track of open file handles
  final Set<RandomAccessFile> _openFiles = {};

  Future<ExcelTemplate?> readTemplateFile(String filePath) async {
    RandomAccessFile? file;

    try {
      file = await File(filePath).open();
      _openFiles.add(file);

      final length = await file.length();
      final bytes = await file.read(length);

      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) return null;

      final rows = <List<dynamic>>[];
      for (final row in sheet.rows) {
        rows.add(row.map((cell) => cell?.value ?? '').toList());
      }

      return ExcelTemplate.fromExcel(rows);
    } catch (e) {
      print('Error reading Excel template: $e');
      return null;
    } finally {
      if (file != null) {
        await _closeFile(file);
      }
    }
  }

  Future<void> writeExcelFile(
    String outputPath,
    List<Map<String, dynamic>> data,
    List<String>? templateColumns,
  ) async {
    if (data.isEmpty) {
      throw Exception('No data to write to Excel');
    }

    // Ensure any existing handles to this file are closed
    await _ensureFileIsClosed(outputPath);

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Determine columns - use template columns if provided
      final allColumns = <String>[];

      if (templateColumns != null && templateColumns.isNotEmpty) {
        allColumns.addAll(templateColumns);

        // Add any additional columns from data that aren't in template
        final additionalColumns = _extractAllColumns(data)
            .where(
                (col) => !templateColumns.contains(col) && !col.startsWith('_'))
            .toList();
        allColumns.addAll(additionalColumns);
      } else {
        allColumns.addAll(_extractAllColumns(data));
      }

      // Always add metadata columns at the end
      final metadataColumns = [
        '_page_number',
        '_page_title',
        '_section',
        '_created_date',
        '_raw_content'
      ];

      for (final metaCol in metadataColumns) {
        if (!allColumns.contains(metaCol)) {
          allColumns.add(metaCol);
        }
      }

      // Write headers with formatting
      for (int i = 0; i < allColumns.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(allColumns[i]);

        // Bold headers
        cell.cellStyle = CellStyle(
          bold: true,
        );
      }

      // Write data rows
      for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final rowData = data[rowIndex];

        for (int colIndex = 0; colIndex < allColumns.length; colIndex++) {
          final columnName = allColumns[colIndex];
          var value = rowData[columnName];

          // Handle null or empty values
          if (value == null || value.toString().isEmpty) {
            // Try to find value without case sensitivity
            final lowerColumnName = columnName.toLowerCase();
            final matchingKey = rowData.keys.firstWhere(
              (key) => key.toLowerCase() == lowerColumnName,
              orElse: () => '',
            );

            if (matchingKey.isNotEmpty) {
              value = rowData[matchingKey];
            }
          }

          // Convert value to string and truncate if too long
          String cellValue = value?.toString() ?? '';
          if (cellValue.length > 32767) {
            // Excel cell limit
            cellValue = '${cellValue.substring(0, 32760)}...';
          }

          sheet
              .cell(CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ))
              .value = TextCellValue(cellValue);
        }
      }

      // Auto-size columns (approximate)
      for (int i = 0; i < allColumns.length; i++) {
        final columnData = <String>[allColumns[i]];
        for (final row in data) {
          columnData.add(row[allColumns[i]]?.toString() ?? '');
        }

        final maxLength =
            columnData.map((s) => s.length).reduce((a, b) => a > b ? a : b);

        sheet.setColumnWidth(i, maxLength * 1.2);
      }

      // Save file with retry logic for access issues
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file bytes');
      }

      // Ensure directory exists
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);

      // Try to write file with retry logic
      await _writeFileWithRetry(outputFile, fileBytes);

      print('Excel file written successfully: $outputPath');
      print('Total rows: ${data.length}');
      print('Total columns: ${allColumns.length}');
    } catch (e) {
      print('Error writing Excel file: $e');
      throw Exception('Failed to write Excel file: $e');
    }
  }

  Future<void> _ensureFileIsClosed(String filePath) async {
    try {
      // Close any open handles to this specific file
      final fileName = File(filePath).path;
      for (final file in _openFiles.toList()) {
        try {
          await file.close();
          _openFiles.remove(file);
        } catch (e) {
          print('Error closing file handle: $e');
        }
      }
      
      // Small delay to ensure file system releases the handle
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error ensuring file is closed: $e');
    }
  }

  Future<void> _writeFileWithRetry(File outputFile, List<int> fileBytes) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Delete existing file if it exists
        if (await outputFile.exists()) {
          await outputFile.delete();
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // Write the file
        await outputFile.writeAsBytes(fileBytes, flush: true);
        return; // Success!
        
      } catch (e) {
        print('Write attempt $attempt failed: $e');
        
        if (attempt == maxRetries) {
          // Last attempt failed, try alternative approach
          try {
            final tempPath = '${outputFile.path}.tmp';
            final tempFile = File(tempPath);
            await tempFile.writeAsBytes(fileBytes, flush: true);
            
            // Try to rename temp file to final name
            await tempFile.rename(outputFile.path);
            return; // Success with temp file approach!
            
          } catch (tempError) {
            throw Exception('Failed to write Excel file after $maxRetries attempts. '
                'Error: $e. Temp file error: $tempError. '
                'Please ensure the file is not open in Excel and you have write permissions.');
          }
        }
        
        // Wait before retry
        await Future.delayed(retryDelay);
      }
    }
  }
  }

  List<String> _extractAllColumns(List<Map<String, dynamic>> data) {
    final columnsSet = <String>{};

    for (final row in data) {
      columnsSet.addAll(row.keys);
    }

    // Sort columns intelligently
    final columns = columnsSet.toList();
    columns.sort((a, b) {
      // Metadata columns go last
      if (a.startsWith('_') && !b.startsWith('_')) return 1;
      if (!a.startsWith('_') && b.startsWith('_')) return -1;

      // Common business columns go first
      final priority = [
        'company',
        'client',
        'insured',
        'date',
        'effective_date',
        'contact',
        'producer',
        'agent',
        'status',
        'type',
        'amount',
        'premium',
        'value',
        'percentage',
        'rate',
        'credit',
        'description',
        'notes'
      ];

      final aIndex = priority.indexWhere((p) => a.toLowerCase().contains(p));
      final bIndex = priority.indexWhere((p) => b.toLowerCase().contains(p));

      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      }
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;

      return a.compareTo(b);
    });

    return columns;
  }

  Future<void> _closeFile(RandomAccessFile file) async {
    try {
      await file.flush();
      await file.close();
      _openFiles.remove(file);
    } catch (e) {
      print('Error closing file: $e');
    }
  }

  void dispose() {
    // Close all open files
    for (final file in _openFiles.toList()) {
      try {
        file.closeSync();
      } catch (e) {
        print('Error closing file in dispose: $e');
      }
    }
    _openFiles.clear();
  }
}
