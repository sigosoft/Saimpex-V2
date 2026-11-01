import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_fonts.dart';
/// A pre-order's `scheduled_for` as "Sat 02/11, 13:30" in the device's time
/// zone, with the weekday in the app's language.
String formatScheduledFor(String value) {
  final time = DateTime.tryParse(value);
  if (time == null) return value;
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final day = 'svc_weekday_${local.weekday}'.tr;
  return '$day ${two(local.day)}/${two(local.month)}, '
      '${two(local.hour)}:${two(local.minute)}';
}

/// "Scheduled for …" on an order's detail screen when it is a pre-order
/// (`is_preorder` / `scheduled_for` from orderDetails, trackOrder and
/// catalog/orderDetail); nothing for a normal order.
class ScheduledForBanner extends StatelessWidget {
  const ScheduledForBanner({super.key, required this.detail});

  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final value = '${detail['scheduled_for'] ?? ''}'.trim();
    final flag = '${detail['is_preorder'] ?? ''}';
    final isPreorder = flag == '1' || flag == 'true';
    if (value.isEmpty || value == 'null' || (flag.isNotEmpty && !isPreorder)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD9C2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: Color(0xFFFF5216),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'orders_scheduled_for'.trParams({
                'time': formatScheduledFor(value),
              }),
              style: AppFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
