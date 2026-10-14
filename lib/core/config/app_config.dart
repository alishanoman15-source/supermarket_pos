import 'package:flutter/foundation.dart';

/// Central app configuration.
///
/// Values come from `--dart-define` (preferred, per CLI_MASTER_PROMPT rule #9):
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Fallback constants keep the existing dev flow working unchanged.
/// Before a production release, replace the fallbacks with empty strings so
/// a missing define fails fast instead of pointing at a stale project.
abstract final class AppConfig {
  static const String _fallbackUrl =
      'https://kbybajdnmcfgkkuwkuas.supabase.co';
  static const String _fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtieWJhamRubWNmZ2trdXdrdWFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NjQ2NzYsImV4cCI6MjEwNjM0MDY3Nn0.Jv6ZkB4jZX-Qxp-cdDrzO89on1fsEZJ9zpRf4K4P08w';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _fallbackUrl,
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _fallbackAnonKey,
  );

  /// True when configuration was supplied via `--dart-define`.
  static const bool hasExplicitConfig = bool.fromEnvironment('SUPABASE_URL');

  // Google sign-in was removed on request: sign-in is email/password or
  // email OTP only, so every account is tied to a verified mailbox.

  /// Guards against a blank/invalid configuration at startup.
  static void validate() {
    final urlOk = Uri.tryParse(supabaseUrl)?.hasScheme ?? false;
    if (!urlOk || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Invalid Supabase configuration. Pass --dart-define=SUPABASE_URL '
        'and --dart-define=SUPABASE_ANON_KEY (see README.md).',
      );
    }
    if (!kReleaseMode && !hasExplicitConfig) {
      debugPrint(
        'AppConfig: using fallback Supabase credentials. '
        'Prefer --dart-define (see README.md).',
      );
    }
  }
}
