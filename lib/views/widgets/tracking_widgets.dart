import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/order_tracking.dart';
import '../../utils/toast_helper.dart';

/// The info panel under the tracking map: status, order tag, the four-step
/// progress and the driver card, all from customer/trackOrder.
class TrackingSummary extends StatelessWidget {
  const TrackingSummary({
    super.key,
    required this.tracking,
    this.error,
    this.fallbackOrderCode = '',
    this.preparingLabel = 'core_tracking_preparing',
  });

  final OrderTracking? tracking;
  final String? error;
  final String fallbackOrderCode;

  /// Second step's label, e.g. "Picking Items" for groceries. Translated
  /// when shown, so a translation key works here too.
  final String preparingLabel;

  @override
  Widget build(BuildContext context) {
    final data = tracking;
    if (data == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: error != null
              ? Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : const CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    }

    final code = data.orderCode.isNotEmpty ? data.orderCode : fallbackOrderCode;
    final tag = [
      if (code.isNotEmpty)
        'core_tracking_order'.trParams({
          'code': code.startsWith('#') ? code : '#$code',
        }),
      if (data.vendorName.isNotEmpty) data.vendorName,
    ].join(' • ');
    final badgeColor = data.isCancelled
        ? const Color(0xFFE03A3A)
        : data.isDelivered
        ? const Color(0xFF00B25C)
        : const Color(0xFFFF5E00);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            data.statusText.toUpperCase(),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.statusText,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (tag.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            tag,
            style: GoogleFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (!data.isCancelled) _progress(data),
        const SizedBox(height: 20),
        Text(
          'core_tracking_your_driver'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _driverCard(context, data),
      ],
    );
  }

  Widget _progress(OrderTracking data) {
    final stage = data.stage;
    Widget line(bool done) => Expanded(
      child: Container(
        height: 2,
        color: done ? const Color(0xFFFF5E00) : const Color(0xFFEAD8C9),
      ),
    );
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 18,
          left: 30,
          right: 30,
          child: Row(
            children: [line(stage >= 1), line(stage >= 2), line(stage >= 3)],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _node(
              stage >= 0,
              Icons.check,
              'core_tracking_placed'.tr,
              data.placedAt,
            ),
            _node(
              stage >= 1,
              Icons.shopping_bag_outlined,
              preparingLabel.tr,
              data.timeOf(3).isNotEmpty ? data.timeOf(3) : data.timeOf(2),
            ),
            _node(
              stage >= 2,
              Icons.delivery_dining_rounded,
              'core_tracking_on_the_way'.tr,
              data.timeOf(7),
            ),
            _node(
              stage >= 3,
              Icons.check,
              'core_tracking_delivered'.tr,
              data.timeOf(9),
            ),
          ],
        ),
      ],
    );
  }

  Widget _node(bool active, IconData icon, String title, String time) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF5E00) : const Color(0xFFEAD8C9),
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: active ? const Color(0xFF2C2520) : const Color(0xFFA59A94),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 6.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _driverCard(BuildContext context, OrderTracking data) {
    final placeholder = Container(
      width: 64,
      height: 64,
      color: const Color(0xFFEAD8C9),
      child: const Icon(Icons.person, color: Colors.white, size: 32),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: !data.hasDriver
          ? Text(
              data.isFinished
                  ? 'core_tracking_no_driver'.tr
                  : 'core_tracking_driver_soon'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF7A6A60),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          : Row(
              children: [
                ClipOval(
                  child: data.driverImage.isEmpty
                      ? placeholder
                      : Image.network(
                          data.driverImage,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => placeholder,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.driverName.isEmpty
                            ? 'core_tracking_driver'.tr
                            : data.driverName,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFAE00),
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            data.driverRating > 0
                                ? data.driverRating.toStringAsFixed(1)
                                : 'core_tracking_new'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (data.driverReviews > 0)
                            Text(
                              ' ${'core_tracking_reviews'.trParams({'count': '${data.driverReviews}'})}',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  // The scope calls for a masked number, which needs a
                  // calling provider the backend doesn't have yet.
                  onTap: () => showAppToast('core_tracking_call_soon'.tr),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5E00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
