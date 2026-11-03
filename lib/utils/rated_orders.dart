import 'package:shared_preferences/shared_preferences.dart';

/// Orders the customer has rated, kept on the phone so My Orders can hide
/// their Rate button. The order lists don't say whether an order was rated
/// (retest 3 Nov, C-B21), so this fills in until the server sends it.
class RatedOrders {
  RatedOrders._();

  static const _prefsKey = 'rated_order_ids';
  static final Set<int> _ids = {};
  static bool _loaded = false;

  static bool contains(int? orderId) =>
      orderId != null && _ids.contains(orderId);

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _ids.addAll(
      (prefs.getStringList(_prefsKey) ?? const []).map(int.tryParse).nonNulls,
    );
    _loaded = true;
  }

  static Future<void> add(int? orderId) async {
    if (orderId == null || !_ids.add(orderId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, [for (final id in _ids) '$id']);
  }
}
