import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/errors/app_exception.dart';
import 'package:supermarket_pos/core/errors/error_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  group('ErrorCode constants match SPEC §81', () {
    test('canonical codes are uppercase snake case', () {
      const codes = [
        ErrorCode.unauthenticated,
        ErrorCode.noBusiness,
        ErrorCode.noPermission,
        ErrorCode.shiftNotOpen,
        ErrorCode.shiftAlreadyOpen,
        ErrorCode.insufficientStock,
        ErrorCode.negativeStockNotAllowed,
        ErrorCode.invalidDiscount,
        ErrorCode.priceOverrideForbidden,
        ErrorCode.productNotFound,
        ErrorCode.productInactive,
        ErrorCode.cartEmpty,
        ErrorCode.negativeTotal,
        ErrorCode.duplicateIdempotencyKey,
        ErrorCode.duplicateBarcode,
        ErrorCode.duplicateSku,
        ErrorCode.duplicateName,
        ErrorCode.invalidInvoiceSequence,
        ErrorCode.insufficientPoints,
        ErrorCode.refundNeedsApproval,
        ErrorCode.countAlreadyApproved,
        ErrorCode.transferNotInTransit,
        ErrorCode.poNotApproved,
        ErrorCode.supplierHasOpenBills,
        ErrorCode.useRpc,
        ErrorCode.validationFailed,
        ErrorCode.internalError,
      ];
      for (final c in codes) {
        expect(RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(c), isTrue,
            reason: '$c must be UPPER_SNAKE_CASE');
      }
      // No duplicates.
      expect(codes.toSet().length, codes.length);
    });
  });

  group('ErrorMessages.message', () {
    test('every canonical code has a friendly message', () {
      const all = [
        ErrorCode.unauthenticated,
        ErrorCode.noBusiness,
        ErrorCode.noPermission,
        ErrorCode.shiftNotOpen,
        ErrorCode.shiftAlreadyOpen,
        ErrorCode.insufficientStock,
        ErrorCode.negativeStockNotAllowed,
        ErrorCode.invalidDiscount,
        ErrorCode.priceOverrideForbidden,
        ErrorCode.productNotFound,
        ErrorCode.productInactive,
        ErrorCode.cartEmpty,
        ErrorCode.negativeTotal,
        ErrorCode.duplicateIdempotencyKey,
        ErrorCode.duplicateBarcode,
        ErrorCode.duplicateSku,
        ErrorCode.duplicateName,
        ErrorCode.invalidInvoiceSequence,
        ErrorCode.insufficientPoints,
        ErrorCode.refundNeedsApproval,
        ErrorCode.countAlreadyApproved,
        ErrorCode.transferNotInTransit,
        ErrorCode.poNotApproved,
        ErrorCode.supplierHasOpenBills,
        ErrorCode.useRpc,
        ErrorCode.validationFailed,
        ErrorCode.internalError,
      ];
      for (final code in all) {
        final msg = ErrorMessages.message(code);
        expect(msg, isNotEmpty, reason: 'missing message for $code');
        expect(msg, isNot(ErrorMessages.fallback),
            reason: '$code should not fall through to generic message');
        expect(msg.endsWith('.'), isTrue,
            reason: 'message for $code should be a full sentence');
      }
    });

    test('unknown code falls back to generic message', () {
      expect(ErrorMessages.message('SOMETHING_NEW'),
          ErrorMessages.fallback);
    });
  });

  group('ErrorMessages.extractCode', () {
    test('extracts code from "CODE: text" backend format', () {
      expect(ErrorMessages.extractCode('INSUFFICIENT_STOCK: Not enough'),
          ErrorCode.insufficientStock);
      expect(ErrorMessages.extractCode('NO_PERMISSION: nope'),
          ErrorCode.noPermission);
    });

    test('returns null for non-coded messages', () {
      expect(ErrorMessages.extractCode('random failure'), isNull);
      expect(ErrorMessages.extractCode(''), isNull);
    });
  });

  group('ErrorMessages.describe', () {
    test('translates raw exception text containing a known code', () {
      expect(
        ErrorMessages.describe(
            Exception('SHIFT_NOT_OPEN: open a shift first')),
        ErrorMessages.message(ErrorCode.shiftNotOpen),
      );
    });

    test('falls back for unknown exceptions', () {
      expect(ErrorMessages.describe(Exception('weird')), ErrorMessages.fallback);
    });
  });

  group('AppException.from — unique violations (23505)', () {
    test('taxonomy name indexes map to DUPLICATE_NAME, not DUPLICATE_SKU', () {
      PostgrestException of(String constraint) => PostgrestException(
            message:
                'duplicate key value violates unique constraint "$constraint"',
            code: '23505',
          );

      final category = AppException.from(of('categories_business_name_uq'));
      expect(category.code, ErrorCode.duplicateName);
      expect(category.message, ErrorMessages.message(ErrorCode.duplicateName));

      final brand = AppException.from(of('brands_business_name_uq'));
      expect(brand.code, ErrorCode.duplicateName);

      final unit = AppException.from(of('units_business_key_uq'));
      expect(unit.code, ErrorCode.duplicateName);
    });

    test('product SKU/barcode indexes keep their own messages', () {
      PostgrestException of(String constraint) => PostgrestException(
            message:
                'duplicate key value violates unique constraint "$constraint"',
            code: '23505',
          );

      expect(AppException.from(of('products_sku_uq')).code,
          ErrorCode.duplicateSku);
      expect(AppException.from(of('products_barcode_uq')).code,
          ErrorCode.duplicateBarcode);
    });
  });
}
