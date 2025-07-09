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

  /// Clean and normalize a value before writing to Excel
  String _cleanExcelValue(dynamic value) {
    if (value == null) return '';

    String cleaned = value.toString()
        .replaceAll(RegExp(r'\r\n|\r|\n'), ' ')  // Replace all line breaks
        .replaceAll(RegExp(r'\t'), ' ')  // Replace tabs
        .replaceAll(RegExp(r'\s+'), ' ')  // Multiple spaces to single space
        .trim();

    // ULTRA AGGRESSIVE cleanup - remove ALL possible whitespace artifacts
    cleaned = cleaned
        .replaceAll(RegExp(r'^[\s\-\*\•\>\<\|\[\]\{\}]+'), '')  // Remove leading symbols/whitespace
        .replaceAll(RegExp(r'[\s\-\*\•\>\<\|\[\]\{\}]+$'), '')  // Remove trailing symbols/whitespace
        .replaceAll(RegExp(r'\s*[,;:]\s*$'), '')  // Remove trailing punctuation
        .replaceAll(RegExp(r'\s{2,}'), ' ')  // Multiple spaces to single space
        .trim();

    // PARANOID cleanup - manually remove invisible characters
    cleaned = cleaned
        .replaceAll(RegExp(r'[\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]'), ' ')  // Unicode spaces
        .replaceAll(RegExp(r'[\u2028\u2029]'), ' ')  // Unicode line separators
        .replaceAll(RegExp(r'[\u0009\u000A\u000B\u000C\u000D\u0020]'), ' ')  // Control characters
        .trim();

    // Final nuclear option - character by character cleanup
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];
      final code = char.codeUnitAt(0);
      
      // Only allow printable ASCII and common extended characters
      if (code >= 32 && code <= 126 || code >= 128 && code <= 255) {
        buffer.write(char);
      } else if (code == 9 || code == 10 || code == 13) {
        // Convert tabs/newlines to spaces
        buffer.write(' ');
      }
    }

    cleaned = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Clean all data before writing to Excel
  List<Map<String, dynamic>> _cleanAllData(List<Map<String, dynamic>> data) {
    return data.map((row) {
      final cleanedRow = <String, dynamic>{};
      row.forEach((key, value) {
        cleanedRow[key] = _cleanExcelValue(value);
      });
      return cleanedRow;
    }).toList();
  }

  Future<void> writeExcelFile(
    String outputPath,
    List<Map<String, dynamic>> data,
    List<String>? templateColumns,
  ) async {
    if (data.isEmpty) {
      throw Exception('No data to write to Excel');
    }

    // Clean all data before processing
    final cleanedData = _cleanAllData(data);

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
        final additionalColumns = _extractAllColumns(cleanedData)
            .where(
                (col) => !templateColumns.contains(col) && !col.startsWith('_'))
            .toList();
        allColumns.addAll(additionalColumns);
      } else {
        allColumns.addAll(_extractAllColumns(cleanedData));
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
      for (int rowIndex = 0; rowIndex < cleanedData.length; rowIndex++) {
        final rowData = cleanedData[rowIndex];

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
        for (final row in cleanedData) {
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
      for (final file in _openFiles.toList()) {
        try {
          await file.close();
          _openFiles.remove(file);
        } catch (e) {
          print('Error closing file handle: $e');
        }
      }

      // Small delay to ensure file system releases the handle
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      print('Error ensuring file is closed: $e');
    }
  }

  Future<void> _writeFileWithRetry(File outputFile, List<int> fileBytes) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Delete existing file if it exists and wait a bit
        if (await outputFile.exists()) {
          await outputFile.delete();
          await Future.delayed(Duration(milliseconds: 200));
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
                'Please close the Excel file if it\'s open and ensure you have write permissions to the output directory.');
          }
        }

        // Wait before retry
        await Future.delayed(retryDelay);
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
        'underwriter',
        'broker',
        'agent',
        'company',
        'client',
        'insured',
        'date',
        'effective_date',
        'contact',
        'producer',
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
