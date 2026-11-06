import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/general_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../views/support_messages_screen.dart';

/// "Need help?" with WhatsApp and call buttons. The numbers come from Admin →
/// Branding, so the client can change them any time (V2_DECISIONS §17).
class HelpSheet {
  HelpSheet._();

  static ({String whatsapp, String phone, String email})? _cached;

  /// With [orderId], the sheet also offers a message to SAIMPEX support
  /// about that order, so Help works when Admin has set no numbers (CA-19).
  static Future<void> show({String? orderCode, int? orderId}) async {
    var contacts = _cached;
    if (contacts == null && Get.isRegistered<GeneralRepository>()) {
      try {
        contacts = await Get.find<GeneralRepository>().fetchSupportContacts(
          apiLanguageCode(),
        );
        _cached = contacts;
      } catch (_) {}
    }
    contacts ??= (whatsapp: '', phone: '', email: '');
    final hasOrder = orderId != null && orderId > 0;
    if (!hasOrder && contacts.whatsapp.isEmpty && contacts.phone.isEmpty) {
      showAppToast('ease_help_unavailable'.tr);
      return;
    }
    await Get.bottomSheet(
      _HelpSheetBody(
        contacts: contacts,
        orderCode: orderCode,
        orderId: hasOrder ? orderId : null,
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  static String _digits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');
}

class _HelpSheetBody extends StatelessWidget {
  const _HelpSheetBody({required this.contacts, this.orderCode, this.orderId});

  final ({String whatsapp, String phone, String email}) contacts;
  final String? orderCode;
  final int? orderId;

  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) showAppToast('ease_help_unavailable'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final text = orderCode == null ? '' : 'Order #$orderCode';
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
            const SizedBox(height: 20),
            const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFFFF5216),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'ease_help_title'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'ease_help_body'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            if (contacts.whatsapp.isNotEmpty)
              _HelpButton(
                icon: Icons.chat_rounded,
                label: 'ease_help_whatsapp'.tr,
                color: const Color(0xFF25D366),
                onTap: () => _open(
                  Uri.https(
                    'wa.me',
                    '/${HelpSheet._digits(contacts.whatsapp)}',
                    {if (text.isNotEmpty) 'text': text},
                  ),
                ),
              ),
            if (contacts.whatsapp.isNotEmpty && contacts.phone.isNotEmpty)
              const SizedBox(height: 10),
            if (contacts.phone.isNotEmpty)
              _HelpButton(
                icon: Icons.call_rounded,
                label: 'ease_help_call'.tr,
                color: const Color(0xFFFF5216),
                onTap: () => _open(
                  Uri(
                    scheme: 'tel',
                    path: '+${HelpSheet._digits(contacts.phone)}',
                  ),
                ),
              ),
            if (orderId != null) ...[
              if (contacts.whatsapp.isNotEmpty || contacts.phone.isNotEmpty)
                const SizedBox(height: 10),
              _HelpButton(
                icon: Icons.forum_rounded,
                label: 'ease_help_message'.tr,
                color: const Color(0xFF2C2520),
                onTap: () {
                  Get.back();
                  Get.to(
                    () => SupportThreadScreen(
                      orderId: orderId!,
                      orderCode: orderCode ?? '',
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
