import '../widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../core/network/api_exception.dart';
import '../core/push/push_notifications.dart';
import '../models/profile_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';

import '../utils/app_fonts.dart';
import '../utils/store_labels.dart';

/// The customer's notifications from the server, newest first.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load().then((_) => _markRead());
  }

  /// Opening Notifications reads them all on the server (#183), so the Home
  /// bell badge clears on every phone. The cards keep their unread dot until
  /// the list is reloaded.
  Future<void> _markRead() async {
    if (!_notifications.any((n) => n['isRead'] != true)) return;
    try {
      await Get.find<ProfileRepository>().markNotificationsRead(
        language: apiLanguageCode(),
      );
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().unreadNotifications.value = 0;
      }
    } on ApiException catch (_) {
      // Stays unread; tried again next time.
    }
  }

  /// An order or booking notification opens it (#178 `order_id`, `type`).
  void _open(Map<String, dynamic> item) {
    final orderId = item['orderId'] as int?;
    if (item['type'] == 'order' && orderId != null) {
      PushNotifications.openOrder(orderId, item['orderType'] as int? ?? 0);
    } else if (item['type'] == 'booking' &&
        Get.isRegistered<HomeController>()) {
      Get.until((route) => route.isFirst);
      Get.find<HomeController>().selectNavigation(HomeController.navBookings);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await Get.find<ProfileRepository>().fetchNotifications(
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() => _notifications = items);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Get.back()),
                  const SizedBox(width: 12),
                  Text(
                    'core_notifications_title'.tr,
                    style: AppFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5216)),
      );
    }
    if (_notifications.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFFF5216),
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(
                'core_notifications_empty'.tr,
                style: AppFonts.outfit(
                  color: const Color(0xFF7A6A60),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFFF5216),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            FadeSlideIn(child: _card(_notifications[index])),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final title = '${item['title']}';
    final content = '${item['content']}';
    // The API sends date and time apart ("2026-11-03", "06:12:32").
    final when = readableDateTime(
      [item['date'], item['time']]
          .map((v) => '$v'.trim())
          .where((v) => v.isNotEmpty && v != 'null')
          .join(' '),
    );

    final unread = item['isRead'] != true;
    final opens =
        (item['type'] == 'order' && item['orderId'] != null) ||
        item['type'] == 'booking';

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFFFF4EE) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unread ? const Color(0xFFFFC9B3) : const Color(0xFFEAD8C9),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (unread) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5216),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (opens)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFA59A94),
                ),
            ],
          ),
          if (content.isNotEmpty && content != 'null') ...[
            const SizedBox(height: 6),
            Text(
              content,
              style: AppFonts.outfit(
                color: const Color(0xFF7A6A60),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          if (when.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              when,
              style: AppFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
    if (!opens) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(item),
      child: card,
    );
  }
}
