import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/order_tracking.dart';
import '../utils/app_fonts.dart';

/// "Reason: …" under the status of a cancelled order. Nothing when the
/// reason is empty.
class CancelReasonNote extends StatelessWidget {
  const CancelReasonNote({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    if (reason.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFFE03A3A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'core_cancel_reason'.trParams({'reason': reason}),
              style: AppFonts.outfit(
                color: const Color(0xFFB42318),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// For screens whose order data has no timeline (food orders come from
/// catalog/orderDetail): loads customer/orderDetails once for the reason.
class CancelReasonLoader extends StatefulWidget {
  const CancelReasonLoader({super.key, required this.orderId});

  final int? orderId;

  @override
  State<CancelReasonLoader> createState() => _CancelReasonLoaderState();
}

class _CancelReasonLoaderState extends State<CancelReasonLoader> {
  String _reason = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await loadOrderDetail(widget.orderId);
      if (!mounted || detail == null) return;
      setState(() => _reason = detail.cancelReason);
    } catch (_) {
      // The reason is extra information; the order still shows Cancelled.
    }
  }

  @override
  Widget build(BuildContext context) => CancelReasonNote(reason: _reason);
}
