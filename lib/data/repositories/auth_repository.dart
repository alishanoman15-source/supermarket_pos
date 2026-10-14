import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../core/errors/app_exception.dart';

/// All Supabase Auth calls live here — never in widgets (SPEC §87).
class AuthRepository {
  final SupabaseClient _client;

  const AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // Google sign-in was removed on request: sign-in is email/password or
  // email OTP only, so every account is tied to a mailbox the user can
  // actually open (no anonymous Google-only identities).

  /// Email OTP sign-in (SPEC §4): sends a one-time code to [email].
  ///
  /// Supabase sends the code via its built-in email service (or the SMTP you
  /// configure). No SMS gateway needed. The code is verified with
  /// [verifyEmailOtp].
  Future<void> sendEmailOtp({required String email}) async {
    try {
      await _client.auth.signInWithOtp(email: email.trim());
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Verifies the email OTP and opens the session (SPEC §4).
  Future<void> verifyEmailOtp({required String email, required String token}) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.email,
        email: email.trim(),
        token: token.trim(),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Phone OTP sign-in (SPEC §4): sends a one-time code to [phone].
  ///
  /// Supabase must have the Phone provider enabled (Dashboard →
  /// Authentication → Providers → Phone) with an SMS gateway (Twilio, etc.).
  /// The phone number is passed through to the profile trigger so a first
  /// sign-in also records it on the profile row.
  Future<void> sendPhoneOtp({required String phone}) async {
    try {
      await _client.auth.signInWithOtp(
        phone: normalizePhone(phone),
        data: {'phone': normalizePhone(phone)},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Verifies the OTP received by SMS and opens the session (SPEC §4).
  Future<void> verifyPhoneOtp({required String phone, required String token}) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.sms,
        phone: normalizePhone(phone),
        token: token.trim(),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Canonical E.164-ish form: digits only with a leading `+`.
  /// Accepts `+92 300 1234567`, `923001234567`, `03001234567` (local PK
  /// numbers get the +92 prefix so OTP delivery matches the saved number).
  static String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return raw.trim();
    if (raw.trim().startsWith('+')) return '+$digits';
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (digits.startsWith('0') && digits.length >= 10) {
      // Local mobile format, e.g. 03001234567 → +923001234567.
      return '+92${digits.substring(1)}';
    }
    if (digits.length > 10 && !digits.startsWith('92')) {
      return '+$digits';
    }
    return '+$digits';
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
