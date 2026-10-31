import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import 'api_language.dart';

/// Payment methods Admin has switched on or off (GET customer/paymentMethods,
/// API §6.30). Checkouts hide the ones that are off. Until the list has
/// loaded, or if it can't be loaded, every method counts as on; the server
/// still refuses a disabled one with a translated message.
class PaymentMethods {
  PaymentMethods._();

  static Set<String>? _enabled;

  /// Sets the enabled list directly; null means "not loaded".
  @visibleForTesting
  static set enabledForTest(Set<String>? enabled) => _enabled = enabled;

  /// Whether payment type [type] ('1' cash, '2' online, '3' wallet, '4' Pay
  /// After Delivery) may be offered.
  static bool isOn(String type) => _enabled?.contains(type) ?? true;

  /// Reloads the list. Returns true when it changed what [isOn] answers, so
  /// the caller knows to rebuild.
  static Future<bool> refresh() async {
    if (!Get.isRegistered<OrderRepository>()) return false;
    try {
      final enabled = await Get.find<OrderRepository>().enabledPaymentTypes(
        apiLanguageCode(),
      );
      final changed =
          _enabled == null ||
          _enabled!.length != enabled.length ||
          !_enabled!.containsAll(enabled);
      _enabled = enabled;
      return changed;
    } on ApiException {
      return false;
    }
  }

  /// [current] when it's on; otherwise the first of [options] that is, or
  /// null when none are.
  static String? keepOrFirstOn(String current, List<String> options) {
    if (isOn(current)) return current;
    for (final option in options) {
      if (isOn(option)) return option;
    }
    return null;
  }
}
