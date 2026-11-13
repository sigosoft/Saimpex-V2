// Labels built from English server values (slots, clock times, plan
// frequencies) in the app language, and server UTC times.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saimpex_v2/l10n/app_locale.dart';
import 'package:saimpex_v2/l10n/app_translations.dart';
import 'package:saimpex_v2/models/water_repository.dart';
import 'package:saimpex_v2/utils/store_labels.dart';

final _lri = String.fromCharCode(0x2066);
final _pdi = String.fromCharCode(0x2069);

Future<void> _language(String code) async {
  // Not AppLocale.change: Get.updateLocale needs a running app.
  SharedPreferences.setMockInitialValues({'app_language': code});
  await AppLocale.load();
  Get.locale = Locale(code);
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    Get.addTranslations(AppTranslations().keys);
  });

  group('slotRangeLabel', () {
    test('English keeps the value', () async {
      await _language('en');
      expect(slotRangeLabel('8–10 AM'), '8–10 AM');
      expect(slotRangeLabel('8 - 10 AM'), '8–10 AM');
    });

    test('French: 24-hour, one meridiem for the range', () async {
      await _language('fr');
      expect(slotRangeLabel('8–10 AM'), '8h–10h');
      expect(slotRangeLabel('10–12 PM'), '10h–12h');
      expect(slotRangeLabel('12–2 PM'), '12h–14h');
      expect(slotRangeLabel('4–6 PM'), '16h–18h');
      expect(slotRangeLabel('Late night'), 'Tard le soir');
    });

    test('Arabic: numbers kept left to right', () async {
      await _language('ar');
      expect(slotRangeLabel('2–4 PM'), '${_lri}2–4$_pdi م');
    });
  });

  test('clockLabel', () async {
    await _language('fr');
    expect(clockLabel('11:59 PM'), '23:59');
    expect(clockLabel('9:05 AM'), '09:05');
    await _language('en');
    expect(clockLabel('11:59 PM'), '11:59 PM');
    expect(clockLabel('soon'), 'soon');
  });

  test('waterFrequencyLabel: by key; unknown keys say Custom', () async {
    await _language('fr');
    expect(waterFrequencyLabel('weekly', 'Weekly'), 'Hebdomadaire');
    expect(waterFrequencyLabel('monthly', 'Monthly'), 'Mensuel');
    expect(waterFrequencyLabel('every_3_days', 'Every 3 days'), 'Personnalisé');
    await _language('en');
    expect(waterFrequencyLabel('every_3_days', 'Every 3 days'), 'Every 3 days');
  });

  test('parseServerTime reads zone-less server times as UTC', () {
    expect(
      parseServerTime('2026-11-07 06:00:02'),
      DateTime.utc(2026, 11, 7, 6, 0, 2).toLocal(),
    );
    expect(
      parseServerTime('2026-11-07T06:00:02+01:00'),
      DateTime.utc(2026, 11, 7, 5, 0, 2).toLocal(),
    );
    expect(parseServerTime('—'), isNull);
  });
}
