/// RFC 4180 CSV encoding (SPEC §63 import, §64 export).
///
/// The same encoder backs the product-import template and every CSV export, so
/// a file written by the app is always readable by the importer and by Excel.
library;

/// Escapes a single field: quotes are doubled and the value is wrapped when it
/// contains a comma, a quote or a line break.
String csvField(Object? value) {
  final text = value?.toString() ?? '';
  final needsQuotes =
      text.contains('"') || text.contains(',') || text.contains('\n') || text.contains('\r');
  if (!needsQuotes) return text;
  return '"${text.replaceAll('"', '""')}"';
}

/// Joins a header row and data rows into CSV text (each row terminated by
/// CRLF, as spreadsheet exporters expect).
String buildCsv(Iterable<Object?> headers, Iterable<Iterable<Object?>> rows) {
  final buffer = StringBuffer();
  buffer.write(headers.map(csvField).join(','));
  buffer.write('\r\n');
  for (final row in rows) {
    buffer.write(row.map(csvField).join(','));
    buffer.write('\r\n');
  }
  return buffer.toString();
}

/// UTF-8 byte order mark so Excel detects the encoding and shows non-ASCII
/// product names correctly.
const String csvBom = '\ufeff';

/// Full file body: BOM + [buildCsv].
String csvFile(Iterable<Object?> headers, Iterable<Iterable<Object?>> rows) =>
    csvBom + buildCsv(headers, rows);
