import 'package:get/get.dart';

/// Why an order was cancelled, from the remark of its "Cancelled" (status 10)
/// timeline entry. The server's fixed English remarks are shown in the app
/// language; a reason Admin typed is shown as written. Empty when the remark
/// says nothing more than "cancelled" (the customer's own cancel).
String cancelReasonLabel(String? remark) {
  final text = (remark ?? '').trim();
  final lower = text.toLowerCase();
  if (lower.isEmpty || lower == 'null' || lower == 'order cancelled') {
    return '';
  }
  if (lower.contains('not accepted by vendor')) {
    return 'core_cancel_not_accepted'.tr;
  }
  // "Order Cancelled by Vendor", "... by pharmacy", "... by water vendor".
  if (RegExp(
    r'^order cancell?ed by (vendor|pharmacy|water vendor)$',
  ).hasMatch(lower)) {
    return 'core_cancel_by_store'.tr;
  }
  return text;
}
