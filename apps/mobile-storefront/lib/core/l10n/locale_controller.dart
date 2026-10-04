import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'solary_locale';

/// Holds the app's current locale and lets any screen change it (see the
/// Account tab's language picker). Defaults to English, persisted across
/// restarts via shared_preferences.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    _restore();
  }

  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('ckb'), // Sorani Kurdish
  ];

  /// Arabic and Sorani Kurdish are both right-to-left — anything that
  /// isn't should be added to this set explicitly, not inferred, since
  /// getting this wrong silently mirrors the whole UI.
  static const _rtlLocales = {'ar', 'ckb'};

  bool get isRtl => _rtlLocales.contains(value.languageCode);

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    final match = supportedLocales.where((l) => l.languageCode == code).firstOrNull;
    if (match != null) value = match;
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
