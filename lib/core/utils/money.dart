import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Money is always [Decimal] in Dart — never double/float (SPEC §6 rule).
Decimal decimalFrom(Object? value, {Decimal? fallback}) {
  if (value == null) return fallback ?? Decimal.zero;
  if (value is Decimal) return value;
  if (value is num) return Decimal.parse(value.toString());
  return Decimal.tryParse(value.toString()) ?? (fallback ?? Decimal.zero);
}

/// Formats money for display only (conversion to double is display-safe).
String formatMoney(
  Decimal amount, {
  String symbol = 'Rs',
  String locale = 'en_PK',
}) {
  final format = NumberFormat.currency(locale: locale, symbol: '$symbol ', decimalDigits: 2);
  return format.format(amount.toDouble());
}

/// Rounds a money value to 2 decimal places (banker-free half-up), matching
/// the backend's `numeric(14,2)` rounding in `complete_sale` (SPEC §55).
Decimal roundMoney(Decimal value) => value.round(scale: 2);

/// Divides two decimals without throwing on recurring fractions.
Decimal divideDecimal(Decimal a, Decimal b) =>
    (a / b).toDecimal(scaleOnInfinitePrecision: 10);

/// Constant 100 as a [Decimal] (percent helpers).
final Decimal hundred = Decimal.fromInt(100);

/// Formats a quantity, trimming trailing zeros for weight-based items.
String formatQty(Decimal qty) {
  final text = qty.toString();
  return text.contains('.') ? text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : text;
}
