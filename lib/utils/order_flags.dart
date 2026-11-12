import 'package:shared_preferences/shared_preferences.dart';

/// What the order lists don't say yet, learned once per order and kept on the
/// phone: whether an order was self-pickup (backend #166) and whether a
/// delivered order still needs rating (backend #165, with [RatedOrders]).
///
/// Both answers never change for an order, so each order is asked about once
/// (`orderDetails` / `rating`) and remembered. "Not rated yet" is kept only
/// for this app session, because the customer may rate on another phone.
class OrderFlags {
  OrderFlags._();

  static const _pickupKey = 'self_pickup_order_ids';
  static const _deliveryKey = 'delivery_order_ids';

  static final Set<int> _pickup = {};
  static final Set<int> _delivery = {};
  static final Set<int> _notRated = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    Set<int> read(String key) => (prefs.getStringList(key) ?? const [])
        .map(int.tryParse)
        .nonNulls
        .toSet();
    _pickup.addAll(read(_pickupKey));
    _delivery.addAll(read(_deliveryKey));
    _loaded = true;
  }

  /// True / false once known, null when the order hasn't been checked.
  static bool? isSelfPickup(int? orderId) {
    if (orderId == null) return null;
    if (_pickup.contains(orderId)) return true;
    if (_delivery.contains(orderId)) return false;
    return null;
  }

  static Future<void> setSelfPickup(int orderId, bool selfPickup) async {
    final set = selfPickup ? _pickup : _delivery;
    if (!set.add(orderId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(selfPickup ? _pickupKey : _deliveryKey, [
      for (final id in set) '$id',
    ]);
  }

  static bool checkedNotRated(int? orderId) =>
      orderId != null && _notRated.contains(orderId);

  static void markNotRated(int orderId) => _notRated.add(orderId);

  /// For tests.
  static void resetForTest() {
    _pickup.clear();
    _delivery.clear();
    _notRated.clear();
    _loaded = true;
  }
}
