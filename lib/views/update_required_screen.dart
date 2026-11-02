import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_fonts.dart';

/// "Update SAIMPEX" (Figma V2 Additions → Update Required). With [force] the
/// screen can't be left; otherwise "Later" closes it.
class UpdateRequiredScreen extends StatelessWidget {
  final bool force;
  final String storeLink;

  const UpdateRequiredScreen({
    super.key,
    required this.force,
    this.storeLink = '',
  });

  static const _orange = Color(0xFFFF5216);

  Future<void> _openStore() async {
    final uri = Uri.tryParse(storeLink);
    if (uri == null || storeLink.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !force,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F1),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEFE3),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: _orange,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'core_update_title'.tr,
                  textAlign: TextAlign.center,
                  style: AppFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (force ? 'core_update_body' : 'core_update_body_optional').tr,
                  textAlign: TextAlign.center,
                  style: AppFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: storeLink.isEmpty ? null : _openStore,
                    child: Text(
                      'core_update_now'.tr,
                      style: AppFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (!force) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'core_update_later'.tr,
                        style: AppFonts.outfit(
                          color: _orange,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
