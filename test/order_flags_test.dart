import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/utils/order_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OrderFlags.resetForTest();
  });

  test('self-pickup is unknown until checked, then remembered', () async {
    expect(OrderFlags.isSelfPickup(10), isNull);
    expect(OrderFlags.isSelfPickup(null), isNull);

    await OrderFlags.setSelfPickup(10, true);
    await OrderFlags.setSelfPickup(11, false);
    expect(OrderFlags.isSelfPickup(10), isTrue);
    expect(OrderFlags.isSelfPickup(11), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('self_pickup_order_ids'), ['10']);
    expect(prefs.getStringList('delivery_order_ids'), ['11']);
  });

  test('"not rated yet" is kept for the session only', () async {
    expect(OrderFlags.checkedNotRated(5), isFalse);
    OrderFlags.markNotRated(5);
    expect(OrderFlags.checkedNotRated(5), isTrue);
    expect(OrderFlags.checkedNotRated(null), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}
