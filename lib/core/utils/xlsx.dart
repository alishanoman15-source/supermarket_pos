import 'package:excel/excel.dart';

import 'csv.dart';

/// XLSX (Excel) support for SPEC §20/§64 — exports write a real `.xlsx`
/// workbook and the importer accepts `.xlsx` uploads by converting the first
/// sheet to CSV before handing them to the server-side `import-products`
/// worker (which parses CSV only).
///
/// Everything here is pure Dart (`excel` has no platform channels), so it
/// works on every target including web.

/// Builds an `.xlsx` workbook with a single [sheetName] holding [headers] and
/// [rows]. Numeric values are written as numbers so Excel can sum them;
/// everything else is written as text.
List<int> buildXlsx({
  required String sheetName,
  required Iterable<Object?> headers,
  required Iterable<Iterable<Object?>> rows,
}) {
  final excel = Excel.createExcel();
  // Single-sheet export: add the data sheet first (delete() only works when
  // at least two sheets exist), then drop the blank default sheet.
  final sheet = excel[sheetName];

  sheet.appendRow([for (final h in headers) _cell(h)]);
  for (final row in rows) {
    sheet.appendRow([for (final value in row) _cell(value)]);
  }
  excel.delete('Sheet1');

  final encoded = excel.encode();
  return encoded ?? const [];
}

CellValue? _cell(Object? value) {
  if (value == null) return null;
  // Real numeric cells so Excel can sum/sort them.
  if (value is int) return IntCellValue(value);
  if (value is double) return DoubleCellValue(value);
  if (value is num) {
    final d = value.toDouble();
    return d == d.roundToDouble() ? IntCellValue(d.toInt()) : DoubleCellValue(d);
  }
  if (value is DateTime) return TextCellValue(value.toIso8601String());
  return TextCellValue(value.toString());
}

/// Converts an uploaded `.xlsx` file to CSV text so it can flow through the
/// same validate → preview → confirm pipeline as a CSV upload. Only the first
/// sheet is read; empty trailing rows are dropped.
///
/// Throws [FormatException] when [bytes] is not a readable workbook.
String xlsxToCsv(List<int> bytes) {
  final Excel excel;
  try {
    excel = Excel.decodeBytes(bytes);
  } catch (_) {
    // decodeBytes throws UnsupportedError/FormatException on non-xlsx bytes.
    throw const FormatException('not a readable .xlsx workbook');
  }
  if (excel.tables.isEmpty) {
    throw const FormatException('empty workbook');
  }
  // Read the sheet that actually holds data (workbooks may keep blank sheets).
  final sheet = excel.tables.values.reduce(
    (a, b) => a.maxRows >= b.maxRows ? a : b,
  );
  if (sheet.maxRows == 0) throw const FormatException('empty sheet');
  final rows = sheet.rows
      .map((row) => [for (final cell in row) _csvValue(cell)])
      .toList();
  // Drop trailing blank rows (Excel files often carry them).
  while (rows.isNotEmpty && rows.last.every((field) => field.isEmpty)) {
    rows.removeLast();
  }
  if (rows.isEmpty) throw const FormatException('empty sheet');
  final headers = rows.first;
  return buildCsv(headers, rows.skip(1));
}

String _csvValue(Data? cell) {
  final value = cell?.value;
  if (value == null) return '';
  if (value is IntCellValue) return value.value.toString();
  if (value is DoubleCellValue) {
    final d = value.value;
    // Keep whole numbers clean: 1450.0 → "1450" (matches the CSV exporter).
    return d == d.roundToDouble() ? d.truncate().toString() : d.toString();
  }
  // excel 4.x models cells as a sealed CellValue hierarchy with no num
  // subtype, so a plain `is num` branch is dead code — every remaining
  // variant (text, formula, …) stringifies through toString().
  if (value is DateCellValue) {
    return DateTime(value.year, value.month, value.day).toIso8601String();
  }
  return value.toString();
}
