import 'package:get/get.dart';

/// Order list status in the app's language from the backend's status codes
/// 1–10 (as courier orders already do); any other value keeps [fallback], the
/// API's own text.
String orderStatusLabel(Object? status, String fallback) {
  final code = int.tryParse('${status ?? ''}');
  return code != null && code >= 1 && code <= 10
      ? 'core_status_$code'.tr
      : fallback;
}
