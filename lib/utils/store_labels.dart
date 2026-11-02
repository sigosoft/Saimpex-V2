import 'package:get/get.dart';

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
