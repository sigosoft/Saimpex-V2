import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../models/auth_repository.dart';
import '../../views/notifications_screen.dart';
import '../../views/pharmacy/my_prescriptions_screen.dart';
import '../../views/support_messages_screen.dart';
import '../storage/session_store.dart';

/// Firebase push for the customer app (C17).
///
/// The token goes to `customer/updateFcmToken` (API §6.45) after login and on
/// every refresh, and is cleared before logout. Pushes arriving while the app
/// is open are shown on the `customer` channel the server targets. Tapping a
/// push opens the support thread for `admin_message` (with `order_id`) and the
/// notifications list for everything else: order status pushes carry no data
/// yet.
///
/// Firebase reads its settings from `android/app/google-services.json`
/// (project `saimpex-customer`, app `app.saimpex`). Without them, for example
/// on iOS until `GoogleService-Info.plist` is added in Xcode, push is off and
/// the rest of the app is unaffected.
class PushNotifications {
  PushNotifications._();

  static const _channel = AndroidNotificationChannel(
    'customer',
    'SAIMPEX',
    description: 'Orders, bookings and messages',
    importance: Importance.high,
  );

  static final _local = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String? _sentToken;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('Push disabled: Firebase is not configured ($error)');
      return;
    }
    _ready = true;
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _openPayload(response.payload),
    );
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    // iOS shows pushes itself while the app is open; Android needs _show.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_show);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
    // The server sends to FCM registration tokens (message.token), not to the
    // installation IDs that the newer register()/onRegistered API returns.
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen(_sendToken);

    final session = Get.find<SessionStore>();
    ever<bool>(session.isLoggedIn, (loggedIn) {
      if (loggedIn) unawaited(syncToken());
    });
    if (session.isLoggedIn.value) unawaited(syncToken());

    // The app was opened by tapping a push while it was closed.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      // Let the first screen settle before navigating.
      Future.delayed(const Duration(seconds: 1), () => _open(initial.data));
    }
  }

  /// Sends the current token to the server for the signed-in customer.
  static Future<void> syncToken() async {
    if (!_ready) return;
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);
    } catch (error) {
      debugPrint('Push token not available: $error');
    }
  }

  /// Unlinks this device from the account; call before logging out.
  static Future<void> clearToken() async {
    if (!_ready || _sentToken == null) return;
    try {
      await Get.find<AuthRepository>().updateFcmToken('');
    } catch (_) {
      // Logging out continues; the server moves the token on next login.
    }
    _sentToken = null;
  }

  static Future<void> _sendToken(String token) async {
    final session = Get.find<SessionStore>();
    if (!session.isLoggedIn.value || token == _sentToken) return;
    try {
      await Get.find<AuthRepository>().updateFcmToken(token);
      _sentToken = token;
    } catch (error) {
      debugPrint('Push token not saved: $error');
    }
  }

  static Future<void> _show(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || GetPlatform.isIOS) return;
    await _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map) _open(Map<String, dynamic>.from(data));
    } catch (_) {
      _open(const {});
    }
  }

  static void _open(Map<String, dynamic> data) {
    if (!Get.find<SessionStore>().isLoggedIn.value) return;
    final orderId = int.tryParse('${data['order_id'] ?? ''}');
    if (data['type'] == 'admin_message' && orderId != null) {
      Get.to(() => SupportThreadScreen(orderId: orderId));
      return;
    }
    // Chat and pharmacy quote pushes carry their type (backend 41739a8).
    if (data['type'] == 'chat' && Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().selectNavigation(HomeController.navChat);
      return;
    }
    if (data['type'] == 'prescription') {
      Get.to(() => const MyPrescriptionsScreen());
      return;
    }
    Get.to(() => const NotificationsScreen());
  }
}

/// Pushes received while the app is in the background or closed are shown by
/// the system from their `notification` part; nothing else to do here.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}
