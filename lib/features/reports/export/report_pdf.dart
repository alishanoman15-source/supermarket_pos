import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// A tabular report ready for PDF export (SPEC §20).
class ExportTable {
  final String title;
  final String subtitle;
  final List<String> headers;
  final List<List<String>> rows;
  final List<List<String>> summary;

  const ExportTable({
    required this.title,
    required this.headers,
    required this.rows,
    this.subtitle = '',
    this.summary = const [],
  });
}

/// Builds a branded PDF and opens the OS print/share sheet. Works on every
/// platform the app targets (web, desktop, mobile) without extra plugins.
Future<void> shareReportPdf(ExportTable table) async {
  final doc = pw.Document();
  final generated = DateFormat.yMMMd().add_jm().format(DateTime.now());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(table.title,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(generated, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9)),
      ),
      build: (context) => [
        if (table.subtitle.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(table.subtitle, style: const pw.TextStyle(fontSize: 11)),
          ),
        if (table.summary.isNotEmpty) ...[
          pw.Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              for (final s in table.summary)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(s.first, style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(s.length > 1 ? s[1] : '',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),
        ],
        pw.TableHelper.fromTextArray(
          headers: table.headers,
          data: table.rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    name: '${table.title.replaceAll(' ', '_')}.pdf',
    onLayout: (format) => doc.save(),
  );
}
