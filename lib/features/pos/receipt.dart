import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/escpos.dart';
import '../../core/utils/money.dart';
import '../../core/utils/share_file.dart';
import '../../data/models/cart.dart';
import '../../data/models/sale.dart';

/// Everything needed to render a receipt (SPEC §21): the server result plus the
/// cart snapshot (totals are taken from the server response).
class ReceiptData {
  final String businessName;
  final String? branchName;
  final String? footer;
  final String invoiceNumber;
  final DateTime soldAt;
  final String? cashierName;
  final String? customerName;
  final List<CartLine> lines;
  final Decimal subtotal;
  final Decimal discountTotal;
  final Decimal taxTotal;
  final Decimal grandTotal;
  final List<PaymentLine> payments;
  final Decimal changeDue;

  const ReceiptData({
    required this.businessName,
    required this.invoiceNumber,
    required this.soldAt,
    required this.lines,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.payments,
    required this.changeDue,
    this.branchName,
    this.footer,
    this.cashierName,
    this.customerName,
  });

  /// Rebuilds a receipt from a stored sale (sales history / sale detail,
  /// SPEC §33, §39): the snapshot lines and tenders are re-read so the reprint
  /// always shows the historical prices (SPEC §95 rule 7).
  factory ReceiptData.fromSale({
    required Sale sale,
    required List<SaleItem> items,
    required List<SalePayment> payments,
    required String businessName,
    String? branchName,
    String? footer,
    String? cashierName,
    String? customerName,
  }) =>
      ReceiptData(
        businessName: businessName,
        branchName: branchName,
        footer: footer,
        invoiceNumber: sale.invoiceNumber,
        soldAt: sale.soldAt,
        cashierName: cashierName,
        customerName: customerName,
        lines: [
          for (final item in items)
            CartLine(
              productId: item.productId,
              name: item.nameSnapshot,
              sku: item.skuSnapshot,
              barcode: item.barcodeSnapshot,
              unitPrice: item.unitPrice,
              basePrice: item.unitPrice,
              qty: item.qty,
              discount: item.discount,
              taxRate: item.taxRate,
            ),
        ],
        subtotal: sale.subtotal,
        discountTotal: sale.discountTotal,
        taxTotal: sale.taxTotal,
        grandTotal: sale.grandTotal,
        payments: [
          for (final payment in payments)
            PaymentLine(
              method: payment.method,
              amount: payment.amount,
              reference: payment.reference,
            ),
        ],
        changeDue: sale.changeDue,
      );

  factory ReceiptData.fromResult({
    required SaleResult result,
    required CartState cart,
    required String businessName,
    String? branchName,
    String? footer,
    String? cashierName,
  }) =>
      ReceiptData(
        businessName: businessName,
        branchName: branchName,
        footer: footer,
        invoiceNumber: result.invoiceNumber,
        soldAt: DateTime.now(),
        cashierName: cashierName,
        customerName: cart.customerName,
        lines: cart.lines,
        subtotal: result.subtotal,
        discountTotal: result.discountTotal,
        taxTotal: result.taxTotal,
        grandTotal: result.grandTotal,
        payments: const [],
        changeDue: result.changeDue,
      );
}

String _money(Decimal value) => formatMoney(value);

/// Builds a 58 mm thermal-friendly A4/roll PDF receipt.
Future<Uint8List> buildReceiptPdf(ReceiptData data) async {
  final doc = pw.Document();
  final date = data.soldAt;
  final stamp =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 297 * PdfPageFormat.mm,
          marginAll: 6 * PdfPageFormat.mm),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(data.businessName,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ),
          if (data.branchName != null) pw.Center(child: pw.Text(data.branchName!)),
          pw.SizedBox(height: 6),
          pw.Divider(),
          pw.Text('Invoice: ${data.invoiceNumber}'),
          pw.Text('Date: $stamp'),
          if (data.cashierName != null) pw.Text('Cashier: ${data.cashierName}'),
          pw.Text('Customer: ${data.customerName ?? 'Guest'}'),
          pw.Divider(),
          for (final line in data.lines)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text('${line.name} x${formatQty(line.qty)}')),
                pw.Text(_money(line.net)),
              ],
            ),
          pw.Divider(),
          _totalRow('Subtotal', data.subtotal),
          if (data.discountTotal > Decimal.zero) _totalRow('Discount', -data.discountTotal),
          if (data.taxTotal > Decimal.zero) _totalRow('Tax', data.taxTotal),
          _totalRow('Total', data.grandTotal, bold: true),
          pw.Divider(),
          pw.Text('Change: ${_money(data.changeDue)}'),
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text(data.footer ?? 'Thank you for your business!')),
        ],
      ),
    ),
  );
  return doc.save();
}

pw.Widget _totalRow(String label, Decimal value, {bool bold = false}) {
  final style = bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [pw.Text(label, style: style), pw.Text(_money(value), style: style)],
  );
}

/// Opens the system print sheet with the receipt PDF (SPEC §21, §39).
Future<void> printReceipt(ReceiptData data) async {
  final bytes = await buildReceiptPdf(data);
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: data.invoiceNumber);
}

/// Hands the receipt PDF to the platform share sheet (SPEC §40 digital receipt).
Future<void> shareReceipt(ReceiptData data) async {
  final bytes = await buildReceiptPdf(data);
  await sharePdfFile(fileName: '${data.invoiceNumber}.pdf', bytes: bytes);
}

/// Builds the same receipt as raw ESC/POS bytes for a thermal printer that
/// accepts a ticket file over Bluetooth/USB/network (SPEC §39).
List<int> buildReceiptEscPos(ReceiptData data, {int charsPerLine = 48}) {
  final esc = EscPosEncoder(charsPerLine: charsPerLine)..initialize();
  final date = data.soldAt;
  final stamp =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  esc.line(data.businessName, bold: true, center: true, large: true);
  final branch = data.branchName;
  if (branch != null && branch.isNotEmpty) esc.line(branch, center: true);
  esc.rule();
  esc.keyValue('Invoice', data.invoiceNumber);
  esc.keyValue('Date', stamp);
  final cashier = data.cashierName;
  if (cashier != null && cashier.isNotEmpty) esc.keyValue('Cashier', cashier);
  esc.keyValue('Customer', data.customerName ?? 'Guest');
  esc.rule();
  for (final line in data.lines) {
    esc.keyValue('${line.name} x${formatQty(line.qty)}', _money(line.net));
  }
  esc.rule();
  esc.keyValue('Subtotal', _money(data.subtotal));
  if (data.discountTotal > Decimal.zero) esc.keyValue('Discount', '-${_money(data.discountTotal)}');
  if (data.taxTotal > Decimal.zero) esc.keyValue('Tax', _money(data.taxTotal));
  esc.keyValue('Total', _money(data.grandTotal), bold: true);
  esc.rule();
  for (final payment in data.payments) {
    esc.keyValue(payment.method, _money(payment.amount));
  }
  esc.keyValue('Change', _money(data.changeDue));
  esc.line(data.footer ?? 'Thank you for your business!', center: true);
  esc.cut();
  return esc.toBytes();
}

/// Shares the ESC/POS ticket through the platform share sheet (SPEC §39).
Future<void> shareReceiptEscPos(ReceiptData data) =>
    shareEscPosFile(
      fileName: '${data.invoiceNumber}.escpos',
      bytes: buildReceiptEscPos(data),
    );
