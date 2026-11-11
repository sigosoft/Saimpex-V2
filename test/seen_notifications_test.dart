import 'package:flutter_test/flutter_test.dart';
import 'package:saimpex_v2/utils/seen_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('badge shows notifications not opened yet, never below 0', () {
    expect(SeenNotifications.unread(5, 0), 5);
    expect(SeenNotifications.unread(5, 3), 2);
    expect(SeenNotifications.unread(5, 5), 0);
    expect(SeenNotifications.unread(3, 5), 0);
  });

  test('seen count is kept per account', () async {
    SharedPreferences.setMockInitialValues({});
    await SeenNotifications.save('7', 4);
    expect(await SeenNotifications.load('7'), 4);
    expect(await SeenNotifications.load('8'), 0);
    expect(await SeenNotifications.load(''), 0);
  });
}
