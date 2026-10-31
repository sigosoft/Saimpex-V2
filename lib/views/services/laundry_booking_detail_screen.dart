import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_exception.dart';
import '../../models/service_booking_detail.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/cancel_booking_bottom_sheet.dart';

class LaundryBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const LaundryBookingDetailScreen({super.key, required this.booking});

  @override
  State<LaundryBookingDetailScreen> createState() =>
      _LaundryBookingDetailScreenState();
}

class _LaundryBookingDetailScreenState
    extends State<LaundryBookingDetailScreen> {
  ServiceBookingDetail? _detail;

  Map<String, dynamic> get booking => widget.booking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await loadServiceBooking(booking['apiOrderId'] as int?);
      if (!mounted || detail == null) return;
      setState(() => _detail = detail);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  String _bookingText(String key) => '${booking[key] ?? ''}'.trim();

  String _raw(String key) => '${_detail?[key] ?? ''}'.trim();

  double? _number(String key) => double.tryParse(_raw(key));

  String _trimNumber(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  String get _bookingId {
    final code = _detail?.orderCode ?? '';
    return code.isNotEmpty ? code : _bookingText('id');
  }

  String get _service {
    final name = _detail?.serviceName ?? '';
    return name.isNotEmpty ? name : _bookingText('service');
  }

  String get _estimate {
    final quantity = _number('estimate_quantity') ?? 0;
    if (quantity <= 0) return '';
    final count = _trimNumber(quantity);
    switch (_raw('unit')) {
      case 'kg':
        return 'svc_estimated_kg'.trParams({'kg': count});
      case 'piece':
      case 'item':
        return (quantity == 1 ? 'svc_estimated_item' : 'svc_estimated_items')
            .trParams({'count': count});
    }
    return '';
  }

  String get _price {
    final detail = _detail;
    return detail != null ? serviceMru(detail.total) : _bookingText('price');
  }

  String get _status {
    final label = _detail?.statusLabel ?? '';
    return label.isNotEmpty ? label : _bookingText('status');
  }

  String get _image => _raw('service_image');

  String get _addressLabel => _detail?.addressLabel ?? '';

  String get _pickupAddress {
    for (final value in [
      _raw('pickup_address'),
      _detail?.address ?? '',
      _detail?.location ?? '',
      _bookingText('location'),
    ]) {
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String get _deliveryAddress {
    final address = _raw('delivery_address');
    return address.isNotEmpty ? address : _pickupAddress;
  }

  String get _slot {
    for (final value in [
      _raw('pickup_slot'),
      _detail?.slot ?? '',
      _bookingText('slot'),
      _bookingText('datetime'),
    ]) {
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String get _deliverySpeed {
    final turnaround = _raw('turnaround');
    if (turnaround == 'Standard (24h)') {
      return 'svc_standard_delivery_ready_in'.trParams({
        'duration': 'svc_24_hours'.tr,
      });
    }
    if (turnaround == 'Express') return 'svc_express'.tr;
    return _raw('processing_label');
  }

  String get _estimatedDelivery => _raw('delivery_turnaround');

  double get _balanceDue {
    if (_detail?.isCancelled ?? true) return 0;
    return _number('additional_payment') ?? 0;
  }

  bool get _canCancel => _detail?.canCancel ?? booking['canCancel'] == true;

  List<Map<String, dynamic>> get _statusSteps {
    const steps = [
      (1, 'svc_step_booking_confirmed', Icons.check_rounded),
      (3, 'svc_step_laundry_collected', Icons.local_laundry_service_rounded),
      (4, 'svc_step_cleaning_folding', Icons.iron_rounded),
      (9, 'svc_step_delivered', Icons.check_rounded),
    ];
    final detail = _detail;
    final cancelled = detail?.isCancelled ?? false;
    return [
      for (var i = 0; i < steps.length; i++)
        if (cancelled && i == steps.length - 1)
          {
            'label': 'svc_step_cancelled',
            'time': detail!.timeOf(10),
            'icon': Icons.close_rounded,
            'done': true,
          }
        else
          {
            'label': steps[i].$2,
            'time': detail?.timeOf(steps[i].$1) ?? '',
            'icon': steps[i].$3,
            'done': detail?.reached(steps[i].$1) ?? i == 0,
          },
    ];
  }

  List<Map<String, String>> _rows(String kind) => [
    for (final line in _detail?.lines(kind) ?? const <ServiceBookingLine>[])
      {
        'label': line.name,
        'detail': '${serviceMru(line.price)} x ${_trimNumber(line.quantity)}',
        'total': serviceMru(line.total),
      },
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final garments = _rows('garment');
    final addons = _rows('addon');
    final hasPickupDelivery =
        _pickupAddress.isNotEmpty ||
        _slot.isNotEmpty ||
        _deliverySpeed.isNotEmpty ||
        _estimatedDelivery.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24 + bottomInset + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('svc_booking_status'.tr),
                      const SizedBox(height: 10),
                      _buildStatusCard(),
                      if (_balanceDue > 0) ...[
                        const SizedBox(height: 16),
                        _sectionTitle('svc_balance_due_breakdown'.tr),
                        const SizedBox(height: 10),
                        _buildBalanceDueCard(),
                      ],
                      const SizedBox(height: 16),
                      _buildServiceCard(),
                      if (garments.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildLineItemsCard(garments),
                      ],
                      if (addons.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _sectionTitle('svc_addon_services'.tr),
                        const SizedBox(height: 10),
                        _buildLineItemsCard(addons),
                      ],
                      if (hasPickupDelivery) ...[
                        const SizedBox(height: 20),
                        _sectionTitle('svc_pickup_delivery'.tr),
                      ],
                      if (_pickupAddress.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildPickupDeliveryCard(),
                      ],
                      if (_slot.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildPickupSlotCard(),
                      ],
                      if (_deliverySpeed.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.local_shipping_outlined,
                          iconBg: const Color(0xFFFFF0E6),
                          iconColor: const Color(0xFFFF5E00),
                          label: 'svc_delivery_speed'.tr,
                          value: _deliverySpeed,
                        ),
                      ],
                      if (_estimatedDelivery.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.calendar_month_rounded,
                          iconBg: const Color(0xFFEAF2F8),
                          iconColor: const Color(0xFF1A6BB5),
                          label: 'svc_estimated_delivery'.tr,
                          value: _estimatedDelivery,
                        ),
                      ],
                      if (_detail != null) ...[
                        const SizedBox(height: 20),
                        _buildPaymentDetails(_detail!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _canCancel || _balanceDue > 0
            ? _buildCancelBar(bottomInset)
            : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFF5E00),
                size: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'svc_booking_number'.trParams({'id': _bookingId}),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DFD6)),
              ),
              child: Text(
                'svc_help'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF1B2B4A),
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatusCard() {
    const circleSize = 36.0;
    const lineTop = circleSize / 2;
    final steps = _statusSteps;
    final lastDone = steps.lastIndexWhere((step) => step['done'] == true);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = steps.length;
          final stepWidth = constraints.maxWidth / count;
          final lineLeft = stepWidth / 2;
          final lineWidth = constraints.maxWidth - stepWidth;
          final progress = count > 1 && lastDone > 0
              ? lastDone / (count - 1)
              : 0.0;

          return SizedBox(
            height: 118,
            child: Stack(
              children: [
                Positioned(
                  top: lineTop - 1.5,
                  left: lineLeft,
                  width: lineWidth,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DFD6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  top: lineTop - 1.5,
                  left: lineLeft,
                  width: lineWidth * progress,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step in steps)
                      Expanded(child: _statusStep(step, circleSize)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusStep(Map<String, dynamic> step, double circleSize) {
    final done = step['done'] as bool;
    final time = step['time'] as String;

    return Column(
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: done ? const Color(0xFFFF5E00) : const Color(0xFFF0EAE4),
            shape: BoxShape.circle,
            boxShadow: done
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
          child: Icon(
            step['icon'] as IconData,
            color: done ? Colors.white : const Color(0xFFB0A8A0),
            size: 18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          (step['label'] as String).tr,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1B2B4A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF9A8E86),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFFFF3EB),
      child: const Icon(
        Icons.local_laundry_service_rounded,
        color: Color(0xFFFF5E00),
      ),
    );
  }

  Widget _buildServiceCard() {
    final cancelled = _detail?.isCancelled ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _image.isEmpty
                ? _imagePlaceholder()
                : Image.network(
                    _image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_service.isNotEmpty)
                  Text(
                    _service,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1B2B4A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (_estimate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _estimate,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF9A8E86),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (_price.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _price,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cancelled
                    ? const Color(0xFFFDECEC)
                    : const Color(0xFFE6F6EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _status.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: cancelled
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF1B7A3E),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLineItemsCard(List<Map<String, String>> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[i]['label']!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1B2B4A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rows[i]['detail']!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF9A8E86),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  rows[i]['total']!,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickupDeliveryCard() {
    const iconSize = 22.0;
    final label = _addressLabel;
    final pickup = _pickupAddress;
    final delivery = _deliveryAddress;
    final pickupTitle = label.isNotEmpty ? label : pickup;
    final pickupSubtitle = label.isNotEmpty ? pickup : '';
    final sameAddress = delivery == pickup;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: iconSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: iconSize,
                    bottom: iconSize,
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFD0C8C0),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.radio_button_checked,
                      color: Color(0xFFFF5E00),
                      size: iconSize,
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF00B25C),
                      size: iconSize,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  _addressContent(
                    label: 'svc_pickup_upper'.tr,
                    labelColor: const Color(0xFFFF5E00),
                    title: pickupTitle,
                    subtitle: pickupSubtitle,
                  ),
                  const SizedBox(height: 18),
                  _addressContent(
                    label: 'svc_delivery_upper'.tr,
                    labelColor: const Color(0xFF00B25C),
                    title: sameAddress ? pickupTitle : delivery,
                    subtitle: sameAddress ? pickupSubtitle : '',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressContent({
    required String label,
    required Color labelColor,
    required String title,
    required String subtitle,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: labelColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: const Color(0xFF8A7E76),
                fontSize: 11.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickupSlotCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EB),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFFFF5E00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'svc_pickup_slot'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _slot,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(ServiceBookingDetail detail) {
    final paid = detail.isPaid;
    final amount = paid ? detail.totalPaid : detail.total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2520),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'svc_payment_details'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          if (detail.paymentLabel.isNotEmpty) ...[
            _payRow('svc_payment'.tr, detail.paymentLabel),
            const SizedBox(height: 10),
          ],
          _payRow('svc_subtotal'.tr, serviceMru(detail.subtotal)),
          const SizedBox(height: 10),
          _payRow('svc_tax'.tr, serviceMru(detail.tax)),
          if (amount != detail.total) ...[
            const SizedBox(height: 10),
            _payRow('svc_total'.tr, serviceMru(detail.total)),
          ],
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF4A4038), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                (paid ? 'svc_total_paid' : 'svc_to_pay').tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                serviceMru(amount),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
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
            color: const Color(0xFFD4CBC3),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDueCard() {
    final rate = _number('rate') ?? 0;
    final estimate = _number('estimate_kg') ?? 0;
    final actual = _number('actual_kg');

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8DD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'svc_balance_due_upper'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (estimate > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'svc_estimated_weight'.trParams({
                        'weight': '${_trimNumber(estimate)} ${'svc_kg'.tr}',
                      }),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (rate > 0)
                      Text(
                        serviceMru(estimate * rate),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
              if (actual != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: 'svc_actual_weight'.tr),
                          TextSpan(
                            text: '${_trimNumber(actual)} ${'svc_kg'.tr}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rate > 0)
                      Text(
                        serviceMru(actual * rate),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'svc_balance_due'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'svc_amount_due_after_weighing'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                serviceMru(_balanceDue),
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelBar(double bottomInset) {
    final balance = _balanceDue;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      color: const Color(0xFFFAF6F0),
      child: Row(
        children: [
          if (balance > 0) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => showAppToast('orders_balance_unavailable'.tr),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'svc_pay_value'.trParams({'amount': serviceMru(balance)}),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            if (_canCancel) const SizedBox(width: 12),
          ],
          if (_canCancel)
            Expanded(
              child: GestureDetector(
                onTap: () => showCancelBookingBottomSheet(
                  context,
                  bookingId: _bookingId,
                  apiOrderId: booking['apiOrderId'] as int?,
                  onCancelled: () => Navigator.of(context).pop(true),
                ),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2ECE1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1B2B4A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
