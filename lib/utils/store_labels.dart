import 'dart:ui' show TextDirection;

import 'package:get/get.dart';

import 'api_language.dart';

final _rtlChar = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
final _ltrChar = RegExp(r'[A-Za-z0-9À-ɏ]');

/// The direction of a text from its first strong letter: Arabic → right to
/// left, Latin or a digit → left to right. Used for server texts (addresses)
/// that may be in either script whatever the app language.
TextDirection textDirectionOf(String text) {
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (_rtlChar.hasMatch(char)) return TextDirection.rtl;
    if (_ltrChar.hasMatch(char)) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

/// Store and product card labels (distance, time, offer, points) in the app's
/// language; the numbers come from the API.
String kmLabel(Object value) => 'core_unit_km'.trParams({'value': '$value'});

String minLabel(Object value) => 'core_unit_min'.trParams({'value': '$value'});

String offLabel(Object value) =>
    'core_percent_off'.trParams({'value': '$value'});

String pointsLabel(Object value) =>
    'core_points_available'.trParams({'value': '$value'});

/// A store's minimum order from the API ("150", "150.00", 150) as the amount
/// to show: "150", "99.5"; '' when there is none (missing, 0 or not a number).
String minOrderValue(Object? raw) {
  final n = double.tryParse('${raw ?? ''}'.trim());
  if (n == null || n <= 0) return '';
  return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
}

/// "Minimum order: 150 MRU" (currency per app language); '' when none.
String minOrderLabel(Object? raw) {
  final amount = minOrderValue(raw);
  if (amount.isEmpty) return '';
  return 'orders_min_order'.trParams({
    'amount': 'mru'.trParams({'amount': amount}),
  });
}

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
  // The server's "2026-11-12 10:26:04" is UTC without a zone (its ISO twin
  // ends in +00:00); it was shown as the phone's time. Same in Mauritania
  // (UTC+0), wrong on a phone in another zone.
  final utc = _serverUtc.hasMatch(text);
  final parsed = DateTime.tryParse(
    utc ? '${text.replaceFirst(' ', 'T')}Z' : text,
  );
  if (parsed == null) return text;
  return '$_lri${_dateTimeText(utc ? parsed.toLocal() : parsed)}$_pdi';
}

final _serverUtc = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');

/// "12 Nov 2026, 03:56 PM" with the month and AM/PM in the app language,
/// without the isolate (for building ranges).
String _dateTimeText(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  // A left-to-right mark after the month: an Arabic month name otherwise
  // pulled the year and time after it into right-to-left order
  // ("06 11:23 ,2026 نوفمبر AM").
  final month = 'svc_month_${time.month}'.tr + String.fromCharCode(0x200E);
  final date = '${two(time.day)} $month ${time.year}, ';
  // French writes the 24-hour clock ("15:56"), not "03:56 PM".
  if (apiLanguageCode() == 'fr') {
    return '$date${two(time.hour)}:${two(time.minute)}';
  }
  return '$date${two(hour)}:${two(time.minute)} '
      '${(time.hour < 12 ? 'pw_am' : 'pw_pm').tr}';
}

/// A date without the time, as Figma shows subscription dates: "Today",
/// "Tomorrow", else "06 Nov 2026" with the month in the app language.
/// '2026-11-06' and '2026-11-06 08:00:00' both work; any other text is
/// returned unchanged. [now] is for tests.
String readableDay(Object? raw, {DateTime? now}) {
  final text = '${raw ?? ''}'.trim();
  final time = DateTime.tryParse(text);
  if (time == null) return text;
  final today = now ?? DateTime.now();
  final day = DateTime(time.year, time.month, time.day);
  final diff = day.difference(DateTime(today.year, today.month, today.day));
  if (diff.inDays == 0) return 'svc_today'.tr;
  if (diff.inDays == 1) return 'svc_tomorrow'.tr;
  final month = 'svc_month_${time.month}'.tr + String.fromCharCode(0x200E);
  return '$_lri${time.day.toString().padLeft(2, '0')} $month ${time.year}$_pdi';
}

/// An ISO 8601 time with an offset ("2026-11-03T10:00:00+00:00") in the
/// phone's time zone, shown like [readableDateTime]; '' when it isn't a time.
String readableIsoTime(Object? raw) {
  final time = DateTime.tryParse('${raw ?? ''}'.trim());
  if (time == null) return '';
  return '$_lri${_dateTimeText(time.toLocal())}$_pdi';
}

/// A closed store's next opening (`opens_at`, ISO 8601 with offset, #185)
/// for "Opens …": the time alone when it is today on the phone ("10:00 AM",
/// "10:00" in French), else the day and time ("14 Nov, 10:00 AM"). '' when
/// there is none; any other text is returned as it is. [now] is for tests.
String opensAtLabel(Object? raw, {DateTime? now}) {
  final text = '${raw ?? ''}'.trim();
  if (text.isEmpty || text == 'null') return '';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  final time = parsed.toLocal();
  final today = now ?? DateTime.now();
  final full = _dateTimeText(time);
  final clock = full.split(', ').last;
  final sameDay =
      time.year == today.year &&
      time.month == today.month &&
      time.day == today.day;
  if (sameDay) return '$_lri$clock$_pdi';
  // "14 Nov 2026, 10:00 AM" without the year.
  final day = full.split(', ').first.replaceFirst(' ${time.year}', '');
  return '$_lri$day, $clock$_pdi';
}

// Left-to-right isolate around a time range (U+2066 … U+2069).
final _lri = String.fromCharCode(0x2066);
final _pdi = String.fromCharCode(0x2069);

/// A booking window from the API (`{start_iso, end_iso, …}`, #169) in the
/// phone's time zone: "12 Nov 2026, 08:00 AM – 10:00 AM" (the end date is
/// repeated only when it's another day). '' when there is no window.
String readableWindow(Object? window) {
  if (window is! Map) return '';
  final start = DateTime.tryParse('${window['start_iso'] ?? ''}'.trim());
  if (start == null) return '';
  final from = _dateTimeText(start.toLocal());
  final end = DateTime.tryParse('${window['end_iso'] ?? ''}'.trim());
  if (end == null) return '$_lri$from$_pdi';
  final localStart = start.toLocal();
  final localEnd = end.toLocal();
  final sameDay =
      localStart.year == localEnd.year &&
      localStart.month == localEnd.month &&
      localStart.day == localEnd.day;
  final to = _dateTimeText(end.toLocal());
  // Kept left to right (Unicode isolate): in Arabic the times and "–" were
  // reordered ("PM – 04:00 PM 02:00").
  return '$_lri$from – ${sameDay ? to.split(', ').last : to}$_pdi';
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
