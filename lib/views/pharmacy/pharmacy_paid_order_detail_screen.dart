import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';

import '../../models/order_tracking.dart';
import '../../utils/api_language.dart';
import '../../widgets/cancel_order_bottom_sheet.dart';
import 'pharmacy_track_order_screen.dart';
import 'widgets/pharmacy_background.dart';
import 'widgets/pharmacy_order_detail_loader.dart';

/// Loads the order from the API, then shows it.
class PharmacyPaidOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final int? apiOrderId;
  final bool isDelivery;

  /// Shown until the order loads; the order's own pharmacy wins after that.
  final String? pharmacyName;
  final String? prescriptionImageUrl;

  const PharmacyPaidOrderDetailScreen({
    super.key,
    required this.orderId,
    this.apiOrderId,
    this.isDelivery = true,
    this.pharmacyName,
    this.prescriptionImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PharmacyOrderDetailLoader(
      apiOrderId: apiOrderId,
      builder: (context, detail) {
        final order = detail == null ? null : OrderTracking.fromJson(detail);
        return _PharmacyPaidOrderDetailBody(
          orderId: orderId,
          apiOrderId: apiOrderId,
          // The loaded order knows whether it is self pickup.
          isDelivery: order == null ? isDelivery : !order.isSelfPickup,
          pharmacyName: pharmacyName,
          prescriptionImageUrl: prescriptionImageUrl,
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

class _PharmacyPaidOrderDetailBody extends StatelessWidget {
  final String orderId;
  final int? apiOrderId;
  final bool isDelivery;
  final String? pharmacyName;
  final String? prescriptionImageUrl;
  final Map<String, dynamic>? detail;

  /// [detail] parsed; null until the order loads.
  final OrderTracking? order;

  const _PharmacyPaidOrderDetailBody({
    required this.orderId,
    this.apiOrderId,
    this.isDelivery = true,
    this.pharmacyName,
    this.prescriptionImageUrl,
    this.detail,
    this.order,
  });

  Map<String, dynamic> get _payment => detail?['payment'] is Map
      ? Map<String, dynamic>.from(detail!['payment'] as Map)
      : <String, dynamic>{};

  bool get _hasDriver => order?.hasDriver == true;
  String get _deliveryAddress => order?.deliveryAddress ?? '';

  List<Widget> _medicineCards() {
    final items = order?.items ?? const <Map<String, dynamic>>[];
    final cards = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final name = item['name_${apiLanguageCode()}'] ?? item['name_en'] ?? '';
      final total = double.tryParse('${item['total_price'] ?? ''}');
      if (i > 0) cards.add(const SizedBox(height: 10));
      cards.add(
        _buildMedicineCard(
          title: '${i + 1}. $name',
          unit:
              '${item['quantity'] ?? 1} × ${orderMoneyText(item['unit_price'])}',
          totalAmount: total == null ? '—' : '${total.round()}',
        ),
      );
    }
    return cards;
  }

  Widget _prescriptionFallback() {
    return Container(
      color: const Color(0xFFF3EFEA),
      alignment: Alignment.center,
      child: const Icon(
        Icons.description_outlined,
        color: Color(0xFFFF5E00),
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = prescriptionImageUrl ?? '';
    final medicines = _medicineCards();
    final displayId = orderId.startsWith('#') ? orderId : '#$orderId';

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppBackButton(onTap: () => Navigator.pop(context)),
                    ),
                    Text(
                      'pw_order_id'.trParams({'id': displayId}),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty) ...[
                      _buildPrescriptionCard(imageUrl),
                      const SizedBox(height: 14),
                    ],
                    _buildOrderStatusCard(),
                    if (medicines.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'pw_medicines_in_quotation'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...medicines,
                    ],
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
                      const SizedBox(height: 12),
                      if (isDelivery) ...[
                        if (_deliveryAddress.isNotEmpty) _buildAddressCard(),
                        if (_deliveryAddress.isNotEmpty && _hasDriver)
                          const SizedBox(height: 10),
                        if (_hasDriver) _buildCourierCard(order!),
                      ] else
                        _buildPickupLocationCard(),
                    ],
                    const SizedBox(height: 16),
                    _buildQuotationSummaryCard(),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: PharmacyBackground.bottom,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFEA),
          borderRadius: BorderRadius.circular(25),
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
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
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

  Widget _buildPrescriptionCard(String imageUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pw_prescription'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: imageUrl.isEmpty
                  ? _prescriptionFallback()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _prescriptionFallback(),
                    ),
            ),
          ),
        ],
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
        label: 'pw_step_payment_successful',
        time: placedAt.isEmpty ? '' : _stepTime(placedAt),
        done: status >= 1,
        icon: Icons.check_rounded,
      ),
      _StatusStep(
        label: 'pw_step_preparing_medicines',
        time: _firstTime(order, const [2, 3]),
        done: !cancelled && status >= 2,
        icon: Icons.medication_liquid_rounded,
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
              icon: Icons.shopping_bag_outlined,
              // Waiting at the pharmacy for the customer.
              highlight: !cancelled && status >= 4 && status < 9,
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
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'pw_order_status'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
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
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const circle = 36.0;
              final usable = constraints.maxWidth - circle;
              final segment = usable / 3;

              return Column(
                children: [
                  SizedBox(
                    height: circle + 8,
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
                                  boxShadow: steps[i].highlight
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFF5E00,
                                            ).withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
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
        ],
      ),
    );
  }

  Widget _buildMedicineCard({
    required String title,
    required String unit,
    required String totalAmount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A2338),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'pw_unit_value'.trParams({'unit': unit}),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'pw_total_colon'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                totalAmount,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' ${'pw_mru_suffix'.tr}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
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
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EA),
              shape: BoxShape.circle,
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
        : (pharmacyName == null || pharmacyName!.isEmpty)
        ? 'pw_pharmacy'.tr
        : pharmacyName!;
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
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EA),
              shape: BoxShape.circle,
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

  Widget _buildQuotationSummaryCard() {
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
            'pw_quotation_summary_caps'.tr,
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
            'cart_delivery_fee'.tr,
            orderMoneyText(_payment['delivery_fee']),
          ),
          const SizedBox(height: 10),
          _payRow('cart_tax'.tr, orderMoneyText(_payment['tax'])),
          const SizedBox(height: 10),
          _payRow(
            'cart_redeemed_points'.tr,
            orderMoneyText(_payment['redeemed_points'], negative: true),
            valueColor: const Color(0xFFFF5E00),
            labelColor: const Color(0xFFFF5E00),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A434E)),
          ),
          Row(
            children: [
              Text(
                'pw_total_paid'.tr,
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

  Widget _payRow(
    String label,
    String value, {
    Color? valueColor,
    Color? labelColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: labelColor ?? Colors.white,
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
  final bool highlight;

  const _StatusStep({
    required this.label,
    required this.time,
    required this.done,
    required this.icon,
    this.highlight = false,
  });
}
