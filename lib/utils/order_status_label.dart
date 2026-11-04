import 'package:get/get.dart';

/// Order list status in the app's language from the backend's status codes
/// 1–10 (as courier orders already do); any other value keeps [fallback], the
/// API's own text. A finished self-pickup order says "Picked up", not
/// "Delivered" (C-B26).
String orderStatusLabel(
  Object? status,
  String fallback, {
  bool selfPickup = false,
}) {
  final code = int.tryParse('${status ?? ''}');
  if (code == 9 && selfPickup) return 'core_status_9_pickup'.tr;
  return code != null && code >= 1 && code <= 10
      ? 'core_status_$code'.tr
      : fallback;
}
