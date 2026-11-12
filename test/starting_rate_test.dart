import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:saimpex_v2/l10n/app_translations.dart';
import 'package:saimpex_v2/models/service_repository.dart';

void main() {
  setUpAll(() => Get.addTranslations(AppTranslations().keys));

  test('laundry starting rate in Arabic has no English MRU/item', () {
    Get.locale = const Locale('ar');
    expect(startingRateLabel('40 MRU', 'item'), '40 أوقية / قطعة');
    expect(startingRateLabel('25 MRU/kg', ''), '25 أوقية / كغ');
    expect(startingRateLabel('150 MRU', ''), '150 أوقية');
  });

  test('English keeps MRU with the unit', () {
    Get.locale = const Locale('en');
    expect(startingRateLabel('40 MRU', 'item'), '40 MRU / item');
    expect(startingRateLabel('12.5 MRU/m', ''), '12.5 MRU / m');
  });
}
