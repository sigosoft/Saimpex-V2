import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/update/app_update.dart';
import '../utils/app_fonts.dart';

/// "We'll be right back" (Figma V2 Additions → Server Down). Shown while Admin
/// has maintenance on, or when the server answers 503. Retry checks again and
/// closes the screen once the server is back.
class ServerDownScreen extends StatefulWidget {
  final String reason;

  const ServerDownScreen({super.key, this.reason = ''});

  @override
  State<ServerDownScreen> createState() => _ServerDownScreenState();
}

class _ServerDownScreenState extends State<ServerDownScreen> {
  static const _orange = Color(0xFFFF5216);
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    final down = await AppUpdate.isServerDown();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!down) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.reason.trim().isNotEmpty
        ? widget.reason.trim()
        : 'core_down_body'.tr;
    return PopScope(
      canPop: false,
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
                    Icons.build_rounded,
                    color: _orange,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'core_down_title'.tr,
                  textAlign: TextAlign.center,
                  style: AppFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
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
                    onPressed: _checking ? null : _retry,
                    child: _checking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'core_down_retry'.tr,
                            style: AppFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
