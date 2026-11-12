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
      '03 svc_month_11\u200E 2026, 10:00 AM',
    );
    expect(
      readableServerTime('02 Nov 2026, 09:22 PM'),
      '02 svc_month_11\u200E 2026, 09:22 PM',
    );
    expect(
      readableServerTime('01 Jan 2026 12:05 AM'),
      '01 svc_month_1\u200E 2026, 12:05 AM',
    );
    expect(readableServerTime('yesterday'), 'yesterday');
    expect(readableServerTime(null), '');
  });

  test('subscription dates: today, tomorrow, else the day', () {
    final now = DateTime(2026, 11, 12, 18, 30);
    expect(readableDay('2026-11-12 08:00:00', now: now), 'svc_today');
    expect(readableDay('2026-11-13', now: now), 'svc_tomorrow');
    expect(
      readableDay('2026-11-06 08:00:00', now: now),
      '06 svc_month_11‎ 2026',
    );
    expect(readableDay('', now: now), '');
    expect(readableDay('soon', now: now), 'soon');
  });
}
