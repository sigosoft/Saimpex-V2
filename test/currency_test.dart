import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:saimpex_v2/l10n/app_translations.dart';
import 'package:saimpex_v2/utils/currency.dart';

/// The currency follows the app language: MRU in English and French,
/// أوقية in Arabic, wherever the price comes from.
void main() {
  setUpAll(() => Get.addTranslations(AppTranslations().keys));

  test('English and French show MRU', () {
    for (final code in ['en', 'fr']) {
      Get.locale = Locale(code);
      expect(mruAmount(260), '260 MRU');
      expect(mruUnit(), 'MRU');
      expect(localizeMru('MRU 260'), '260 MRU');
    }
  });

  test('Arabic shows أوقية, also for server texts', () {
    Get.locale = const Locale('ar');
    // The amount (with any sign) is kept left to right inside the line.
    String ar(String amount) =>
        '${String.fromCharCode(0x2066)}$amount${String.fromCharCode(0x2069)} أوقية';
    expect(mruAmount(260), ar('260'));
    expect(mruAmount('—'), ar('—'));
    expect(signedMru('+', 100), ar('+100'));
    expect(mruUnit(), 'أوقية');
    expect(localizeMru('260 MRU'), ar('260'));
    expect(localizeMru('MRU 260.50'), ar('260.50'));
    expect(localizeMru('Starts at 50 MRU'), 'Starts at 50 أوقية');
    expect(localizeMru('Free'), 'Free');
  });
}
