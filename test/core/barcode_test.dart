import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/utils/barcode.dart';

void main() {
  group('ean13CheckDigit', () {
    test('known valid EAN-13 (4006381333931) → check digit 1', () {
      expect(ean13CheckDigit('400638133393'), 1);
    });

    test('known valid EAN-13 (5901234123457) → check digit 7', () {
      expect(ean13CheckDigit('590123412345'), 7);
    });

    test('all-zeros body → check digit 0', () {
      expect(ean13CheckDigit('000000000000'), 0);
    });

    test('rejects wrong length', () {
      expect(() => ean13CheckDigit('123'), throwsArgumentError);
      expect(() => ean13CheckDigit('0000000000000'), throwsArgumentError);
    });

    test('rejects non-digits', () {
      expect(() => ean13CheckDigit('00000000000A'), throwsArgumentError);
    });
  });

  group('buildEan13', () {
    test('produces 13 digits with valid check digit', () {
      final code = buildEan13('400638133393');
      expect(code, '4006381333931');
      expect(isValidEan13(code), isTrue);
    });
  });

  group('isValidEan13', () {
    test('accepts structurally valid codes', () {
      expect(isValidEan13('4006381333931'), isTrue);
      expect(isValidEan13('5901234123457'), isTrue);
    });

    test('rejects corrupted check digit', () {
      expect(isValidEan13('4006381333932'), isFalse);
    });

    test('rejects wrong length / non-numeric', () {
      expect(isValidEan13('40063813339'), isFalse);
      expect(isValidEan13('40063813339311'), isFalse);
      expect(isValidEan13('ABCDEFGHIJKLM'), isFalse);
      expect(isValidEan13(''), isFalse);
    });
  });

  group('ean13Modules (label printing)', () {
    test('encodes a valid EAN-13 into 95 modules with correct guards', () {
      final modules = ean13Modules('4006381333931');
      expect(modules.length, 95);
      expect(modules.startsWith('101'), isTrue);
      expect(modules.endsWith('101'), isTrue);
      expect(modules.substring(45, 50), '01010');
    });

    test('only emits bar/space characters', () {
      final modules = ean13Modules('5901234123457');
      expect(RegExp(r'^[01]+$').hasMatch(modules), isTrue);
    });

    test('returns an empty string for invalid input', () {
      expect(ean13Modules('4006381333932'), '');
      expect(ean13Modules('not-a-barcode'), '');
    });
  });
}
