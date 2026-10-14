import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/utils/validators.dart';
import 'package:supermarket_pos/data/repositories/auth_repository.dart';

void main() {
  group('Validators.phone (SPEC §4)', () {
    const req = 'required';
    const inv = 'invalid';

    test('rejects empty', () {
      expect(Validators.phone('', required: req, invalid: inv), req);
      expect(Validators.phone(null, required: req, invalid: inv), req);
      expect(Validators.phone('   ', required: req, invalid: inv), req);
    });

    test('rejects too short / non-numeric', () {
      expect(Validators.phone('12345', required: req, invalid: inv), inv);
      expect(Validators.phone('abc-defg', required: req, invalid: inv), inv);
      expect(Validators.phone('+92 300 123456789012', required: req, invalid: inv), inv);
    });

    test('accepts common formats', () {
      expect(Validators.phone('+923001234567', required: req, invalid: inv), isNull);
      expect(Validators.phone('0300 1234567', required: req, invalid: inv), isNull);
      expect(Validators.phone('+1 (555) 123-4567', required: req, invalid: inv), isNull);
    });
  });

  group('Validators.otp (SPEC §4)', () {
    const req = 'required';
    const inv = 'invalid';

    test('requires exactly six digits', () {
      expect(Validators.otp('', required: req, invalid: inv), req);
      expect(Validators.otp('12345', required: req, invalid: inv), inv);
      expect(Validators.otp('1234567', required: req, invalid: inv), inv);
      expect(Validators.otp('12345a', required: req, invalid: inv), inv);
      expect(Validators.otp('123456', required: req, invalid: inv), isNull);
    });
  });

  group('AuthRepository.normalizePhone (SPEC §4)', () {
    test('keeps explicit + numbers, strips separators', () {
      expect(AuthRepository.normalizePhone('+92 300-1234567'), '+923001234567');
      expect(AuthRepository.normalizePhone('+1 (555) 123-4567'), '+15551234567');
    });

    test('converts local PK numbers to +92', () {
      expect(AuthRepository.normalizePhone('03001234567'), '+923001234567');
      expect(AuthRepository.normalizePhone('0300 1234567'), '+923001234567');
    });

    test('handles 00-prefixed international dialling', () {
      expect(AuthRepository.normalizePhone('0092 300 1234567'), '+923001234567');
    });

    test('adds + to bare country-code numbers', () {
      expect(AuthRepository.normalizePhone('923001234567'), '+923001234567');
    });
  });
}
