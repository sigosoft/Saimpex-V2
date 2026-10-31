import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';

import '../../core/network/api_constants.dart';
import '../../models/order_tracking.dart';
import '../../utils/api_language.dart';
import '../../widgets/cancel_order_bottom_sheet.dart';
import 'pharmacy_track_order_screen.dart';
import 'widgets/pharmacy_background.dart';
import 'widgets/pharmacy_order_detail_loader.dart';

/// Loads the order from the API, then shows it.
class PharmacyItemOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final int? apiOrderId;
  final bool isDelivery;

  /// Shown as the store name; orders from other verticals pass their own store.
  final String? storeName;

  const PharmacyItemOrderDetailScreen({
    super.key,
    required this.orderId,
    this.apiOrderId,
    this.isDelivery = true,
    this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return PharmacyOrderDetailLoader(
      apiOrderId: apiOrderId,
      builder: (context, detail) {
        final order = detail == null ? null : OrderTracking.fromJson(detail);
        return _PharmacyItemOrderDetailBody(
          orderId: orderId,
          apiOrderId: apiOrderId,
          // The loaded order knows whether it is self pickup.
          isDelivery: order == null ? isDelivery : !order.isSelfPickup,
          storeName: storeName,
          detail: detail,
          order: order,
        );
      },
    );
  }
}

/// "22 Oct 2025 10:00 AM" (or with a comma) → "22 Oct 2025,\n10:00 AM".
String _stepTime(String raw) {
  final parts = raw.replaceAll(',', '').trim().split(RegExp(r'\s+'));
  if (parts.length < 4) return raw.trim();
  return '${parts.take(3).join(' ')},\n${parts.skip(3).join(' ')}';
}

/// The first non-empty time among [statuses] in the order's timeline.
String _firstTime(OrderTracking? order, List<int> statuses) {
  if (order == null) return '';
  for (final status in statuses) {
    final time = order.timeOf(status);
    if (time.isNotEmpty) return _stepTime(time);
  }
  return '';
}

class _PharmacyItemOrderDetailBody extends StatelessWidget {
  final String orderId;
  final int? apiOrderId;
  final bool isDelivery;
  final String? storeName;
  final Map<String, dynamic>? detail;

  /// [detail] parsed; null until the order loads.
  final OrderTracking? order;

  const _PharmacyItemOrderDetailBody({
    required this.orderId,
    this.apiOrderId,
    this.isDelivery = true,
    this.storeName,
    this.detail,
    this.order,
  });

  bool get _hasDriver => order?.hasDriver == true;
  String get _deliveryAddress => order?.deliveryAddress ?? '';

  Map<String, dynamic> get _payment => detail?['payment'] is Map
      ? Map<String, dynamic>.from(detail!['payment'] as Map)
      : <String, dynamic>{};

