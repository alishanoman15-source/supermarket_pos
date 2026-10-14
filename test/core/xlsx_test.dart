import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/utils/xlsx.dart';

void main() {
  group('buildXlsx', () {
    test('produces a workbook that round-trips through xlsxToCsv', () {
      final bytes = buildXlsx(
        sheetName: 'products',
        headers: const ['name', 'selling_price', 'stock'],
        rows: const [
          ['Basmati Rice 5 kg', 1450, 12],
          ['Cola, 1.5 L', 180, 40],
          ['Quote "product"', 99.5, 0],
        ],
      );

      expect(bytes, isNotEmpty);
      // ZIP local file header magic (PK\x03\x04).
      expect(bytes.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);

      final csv = xlsxToCsv(bytes);
      final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();
      expect(lines, hasLength(4));
      expect(lines.first, 'name,selling_price,stock');
      expect(lines[1], 'Basmati Rice 5 kg,1450,12');
      // Commas and quotes survive the round-trip through CSV escaping.
      expect(lines[2], '"Cola, 1.5 L",180,40');
      expect(lines[3], '"Quote ""product""",99.5,0');
    });

    test('writes an empty body when there are no rows', () {
      final bytes = buildXlsx(
        sheetName: 'sheet',
        headers: const ['a'],
        rows: const [],
      );
      expect(bytes, isNotEmpty);
      final csv = xlsxToCsv(bytes);
      expect(csv.trim(), 'a');
    });
  });

  group('xlsxToCsv', () {
    test('rejects non-workbook bytes', () {
      expect(() => xlsxToCsv([1, 2, 3]), throwsFormatException);
    });
  });
}
