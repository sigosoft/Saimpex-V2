import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_exception.dart';
import '../../models/service_booking_detail.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/cancel_booking_bottom_sheet.dart';
import '../../widgets/app_back_button.dart';

class CarWashBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const CarWashBookingDetailScreen({super.key, required this.booking});

  @override
  State<CarWashBookingDetailScreen> createState() =>
      _CarWashBookingDetailScreenState();
}

class _CarWashBookingDetailScreenState
    extends State<CarWashBookingDetailScreen> {
  ServiceBookingDetail? _detail;

  Map<String, dynamic> get _booking => widget.booking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await loadServiceBooking(_booking['apiOrderId'] as int?);
      if (!mounted || detail == null) return;
      setState(() => _detail = detail);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  String _text(dynamic value) => '${value ?? ''}'.trim();

  String _firstOf(String fromDetail, List<String> keys) {
    if (fromDetail.isNotEmpty) return fromDetail;
    for (final key in keys) {
      final value = _text(_booking[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String get _bookingId => _firstOf(_detail?.orderCode ?? '', ['id']);

  String get _service =>
      _firstOf(_detail?.serviceName ?? '', ['service', 'serviceTitle']);

  String get _serviceImage => _text(_detail?['service_image']);

  String get _slot => _firstOf(_detail?.slot ?? '', ['slot', 'datetime']);

  String get _location {
    final detail = _detail;
    if (detail != null) {
      final parts = [
        detail.location,
        detail.address,
      ].where((part) => part.isNotEmpty).toSet();
      if (parts.isNotEmpty) return parts.join(' · ');
    }
    return _text(_booking['location']);
  }

  String get _paymentLabel =>
      _firstOf(_detail?.paymentLabel ?? '', ['payment']);

  bool get _canCancel => _detail?.canCancel ?? _booking['canCancel'] == true;

  static String _amount(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(2);

  String _vehicleImage(String type) {
    final label = type.toLowerCase();
    if (label.contains('suv') || label.contains('4x4')) {
      return 'lib/assets/images/SUV.png';
    }
    if (label.contains('pickup')) {
      return 'lib/assets/images/Pickup.png';
    }
    if (label.contains('mini') || label.contains('bus')) {
      return 'lib/assets/images/MiniBus.png';
    }
    return 'lib/assets/images/Sedan.png';
  }

  List<Map<String, dynamic>> get _statusSteps {
    final detail = _detail!;
    final cancelled = detail.isCancelled;
    return [
      {
        'label': 'svc_step_booking_confirmed',
        'time': detail.timeOf(1),
        'icon': Icons.check_rounded,
        'done': detail.reached(1),
      },
      {
        'label': 'svc_step_vehicle_received',
        'time': detail.timeOf(2),
        'icon': Icons.directions_car_filled_rounded,
        'done': detail.reached(2),
      },
      {
        'label': 'svc_step_ready_for_pickup',
        'time': detail.timeOf(4),
        'icon': Icons.check_rounded,
        'done': detail.reached(4),
      },
      if (cancelled)
        {
          'label': 'svc_step_cancelled',
          'time': detail.timeOf(10),
          'icon': Icons.close_rounded,
          'done': true,
          'cancelled': true,
        }
      else
        {
          'label': 'svc_step_completed',
          'time': detail.timeOf(9),
          'icon': Icons.check_rounded,
          'done': detail.reached(9),
        },
    ];
  }

  void _cancel() {
    showCancelBookingBottomSheet(
      context,
      bookingId: _bookingId,
      apiOrderId: _booking['apiOrderId'] as int?,
      onCancelled: () {
        if (mounted) Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final detail = _detail;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFDFBF7),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFDFBF7),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
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
                    10,
                    16,
                    20 + bottomInset + (_canCancel ? 72 : 0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detail != null) ...[
                        _buildStatusCard(),
                        const SizedBox(height: 22),
                      ],
                      if (_hasVehicleSection) ...[
                        _sectionTitle('svc_vehicles'.tr),
                        const SizedBox(height: 12),
                        _buildVehicleCard(),
                        const SizedBox(height: 22),
                      ],
                      if (_location.isNotEmpty || _slot.isNotEmpty) ...[
                        _sectionTitle('svc_washing_details'.tr),
                        const SizedBox(height: 12),
                        if (_location.isNotEmpty) _buildLocationCard(),
                        if (_location.isNotEmpty && _slot.isNotEmpty)
                          const SizedBox(height: 10),
                        if (_slot.isNotEmpty) _buildSlotCard(),
                        const SizedBox(height: 22),
                      ],
                      _buildPaymentDetails(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _canCancel ? _buildCancelBar(bottomInset) : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              _bookingId.isEmpty
                  ? ''
                  : 'svc_booking_number'.trParams({'id': _bookingId}),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFF5E00).withValues(alpha: 0.45),
                ),
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
        color: const Color(0xFF1A1A1A),
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatusCard() {
    const circleSize = 36.0;
    const lineTop = 18.0;
    final steps = _statusSteps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'svc_booking_status'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = steps.length;
              final stepWidth = constraints.maxWidth / count;
              final lineLeft = stepWidth / 2;
              final lineWidth = constraints.maxWidth - stepWidth;
              final lastDone = steps.lastIndexWhere(
                (s) => s['done'] == true && s['cancelled'] != true,
              );
              final progress = lastDone <= 0 ? 0.0 : lastDone / (count - 1);

              return SizedBox(
                height: 118,
                child: Stack(
                  children: [
                    PositionedDirectional(
                      top: lineTop - 1.5,
                      start: lineLeft,
                      width: lineWidth,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8DFD6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: lineTop - 1.5,
                      start: lineLeft,
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
        ],
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
            color: const Color(0xFF1A1A1A),
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

  List<ServiceBookingLine> _lines(String kind) =>
      _detail?.lines(kind) ?? const [];

  bool get _hasVehicleSection =>
      _lines('vehicle').isNotEmpty ||
      _lines('addon').isNotEmpty ||
      _lines('distance').isNotEmpty ||
      (_detail == null && _service.isNotEmpty);

  String _lineDescription(ServiceBookingLine line) {
    if (line.quantity <= 1) return '';
    return 'svc_rate_times_qty'.trParams({
      'rate': _amount(line.price),
      'qty': _amount(line.quantity),
    });
  }

  Widget _buildVehicleCard() {
    final vehicles = _lines('vehicle');
    final addons = _lines('addon');
    final distances = _lines('distance');
    final fallbackPrice = _text(_booking['price']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_detail == null)
            _nestedServiceRow(
              image: _serviceImage,
              title: _service,
              description: '',
              priceLabel: fallbackPrice,
            ),
          for (var i = 0; i < vehicles.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8E2)),
              const SizedBox(height: 14),
            ],
            _vehicleHeader(vehicles[i]),
            const SizedBox(height: 16),
            _nestedServiceRow(
              image: _serviceImage,
              title: _service.isNotEmpty ? _service : vehicles[i].name,
              description: _lineDescription(vehicles[i]),
              priceLabel: serviceMru(vehicles[i].total),
            ),
          ],
          if (addons.isNotEmpty) ...[
            if (vehicles.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8E2)),
              const SizedBox(height: 12),
            ],
            Text(
              'svc_addon_services'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF5A6B7D),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < addons.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _nestedServiceRow(
                image: '',
                title: addons[i].name.isNotEmpty
                    ? addons[i].name
                    : 'svc_addon'.tr,
                description: _lineDescription(addons[i]),
                priceLabel: '+${serviceMru(addons[i].total)}',
              ),
            ],
          ],
          for (final distance in distances) ...[
            if (vehicles.isNotEmpty || addons.isNotEmpty)
              const SizedBox(height: 10),
            _nestedServiceRow(
              image: '',
              icon: Icons.near_me_rounded,
              title: distance.name,
              description: '',
              priceLabel: '+${serviceMru(distance.total)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _vehicleHeader(ServiceBookingLine vehicle) {
    final type = vehicle.name;
    final plate = vehicle.unit;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 78,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFECECEC)),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, type.isEmpty ? 0 : 22),
                  child: type.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.directions_car_rounded,
                            color: Color(0xFFFF5E00),
                          ),
                        )
                      : Image.asset(
                          _vehicleImage(type),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Color(0xFFFF5E00),
                            ),
                          ),
                        ),
                ),
                if (type.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child: Text(
                        type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plate.isNotEmpty) ...[
                Text(
                  plate,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0D1B2A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
              ],
              if (_service.isNotEmpty)
                Text(
                  _service,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF5A6B7D),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nestedServiceRow({
    required String image,
    required String title,
    required String description,
    required String priceLabel,
    IconData icon = Icons.local_car_wash_rounded,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image.startsWith('http')
                ? Image.network(
                    image,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imageFallback(icon),
                  )
                : _imageFallback(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0D1B2A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (priceLabel.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              priceLabel,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imageFallback(IconData icon) {
    return Container(
      width: 54,
      height: 54,
      color: const Color(0xFFFFF3EB),
      child: Icon(icon, color: const Color(0xFFFF5E00), size: 22),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
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
                  'svc_location'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  Widget _buildSlotCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.12),
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
                  'svc_your_slot'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _slot,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF6B6560),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  Widget _buildPaymentDetails() {
    final detail = _detail;
    final String bottomLabel;
    final String bottomValue;
    if (detail == null) {
      bottomLabel = 'svc_total'.tr;
      bottomValue = _text(_booking['price']);
    } else if (detail.isPaid) {
      bottomLabel = 'svc_total_paid'.tr;
      bottomValue = serviceMru(detail.totalPaid);
    } else {
      bottomLabel = 'svc_to_pay'.tr;
      bottomValue = serviceMru(detail.total);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'svc_payment_details'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          if (_paymentLabel.isNotEmpty) ...[
            _payRow('svc_payment'.tr, _paymentLabel),
            const SizedBox(height: 10),
          ],
          if (detail != null) ...[
            _payRow('svc_subtotal'.tr, serviceMru(detail.subtotal)),
            const SizedBox(height: 10),
            _payRow('svc_tax'.tr, serviceMru(detail.tax)),
            const SizedBox(height: 10),
            _payRow('svc_total'.tr, serviceMru(detail.total)),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFF4A4A4A)),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Text(
                bottomLabel,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                bottomValue,
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

  Widget _payRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      color: const Color(0xFFFDFBF7),
      child: GestureDetector(
        onTap: _cancel,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF2ECE4),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'cancel'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
