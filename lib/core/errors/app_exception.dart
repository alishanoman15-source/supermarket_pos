// Hide gotrue's `ErrorCode`; this file uses the app's own catalogue.
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException, AuthException;

import 'error_codes.dart';

/// Application-level exception carrying a stable backend [code] and an already
/// translated, user-facing [message]. UI shows [message] and may branch on
/// [code]; raw backend text is never displayed (SPEC §23).
class AppException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const AppException(this.code, this.message, [this.cause]);

  /// Normalises anything thrown by the Supabase client.
  factory AppException.from(Object error) {
    if (error is AppException) return error;

    if (error is PostgrestException) {
      // RPCs raise "CODE: human text"; DB constraints may surface codes too.
      final code = ErrorMessages.extractCode(error.message) ??
          _fromConstraint(error) ??
          ErrorCode.internalError;
      return AppException(code, ErrorMessages.message(code), error);
    }

    if (error is AuthException) {
      return AppException(_authCode(error), _authMessage(error), error);
    }

    return AppException(ErrorCode.internalError, ErrorMessages.describe(error), error);
  }

  static String? _fromConstraint(PostgrestException error) {
    // 23505 = unique_violation. Products carry unique SKU and barcode
    // indexes; taxonomy rows carry per-business name indexes
    // (categories_business_name_uq, brands_business_name_uq,
    // units_business_key_uq) — the raw index name tells them apart, so a
    // duplicate "Snacks" says "name already exists", not "SKU in use".
    if (error.code == '23505') {
      final msg = error.message.toLowerCase();
      if (msg.contains('barcode')) return ErrorCode.duplicateBarcode;
      if (msg.contains('categories_business_name') ||
          msg.contains('brands_business_name') ||
          msg.contains('units_business')) {
        return ErrorCode.duplicateName;
      }
      return ErrorCode.duplicateSku;
    }
    return null;
  }

  static String _authCode(AuthException e) {
    final status = e.statusCode;
    if (status == '400' || status == '401') return ErrorCode.unauthenticated;
    return ErrorCode.unauthenticated;
  }

  static String _authMessage(AuthException e) {
    final raw = e.message.toLowerCase();
    if (raw.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('email not confirmed')) {
      return 'Please confirm your email address first.';
    }
    if (raw.contains('already registered')) {
      return 'That email is already registered.';
    }
    if (raw.contains('password')) {
      return 'That password is not strong enough.';
    }
    return 'Authentication failed. Please try again.';
  }

  /// True when Supabase reported that the address already has an account
  /// (sign-up of an invited/registered user). Screens branch on this to give
  /// actionable, translated guidance instead of a bare error (SPEC §23).
  bool get isEmailAlreadyRegistered =>
      _causeContains('already registered') || _causeContains('user already exists');

  /// True when Supabase rejected the email/password pair itself.
  bool get isInvalidCredentials => _causeContains('invalid login credentials');

  bool _causeContains(String needle) {
    final c = cause;
    if (c is AuthException) return c.message.toLowerCase().contains(needle);
    return message.toLowerCase().contains(needle);
  }

  @override
  String toString() => 'AppException($code): $message';
}
