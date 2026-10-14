import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/utils/money.dart';

void main() {
  group('decimalFrom', () {
    test('parses ints, doubles and strings exactly', () {
      expect(decimalFrom(10), Decimal.parse('10'));
      expect(decimalFrom('12.34'), Decimal.parse('12.34'));
      expect(decimalFrom(0.1) + decimalFrom(0.2), Decimal.parse('0.3'));
    });

    test('defaults to zero for null/garbage', () {
      expect(decimalFrom(null), Decimal.zero);
      expect(decimalFrom('abc'), Decimal.zero);
      expect(decimalFrom(null, fallback: Decimal.parse('5')), Decimal.parse('5'));
    });
  });

  group('formatMoney', () {
    test('renders two decimals with the given symbol', () {
      final text = formatMoney(Decimal.parse('1234.5'), symbol: 'Rs');
      expect(text, contains('1,234.50'));
      expect(text, contains('Rs'));
    });
  });

  group('formatQty', () {
    test('trims trailing zeros for weight-based quantities', () {
      expect(formatQty(Decimal.parse('2.500')), '2.5');
      expect(formatQty(Decimal.parse('3.000')), '3');
    });
  });
}
