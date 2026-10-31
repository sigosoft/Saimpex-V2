import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language (en, fr or ar). Saved on the device so it survives a
/// restart; changing it switches the UI translations and, for Arabic, the
/// layout direction (right to left).
class AppLocale {
  AppLocale._();

  static const _prefsKey = 'app_language';
  static const supportedCodes = ['en', 'fr', 'ar'];
  static const supportedLocales = [Locale('en'), Locale('fr'), Locale('ar')];
  static const fallbackLocale = Locale('en');

  static const _labels = {'en': 'English', 'fr': 'Français', 'ar': 'العربية'};

  static String _code = 'en';

  /// The current language code: `en`, `fr` or `ar`.
  static String get code => _code;

  static Locale get locale => Locale(_code);

  /// The language's own name, as the language picker lists it.
  static String get label => _labels[_code]!;

  static bool get isRtl => _code == 'ar';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedCodes.contains(saved)) _code = saved;
  }

  /// Switches the app to [code] and remembers it.
  static Future<void> change(String code) async {
    final next = codeFor(code);
    _code = next;
    await Get.updateLocale(Locale(next));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, next);
  }

  /// Accepts a code (`fr`, `FR`) or a picker label (`Français`).
  static String codeFor(String value) {
    final text = value.trim().toLowerCase();
    if (text == 'fr' || text == 'français' || text == 'francais') return 'fr';
    if (text == 'ar' || text == 'العربية') return 'ar';
    return 'en';
  }
}
