import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three choices offered in Settings (SPEC §94 localization): follow the
/// device, or pin English / Urdu explicitly.
enum AppLanguage {
  system(null),
  english('en'),
  urdu('ur');

  final String? code;

  const AppLanguage(this.code);

  Locale? get locale => code == null ? null : Locale(code!);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.system,
      );
}

const _kLanguageKey = 'app_language';

/// Current selection, restored on every launch. `null` code = follow system.
final appLanguageProvider = NotifierProvider<AppLanguageController, AppLanguage>(
  AppLanguageController.new,
);

class AppLanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    _restore();
    return AppLanguage.system;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguageKey);
    final language = AppLanguage.fromCode(saved);
    if (language != state) state = language;
  }

  Future<void> set(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    if (language.code == null) {
      await prefs.remove(_kLanguageKey);
    } else {
      await prefs.setString(_kLanguageKey, language.code!);
    }
  }
}
