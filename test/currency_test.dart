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
    expect(mruAmount(260), '260 أوقية');
    expect(mruAmount('—'), '— أوقية');
    expect(mruUnit(), 'أوقية');
    expect(localizeMru('260 MRU'), '260 أوقية');
    expect(localizeMru('MRU 260.50'), '260.50 أوقية');
    expect(localizeMru('Starts at 50 MRU'), 'Starts at 50 أوقية');
    expect(localizeMru('Free'), 'Free');
  });
}
