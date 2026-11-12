import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/utils/store_labels.dart';

void main() {
  test('ratings show at most one decimal', () {
    expect(ratingLabel('4.666667'), '4.7');
    expect(ratingLabel(5), '5');
    expect(ratingLabel('4.0'), '4');
    expect(ratingLabel(null), '');
    expect(ratingLabel('New'), 'New');
  });

  // No translations are loaded here, so the month shows as its key.
  test('order timeline times use the app month', () {
    expect(
      readableServerTime('03 Nov 2026 10:00 AM'),
      '\u206603 svc_month_11\u200E 2026, 10:00 pw_am\u2069',
    );
    expect(
      readableServerTime('02 Nov 2026, 09:22 PM'),
      '\u206602 svc_month_11\u200E 2026, 09:22 pw_pm\u2069',
    );
    expect(
      readableServerTime('01 Jan 2026 12:05 AM'),
      '\u206601 svc_month_1\u200E 2026, 12:05 pw_am\u2069',
    );
    expect(readableServerTime('yesterday'), 'yesterday');
    expect(readableServerTime(null), '');
  });

  test('text direction follows the first letter', () {
    expect(textDirectionOf('32PC+9MV, La Capitale'), TextDirection.ltr);
    expect(textDirectionOf('نواكشوط، تفرغ زينة'), TextDirection.rtl);
    expect(textDirectionOf('  , حي 5'), TextDirection.rtl);
    expect(textDirectionOf(''), TextDirection.ltr);
  });

  test('store minimum order: amount only when above zero', () {
    expect(minOrderValue('150.00'), '150');
    expect(minOrderValue(99.5), '99.50');
    expect(minOrderValue(0), '');
    expect(minOrderValue(null), '');
    expect(minOrderValue('none'), '');
    expect(minOrderLabel(0), '');
    expect(minOrderLabel(150), isNotEmpty);
  });

  test('subscription dates: today, tomorrow, else the day', () {
    final now = DateTime(2026, 11, 12, 18, 30);
    expect(readableDay('2026-11-12 08:00:00', now: now), 'svc_today');
    expect(readableDay('2026-11-13', now: now), 'svc_tomorrow');
    expect(
      readableDay('2026-11-06 08:00:00', now: now),
      '${String.fromCharCode(0x2066)}06 svc_month_11'
      '${String.fromCharCode(0x200E)} 2026${String.fromCharCode(0x2069)}',
    );
    expect(readableDay('', now: now), '');
    expect(readableDay('soon', now: now), 'soon');
  });

  test('server UTC times show in the phone time zone', () {
    final local = DateTime.utc(2026, 11, 12, 10, 26).toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    expect(
      readableDateTime('2026-11-12 10:26:04'),
      contains(
        '${hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}',
      ),
    );
  });
}
