class ExcelTemplate {
  final List<String> columns;
  final Map<String, dynamic> sampleData;

  ExcelTemplate({
    required this.columns,
    required this.sampleData,
  });

  factory ExcelTemplate.fromExcel(List<List<dynamic>> rows) {
    if (rows.isEmpty) return ExcelTemplate(columns: [], sampleData: {});

    final columns = rows[0].map((e) => e.toString()).toList();
    final sampleData = <String, dynamic>{};

    if (rows.length > 1) {
      for (int i = 0; i < columns.length; i++) {
        if (i < rows[1].length) {
          sampleData[columns[i]] = rows[1][i];
        }
      }
    }

    return ExcelTemplate(columns: columns, sampleData: sampleData);
  }
}
