import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/utils/csv.dart';

void main() {
  group('csvField', () {
    test('leaves plain values untouched', () {
      expect(csvField('Rice'), 'Rice');
      expect(csvField(12), '12');
      expect(csvField(null), '');
    });

    test('quotes commas, quotes and newlines', () {
      expect(csvField('a,b'), '"a,b"');
      expect(csvField('say "hi"'), '"say ""hi"""');
      expect(csvField('line1\nline2'), '"line1\nline2"');
    });
  });

  group('buildCsv', () {
    test('writes a header row and CRLF-terminated data rows', () {
      final csv = buildCsv(const ['name', 'sku'], [
        ['Rice', 'R-1'],
        ['Sugar', 'S,1'],
      ]);
      expect(csv, 'name,sku\r\nRice,R-1\r\nSugar,"S,1"\r\n');
    });

    test('round-trips through the importer shape (name + price columns)', () {
      final csv = buildCsv(
        const ['name', 'purchase_price', 'selling_price'],
        [
          ['Dal 1 kg', '100', '130'],
        ],
      );
      final lines = csv.split('\r\n');
      expect(lines.first, 'name,purchase_price,selling_price');
      expect(lines[1], 'Dal 1 kg,100,130');
    });
  });

  group('csvFile', () {
    test('prefixes a UTF-8 BOM so Excel reads non-ASCII names', () {
      final file = csvFile(const ['name'], [
        ['چاولے'],
      ]);
      expect(file.startsWith('\ufeff'), isTrue);
      expect(file.contains('چاولے'), isTrue);
    });
  });
}
