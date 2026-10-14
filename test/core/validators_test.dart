import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('requires a value', () {
      expect(Validators.email('', required: 'req', invalid: 'bad'), 'req');
      expect(Validators.email(null, required: 'req', invalid: 'bad'), 'req');
    });

    test('rejects malformed and accepts valid', () {
      expect(Validators.email('nope', required: 'req', invalid: 'bad'), 'bad');
      expect(Validators.email('a@b.co', required: 'req', invalid: 'bad'), isNull);
    });

    test('rejects fake-looking addresses (SPEC §4)', () {
      // TLD shorter than two letters.
      expect(Validators.email('a@b.c', required: 'req', invalid: 'bad'), 'bad');
      // No TLD at all.
      expect(Validators.email('user@domain', required: 'req', invalid: 'bad'), 'bad');
      // Double dots in the domain.
      expect(Validators.email('x@y..com', required: 'req', invalid: 'bad'), 'bad');
      // Leading dots in the local part.
      expect(Validators.email('..@gmail.com', required: 'req', invalid: 'bad'), 'bad');
      // Two @ signs.
      expect(Validators.email('a@@b.com', required: 'req', invalid: 'bad'), 'bad');
      // Spaces.
      expect(Validators.email('a b@c.com', required: 'req', invalid: 'bad'), 'bad');
    });

    test('accepts common real-world addresses', () {
      expect(Validators.email('alisha15@gmail.com', required: 'req', invalid: 'bad'), isNull);
      expect(Validators.email('user.name+tag@example.co', required: 'req', invalid: 'bad'), isNull);
      expect(Validators.email('A@Example.COM', required: 'req', invalid: 'bad'), isNull);
    });
  });

  group('Validators.emailOptional / phoneOptional', () {
    test('empty stays empty, malformed is rejected', () {
      expect(Validators.emailOptional('', invalid: 'bad'), isNull);
      expect(Validators.emailOptional(null, invalid: 'bad'), isNull);
      expect(Validators.emailOptional('not-an-email', invalid: 'bad'), 'bad');
      expect(Validators.phoneOptional('', invalid: 'bad'), isNull);
      expect(Validators.phoneOptional(null, invalid: 'bad'), isNull);
      expect(Validators.phoneOptional('03301783237219873', invalid: 'bad'), 'bad');
      expect(Validators.phoneOptional('0300 1234567', invalid: 'bad'), isNull);
    });
  });

  group('Validators.password', () {
    test('enforces the minimum length', () {
      expect(Validators.password('', required: 'req', tooShort: 'short'), 'req');
      expect(Validators.password('abc', required: 'req', tooShort: 'short'), 'short');
      expect(Validators.password('abcdefgh', required: 'req', tooShort: 'short'), isNull);
    });
  });
}
