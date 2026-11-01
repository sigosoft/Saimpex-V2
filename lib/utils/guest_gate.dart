import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/storage/session_store.dart';
import '../views/login_screen.dart';

/// Guests can browse everything; login is asked only when an action needs an
/// account (V2_DECISIONS §17). One sheet at a time.
class GuestGate {
  GuestGate._();

  static bool _open = false;

  static bool get isGuest =>
      !Get.isRegistered<SessionStore>() ||
      !Get.find<SessionStore>().isLoggedIn.value;

  /// True when signed in; otherwise shows the login sheet and returns false.
  static bool ensureLoggedIn() {
    if (!isGuest) return true;
    prompt();
    return false;
  }

  static Future<void> prompt() async {
    if (_open) return;
    _open = true;
    try {
      await Get.bottomSheet(
        const _LoginSheet(),
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      );
    } finally {
      _open = false;
    }
  }
}

class _LoginSheet extends StatelessWidget {
  const _LoginSheet();

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF5216);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_iphone_rounded, color: orange, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'ease_login_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'ease_login_body'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Get.back();
                  Get.to(() => const LoginScreen(), transition: Transition.downToUp);
                },
                child: Text('ease_login_button'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: Get.back,
                child: Text('ease_login_later'.tr, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
