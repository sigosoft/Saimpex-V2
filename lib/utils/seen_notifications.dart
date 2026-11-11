import 'package:shared_preferences/shared_preferences.dart';

/// How many notifications the customer had when they last opened
/// Notifications, kept on the phone per account.
///
/// `homeHub.unread_notifications` is really the total number of the
/// customer's notifications: the server has no read flag for them. The Home
/// bell shows total − seen, so it clears once Notifications is opened.
class SeenNotifications {
  SeenNotifications._();

  static String _key(String userId) => 'notifications_seen_$userId';

  static Future<int> load(String userId) async {
    if (userId.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId)) ?? 0;
  }

  static Future<void> save(String userId, int count) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(userId), count);
  }

  /// Notifications not opened yet: [total] minus [seen], never below 0.
  static int unread(int total, int seen) => total > seen ? total - seen : 0;
}
