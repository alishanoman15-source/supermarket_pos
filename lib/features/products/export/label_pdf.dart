import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/barcode.dart';

/// A single label to print (SPEC §104): name, barcode, price.
class LabelSpec {
  final String name;
  final String barcode;
  final String price;
  final int copies;

  const LabelSpec({
    required this.name,
    required this.barcode,
    required this.price,
    this.copies = 1,
  });
}

/// Builds a 50×25 mm label sheet (N copies) and opens the print/share sheet.
/// EAN-13 is rendered from the real module encoding; other formats fall back to
/// a Code128-style text caption.
Future<void> printProductLabels(LabelSpec spec) async {
  final doc = pw.Document();
  const labelWidth = 50 * PdfPageFormat.mm;
  const labelHeight = 25 * PdfPageFormat.mm;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(8),
      build: (context) => [
        pw.Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < spec.copies.clamp(1, 200); i++)
              pw.Container(
                width: labelWidth,
                height: labelHeight,
                padding: const pw.EdgeInsets.all(2),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.4)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      spec.name,
                      maxLines: 1,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 2),
                    _bars(spec.barcode),
                    pw.SizedBox(height: 2),
                    pw.Text(spec.barcode, style: const pw.TextStyle(fontSize: 7)),
                    pw.Text(
                      spec.price,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    name: 'labels_${spec.barcode}.pdf',
    onLayout: (format) => doc.save(),
  );
}

pw.Widget _bars(String barcode) {
  final modules = ean13Modules(barcode);
  if (modules.isEmpty) {
    return pw.SizedBox(
      height: 24,
      child: pw.Center(
        child: pw.Text(barcode, style: const pw.TextStyle(fontSize: 6)),
      ),
    );
  }
  const moduleWidth = 0.22 * PdfPageFormat.mm;
  return pw.SizedBox(
    height: 24,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final module in modules.split(''))
          pw.Container(
            width: moduleWidth,
            color: module == '1' ? PdfColors.black : PdfColors.white,
          ),
      ],
    ),
  );
}
