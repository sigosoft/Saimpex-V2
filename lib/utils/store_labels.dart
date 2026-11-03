import 'package:get/get.dart';

import 'api_language.dart';

/// Store and product card labels (distance, time, offer, points) in the app's
/// language; the numbers come from the API.
String kmLabel(Object value) => 'core_unit_km'.trParams({'value': '$value'});

String minLabel(Object value) => 'core_unit_min'.trParams({'value': '$value'});

String offLabel(Object value) =>
    'core_percent_off'.trParams({'value': '$value'});

String pointsLabel(Object value) =>
    'core_points_available'.trParams({'value': '$value'});

final _minText = RegExp(
  r'^(\d+(?:\.\d+)?(?:\s*-\s*\d+(?:\.\d+)?)?)\s*min$',
  caseSensitive: false,
);
final _kmText = RegExp(r'^(\d+(?:\.\d+)?)\s*km$', caseSensitive: false);
final _offText = RegExp(r'^(\d+(?:\.\d+)?)\s*%\s*off$', caseSensitive: false);

/// The API's ready-made card texts ("14-19 min", "1.2 Km", "9% OFF") are
/// English only; rebuilds the plain ones in the app's language and leaves
/// any other text as it is.
String localizedStoreText(Object? text) {
  final value = (text ?? '').toString().trim();
  final min = _minText.firstMatch(value);
  if (min != null) return minLabel(min.group(1)!.replaceAll(' ', ''));
  final km = _kmText.firstMatch(value);
  if (km != null) return kmLabel(km.group(1)!);
  final off = _offText.firstMatch(value);
  if (off != null) return offLabel(off.group(1)!);
  return value;
}

/// "1 item" / "3 items" in the app language (the plural key alone read
/// "1 items" / "1 articles").
String itemsCountLabel(Object count) {
  final n = int.tryParse('$count');
  return (n == 1 ? 'orders_items_count_one' : 'orders_items_count').trParams({
    'count': '$count',
  });
}

/// A rating as the cards show it: "4.7", "5"; the API sometimes sends
/// "4.666667". Empty when there is none.
String ratingLabel(Object? value) {
  final n = double.tryParse('${value ?? ''}'.trim());
  if (n == null) return '${value ?? ''}'.trim();
  final one = n.toStringAsFixed(1);
  return one.endsWith('.0') ? one.substring(0, one.length - 2) : one;
}

/// '2026-11-02 12:22:12' → '02 Nov 2026, 12:22 PM' with the month in the app
/// language (as order details); any other text is returned unchanged.
String readableDateTime(Object? raw) {
  final text = '${raw ?? ''}'.trim();
  final time = DateTime.tryParse(text);
  if (time == null) return text;
  String two(int n) => n.toString().padLeft(2, '0');
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final month = 'svc_month_${time.month}'.tr;
  return '${two(time.day)} $month ${time.year}, '
      '${two(hour)}:${two(time.minute)} ${time.hour < 12 ? 'AM' : 'PM'}';
}

const _englishMonths = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

/// Order timeline times come as "03 Nov 2026 10:00 AM" (or with a comma
/// after the year); shown like [readableDateTime], with the month in the app
/// language. Anything else is returned as it is.
String readableServerTime(Object? raw) {
  final text = '${raw ?? ''}'.trim();
  final match = RegExp(
    r'^(\d{1,2}) ([A-Za-z]{3}) (\d{4}),? (\d{1,2}):(\d{2}) ?([AaPp][Mm])$',
  ).firstMatch(text);
  if (match == null) return text;
  final month = _englishMonths.indexOf(match.group(2)!.toLowerCase()) + 1;
  if (month == 0) return text;
  var hour = int.parse(match.group(4)!) % 12;
  if (match.group(6)!.toUpperCase() == 'PM') hour += 12;
  final time = DateTime(
    int.parse(match.group(3)!),
    month,
    int.parse(match.group(1)!),
    hour,
    int.parse(match.group(5)!),
  );
  return readableDateTime(time.toIso8601String());
}

/// A server row's `name_<language>`, English when that is empty.
String localizedName(Map row, [String key = 'name']) {
  final local = '${row['${key}_${apiLanguageCode()}'] ?? ''}'.trim();
  return local.isNotEmpty ? local : '${row['${key}_en'] ?? ''}'.trim();
}