  List<Widget> _itemRows() {
    final items = detail?['items'] is List
        ? (detail!['items'] as List).whereType<Map>().toList()
        : const <Map>[];
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (i > 0) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFEFE8E1)),
          ),
        );
      }
      rows.add(
        _itemRow(
          imageUrl: ApiConstants.mediaUrl(item['image']?.toString()) ?? '',
          title:
              '${item['name_${apiLanguageCode()}'] ?? item['name_en'] ?? ''}',
          subtitle: 'pw_price_each'.trParams({
            'price': orderMoneyText(item['unit_price']),
          }),
          qty: 'x${item['quantity'] ?? 1}',
          price: orderMoneyText(item['total_price']),
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackButton(onTap: () => Navigator.pop(context)),
                  ),
                  Text(
                    'pw_order_id'.trParams({'id': orderId}),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'pw_help_center_opened'.tr,
                              style: GoogleFonts.outfit(),
                            ),
                            backgroundColor: const Color(0xFFFF5E00),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD4B8),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'subs_help'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'pw_order_status'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isDelivery ? 'pw_delivery'.tr : 'pw_self_pickup'.tr,
                          style: GoogleFonts.outfit(
                            color: isDelivery
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFF007DFE),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildOrderStatusCard(),
                    if (!isDelivery ||
                        _deliveryAddress.isNotEmpty ||
                        _hasDriver) ...[
                      const SizedBox(height: 18),
                      Text(
                        isDelivery
                            ? 'pw_delivery_details'.tr
                            : 'pw_pickup_location'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isDelivery) ...[
                        if (_deliveryAddress.isNotEmpty) _buildAddressCard(),
                        if (_deliveryAddress.isNotEmpty && _hasDriver)
                          const SizedBox(height: 10),
                        if (_hasDriver) _buildCourierCard(order!),
                      ] else
                        _buildPickupLocationCard(),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'pw_order_summary'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildOrderSummaryCard(),
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: isDelivery
                    ? Row(
                        children: [
                          Expanded(child: _buildCancelButton(context)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTrackButton()),
                        ],
                      )
                    : _buildCancelButton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showCancelOrderBottomSheet(
          context,
          orderId: orderId,
          apiOrderId: apiOrderId,
        );
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFEA),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          'cancel'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackButton() {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => PharmacyTrackOrderScreen(
            orderId: orderId,
            apiOrderId: apiOrderId,
          ),
        );
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'pw_track_order'.tr,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    // Status codes: 1 placed, 2–3 accepted/preparing, 4 ready, 7–8 picked up
    // / on the way, 9 delivered, 10 cancelled.
    final status = order?.status ?? 0;
    final cancelled = order?.isCancelled == true;
    final placedAt = order?.placedAt ?? '';
    final steps = [
      _StatusStep(
        label: 'pw_step_order_placed',
        time: placedAt.isEmpty ? '' : _stepTime(placedAt),
        done: status >= 1,
        icon: Icons.check_rounded,
      ),
      _StatusStep(
        label: 'pw_step_preparing',
        time: _firstTime(order, const [2, 3]),
        done: !cancelled && status >= 2,
        icon: Icons.assignment_outlined,
      ),
      isDelivery
          ? _StatusStep(
              label: 'pw_step_on_the_way',
              time: _firstTime(order, const [7, 8]),
              done: !cancelled && status >= 7,
              icon: Icons.delivery_dining_rounded,
            )
          : _StatusStep(
              label: 'pw_step_ready_for_pickup',
              time: _firstTime(order, const [4]),
              done: !cancelled && status >= 4,
              icon: Icons.local_shipping_outlined,
            ),
      cancelled
          ? _StatusStep(
              label: 'pw_cancelled',
              time: _firstTime(order, const [10]),
              done: true,
              icon: Icons.close_rounded,
            )
          : _StatusStep(
              label: 'pw_step_delivered',
              time: _firstTime(order, const [9]),
              done: status >= 9,
              icon: Icons.check_rounded,
            ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const circle = 36.0;
          final usable = constraints.maxWidth - circle;
          final segment = usable / 3;

          return Column(
            children: [
              SizedBox(
                height: circle,
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    Positioned(
                      left: circle / 2,
                      right: circle / 2,
                      child: Row(
                        children: List.generate(3, (i) {
                          final active = steps[i + 1].done;
                          return Container(
                            width: segment,
                            height: 3,
                            color: active
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFE5DDD4),
                          );
                        }),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          Container(
                            width: circle,
                            height: circle,
                            decoration: BoxDecoration(
                              color: steps[i].done
                                  ? const Color(0xFFFF5E00)
                                  : const Color(0xFFEFE8E1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: i == 2 && steps[i].done && isDelivery
                                ? Image.asset(
                                    'lib/assets/images/delivery_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                    errorBuilder: (_, _, _) => Icon(
                                      steps[i].icon,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                : Icon(
                                    steps[i].icon,
                                    color: steps[i].done
                                        ? Colors.white
                                        : const Color(0xFFB0A59C),
                                    size: 18,
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: steps.map((step) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          step.label.tr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: step.done
                                ? const Color(0xFF2C2520)
                                : const Color(0xFFA59A94),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        if (step.time.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            step.time,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Color(0xFFFF5E00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'pw_delivery_address'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _deliveryAddress,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupLocationCard() {
    final vendorName = order?.vendorName ?? '';
    final name = vendorName.isNotEmpty
        ? vendorName
        : (storeName == null || storeName!.isEmpty)
        ? 'pw_store'.tr
        : storeName!;
    final address = order?.vendorAddress ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Color(0xFFFF5E00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF5E00),
            size: 22,
          ),
        ],
      ),
    );
  }

  /// Only built when the order has a driver.
  Widget _buildCourierCard(OrderTracking order) {
    final placeholder = Container(
      width: 46,
      height: 46,
      color: const Color(0xFFF3EFEA),
      child: const Icon(Icons.person, color: Color(0xFFFF5E00)),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: order.driverImage.isEmpty
                ? placeholder
                : Image.network(
                    order.driverImage,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName.isEmpty ? 'pw_driver'.tr : order.driverName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (order.driverRating > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFAE00),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        order.driverRating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (order.driverReviews > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          'pw_reviews_count'.trParams({
                            'count': '${order.driverReviews}',
                          }),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [..._itemRows(), const SizedBox(height: 8)]),
    );
  }

  Widget _itemRow({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String qty,
    required String price,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 54,
            height: 54,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 54,
              height: 54,
              color: const Color(0xFFF3EFEA),
              child: const Icon(
                Icons.medication_outlined,
                color: Color(0xFFFF5E00),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                qty,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pw_payment_details_caps'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _payRow('pw_item_total'.tr, orderMoneyText(_payment['item_total'])),
          const SizedBox(height: 10),
          _payRow(
            'cart_redeemed_points'.tr,
            orderMoneyText(_payment['redeemed_points'], negative: true),
            valueColor: const Color(0xFFFF5E00),
          ),
          if (isDelivery) ...[
            const SizedBox(height: 10),
            _payRow(
              'cart_delivery_fee'.tr,
              orderMoneyText(_payment['delivery_fee']),
            ),
          ],
          const SizedBox(height: 10),
          _payRow('cart_tax'.tr, orderMoneyText(_payment['tax'])),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A434E)),
          ),
          Row(
            children: [
              Text(
                isDelivery ? 'pw_total_paid'.tr : 'pw_to_pay'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                orderMoneyText(_payment['total_bill']),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusStep {
  final String label;
  final String time;
  final bool done;
  final IconData icon;

  const _StatusStep({
    required this.label,
    required this.time,
    required this.done,
    required this.icon,
  });
}
