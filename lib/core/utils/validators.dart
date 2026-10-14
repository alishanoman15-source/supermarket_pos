/// Pure form validators. Messages are passed in so this stays localized-free
/// and easy to unit test (SPEC §96).
abstract final class Validators {
  /// Deliberately strict (SPEC §4): a local part without dots-at-the-edges,
  /// a dotted domain with labels that start/end alphanumeric, and a TLD of at
  /// least two letters — so `a@b.c`, `a@@b.com`, `x@y..com` and
  /// `..@gmail.com` are all rejected before they reach the backend.
  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9%+_~-]+(\.[A-Za-z0-9%+_~-]+)*'
    r'@[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
    r'(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*'
    r'\.[A-Za-z]{2,}$',
  );

  static String? email(String? value, {required String required, required String invalid}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required;
    if (!_email.hasMatch(v)) return invalid;
    return null;
  }

  /// Same as [email] but an empty value is allowed (optional email fields on
  /// customer/supplier forms still reject malformed addresses).
  static String? emailOptional(String? value, {required String invalid}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return _email.hasMatch(v) ? null : invalid;
  }

  /// Same as [phone] but an empty value is allowed (optional phone fields).
  static String? phoneOptional(String? value, {required String invalid}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return phone(v, required: invalid, invalid: invalid);
  }

  static String? password(
    String? value, {
    required String required,
    required String tooShort,
    int minLength = 8,
  }) {
    final v = value ?? '';
    if (v.isEmpty) return required;
    if (v.length < minLength) return tooShort;
    return null;
  }

  /// Phone (SPEC §4): digits with an optional leading `+`, 7–15 digits total
  /// (E.164 allows up to 15). Spaces, dashes and parentheses are tolerated.
  static String? phone(String? value, {required String required, required String invalid}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return required;
    final stripped = v.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(stripped)) return invalid;
    return null;
  }

  /// OTP code: exactly [length] digits (default 6).
  static String? otp(
    String? value, {
    required String required,
    required String invalid,
    int length = 6,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return required;
    if (!RegExp(r'^[0-9]+$').hasMatch(v) || v.length != length) return invalid;
    return null;
  }

  static String? requiredText(String? value, {required String message}) {
    if ((value?.trim() ?? '').isEmpty) return message;
    return null;
  }
}
