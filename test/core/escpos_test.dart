import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/utils/escpos.dart';
import 'package:supermarket_pos/data/models/cart.dart';
import 'package:supermarket_pos/features/pos/receipt.dart';

void main() {
  group('EscPosEncoder', () {
    test('starts with ESC @ (initialize) and ends with a cut', () {
      final esc = EscPosEncoder(charsPerLine: 32)..initialize();
      esc.line('Hello');
      esc.cut();
      final bytes = esc.toBytes();
      expect(bytes.sublist(0, 2), [0x1B, 0x40]);
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    });

    test('bold toggles with ESC E', () {
      final esc = EscPosEncoder()..initialize();
      esc.line('Title', bold: true);
      final text = utf8.decode(esc.toBytes(), allowMalformed: true);
      expect(text.contains('Title'), isTrue);
      expect(esc.toBytes(), containsAllInOrder([0x1B, 0x45, 0x01]));
      expect(esc.toBytes(), containsAllInOrder([0x1B, 0x45, 0x00]));
    });

    test('non-ASCII text falls back to ? instead of corrupting the ticket', () {
      expect(EscPosEncoder.asciiSafe('چاولے'), '?????');
      expect(EscPosEncoder.asciiBytes('Basmati'), ascii.encode('Basmati'));
      expect(() => ascii.encode(EscPosEncoder.asciiSafe('Rs 100')), returnsNormally);
    });

    test('wraps long lines at the paper width, breaking on spaces', () {
      final lines = EscPosEncoder.wrapAscii('one two three four five six', 12);
      expect(lines.every((l) => l.length <= 12), isTrue);
      expect(lines.join(' '), 'one two three four five six');
    });

    test('keyValue keeps both columns on a single line', () {
      final esc = EscPosEncoder(charsPerLine: 32)..initialize();
      esc.keyValue('Total', 'Rs 2,900.00', bold: true);
      final raw = utf8.decode(esc.toBytes(), allowMalformed: true);
      // Strip command sequences (ESC x, GS x x) and control bytes, keeping text.
      final text = raw
          .replaceAll(RegExp(r'\x1B.'), '')
          .replaceAll(RegExp(r'\x1D..'), '');
      final printed = text
          .split('\n')
          .map((line) => line
              .split('')
              .where((ch) => ch.codeUnitAt(0) >= 0x20)
              .join())
          .firstWhere((line) => line.contains('Total'), orElse: () => '');
      expect(printed.length, 32);
      expect(printed.trimRight().endsWith('Rs 2,900.00'), isTrue);
    });
  });

  group('buildReceiptEscPos', () {
    ReceiptData receipt() => ReceiptData(
          businessName: 'Karachi Mart',
          branchName: 'Model Town',
          invoiceNumber: 'INV-000123',
          soldAt: DateTime(2026, 10, 9, 14, 30),
          cashierName: 'Ahmed',
          customerName: 'Walk-in',
          lines: [
            CartLine(
              productId: 'p1',
              name: 'Basmati Rice 5 kg',
              unitPrice: Decimal.parse('1450'),
              basePrice: Decimal.parse('1450'),
              qty: Decimal.parse('2'),
              taxRate: Decimal.zero,
            ),
          ],
          subtotal: Decimal.parse('2900.00'),
          discountTotal: Decimal.zero,
          taxTotal: Decimal.zero,
          grandTotal: Decimal.parse('2900.00'),
          payments: [
            PaymentLine(method: 'cash', amount: Decimal.parse('3000')),
          ],
          changeDue: Decimal.parse('100.00'),
        );

    test('emits the invoice, totals and cut command', () {
      final bytes = buildReceiptEscPos(receipt());
      final text = utf8.decode(bytes, allowMalformed: true);
      expect(text, contains('Karachi Mart'));
      expect(text, contains('INV-000123'));
      expect(text, contains('Basmati Rice 5 kg x2'));
      expect(text, contains('Total'));
      expect(text, contains('Rs 2,900.00'));
      expect(text, contains('Change'));
      expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    });
  });
}
