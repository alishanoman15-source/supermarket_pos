/// Barcode helpers (SPEC §104): EAN-13 check digit + validation, Code128 fallback.
library;

/// Computes the EAN-13 check digit for the first 12 digits.
///
/// Algorithm: digits at odd positions (1-based: 1,3,5…) weight 1,
/// even positions weight 3; check = (10 - sum % 10) % 10.
int ean13CheckDigit(String first12) {
  if (first12.length != 12 || !RegExp(r'^\d{12}$').hasMatch(first12)) {
    throw ArgumentError.value(first12, 'first12', 'must be exactly 12 digits');
  }
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final digit = int.parse(first12[i]);
    sum += (i.isEven) ? digit : digit * 3;
  }
  return (10 - (sum % 10)) % 10;
}

/// Builds a complete 13-digit EAN-13 from the first 12 digits.
String buildEan13(String first12) => '$first12${ean13CheckDigit(first12)}';

/// Returns true if [code] is a structurally valid EAN-13
/// (13 digits + correct check digit).
bool isValidEan13(String code) {
  if (!RegExp(r'^\d{13}$').hasMatch(code)) return false;
  final expected = ean13CheckDigit(code.substring(0, 12));
  return int.parse(code[12]) == expected;
}

const _lCodes = [
  '0001101', '0011001', '0010011', '0111101', '0100011',
  '0110001', '0101111', '0111011', '0110111', '0001011',
];
const _gCodes = [
  '0100111', '0110011', '0011011', '0100001', '0011101',
  '0111001', '0000101', '0010001', '0001001', '0010111',
];
const _rCodes = [
  '1110010', '1100110', '1101100', '1000010', '1011100',
  '1001110', '1010000', '1000100', '1001000', '1110100',
];
const _parity = [
  '000000', '001011', '001101', '001110', '010011',
  '011001', '011100', '010101', '010110', '011010',
];

/// Encodes a valid 13-digit EAN-13 into a 95-module binary string where `1` is
/// a bar and `0` is a space (SPEC §104). Returns an empty string when [code] is
/// not a valid EAN-13.
String ean13Modules(String code) {
  if (!isValidEan13(code)) return '';
  final first = int.parse(code[0]);
  final pattern = _parity[first];
  final buffer = StringBuffer('101');
  for (var i = 1; i <= 6; i++) {
    final digit = int.parse(code[i]);
    buffer.write(pattern[i - 1] == '1' ? _gCodes[digit] : _lCodes[digit]);
  }
  buffer.write('01010');
  for (var i = 7; i <= 12; i++) {
    buffer.write(_rCodes[int.parse(code[i])]);
  }
  buffer.write('101');
  return buffer.toString();
}
