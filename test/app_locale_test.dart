// An unexpected language value keeps the current language instead of
// quietly switching the app to English (language reset, retest 3 Nov).

import 'package:flutter_test/flutter_test.dart';

import 'package:saimpex_v2/l10n/app_locale.dart';

void main() {
  test('codes and picker labels map to their language', () {
    expect(AppLocale.codeFor('EN'), 'en');
    expect(AppLocale.codeFor('English'), 'en');
    expect(AppLocale.codeFor('FR'), 'fr');
    expect(AppLocale.codeFor('Français'), 'fr');
    expect(AppLocale.codeFor('AR'), 'ar');
    expect(AppLocale.codeFor('العربية'), 'ar');
  });

  test('an unknown value keeps the current language', () {
    expect(AppLocale.codeFor(''), AppLocale.code);
    expect(AppLocale.codeFor('Deutsch'), AppLocale.code);
  });
}
