import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_constants.dart';
import '../../../utils/toast_helper.dart';

/// "View Full Prescription": the uploaded photo full screen (pinch to zoom),
/// or a PDF in the phone's viewer. The link did nothing on the order cards
/// and the quotation screen.
Future<void> openPrescription(BuildContext context, String? rawUrl) async {
  final url = ApiConstants.mediaUrl(rawUrl?.trim()) ?? rawUrl?.trim() ?? '';
  if (!url.startsWith('http')) {
    showAppToast('pw_prescription_unavailable'.tr);
    return;
  }
  if (url.toLowerCase().split('?').first.endsWith('.pdf')) {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) showAppToast('pw_prescription_unavailable'.tr);
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5216),
                          ),
                        ),
                      ),
                errorBuilder: (_, _, _) => Container(
                  height: 240,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFA59A94),
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 8,
            end: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
