import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/api_exception.dart';
import '../../models/service_booking_detail.dart';
import '../../models/service_repository.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/cancel_booking_bottom_sheet.dart';
import '../help_support_screen.dart';
import '../../widgets/app_back_button.dart';
import 'home_cleaning_cart_screen.dart' show homeCleaningLabelText;

/// Home cleaning and gas booking details from customer/service/booking.
class HomeCleaningBookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const HomeCleaningBookingDetailScreen({super.key, required this.booking});

  @override
  State<HomeCleaningBookingDetailScreen> createState() =>
      _HomeCleaningBookingDetailScreenState();
}

class _HomeCleaningBookingDetailScreenState
    extends State<HomeCleaningBookingDetailScreen> {
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

  bool get _isGas =>
      _detail?.vertical == ServiceRepository.gas ||
      booking['category'] == 'Gas';

  String get _bookingId {
    final code = _detail?.orderCode ?? '';
    return code.isNotEmpty ? code : _bookingText('id');
  }

  String get _slot {
    final slot = _detail?.slot ?? '';
    if (slot.isNotEmpty) return slot;
    final fromList = _bookingText('slot');
    return fromList.isNotEmpty ? fromList : _bookingText('datetime');
  }

  String get _locationTitle {
    final label = _detail?.addressLabel ?? '';
    if (label.isNotEmpty) return label;
    final location = _detail?.location ?? '';
    return location.isNotEmpty ? location : _bookingText('location');
  }

  String get _locationSubtitle {
    final address = _detail?.address ?? '';
    return address == _locationTitle ? '' : address;
  }

  bool get _canCancel => _detail?.canCancel ?? booking['canCancel'] == true;

  List<Map<String, dynamic>> get _statusSteps {
    final steps = _isGas
        ? const [
            (1, 'svc_step_booking_confirmed', Icons.check_rounded, null),
            (8, 'svc_step_on_the_way', Icons.local_shipping_rounded, null),
            (9, 'svc_step_delivered', Icons.check_rounded, null),
          ]
        : const [
            (1, 'svc_step_booking_confirmed', Icons.check_rounded, null),
            (2, 'svc_step_cleaner_assigned', Icons.person_rounded, 'person'),
            (
              8,
              'svc_step_cleaner_arriving',
              Icons.directions_car_filled_rounded,
              null,
            ),
            (9, 'svc_step_completed', Icons.check_rounded, null),
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
            'custom': null,
            'done': true,
          }
        else
          {
            'label': steps[i].$2,
            'time': detail?.timeOf(steps[i].$1) ?? '',
            'icon': steps[i].$3,
            'custom': steps[i].$4,
            'done': detail?.reached(steps[i].$1) ?? i == 0,
          },
    ];
  }

  List<Map<String, String>> _rows(String kind) => [
    for (final line in _detail?.lines(kind) ?? const <ServiceBookingLine>[])
      {
        'label': line.name,
        'detail':
            '${serviceMru(line.price)} x ${line.quantity == line.quantity.roundToDouble() ? line.quantity.round() : line.quantity}',
        'total': serviceMru(line.total),
      },
  ];

  @override
  Widget build(BuildContext context) {
    final spaces = _rows('space');
    final extras = _rows('addon');
    final detail = _detail;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

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
                      _buildStatusCard(),
                      if (_isGas && detail != null) ...[
                        const SizedBox(height: 22),
                        _sectionTitle('gas_title'.tr),
                        const SizedBox(height: 12),
                        _buildLineItemsCard([
                          {
                            'label': detail.serviceName,
                            'detail': 'gas_cylinders'.trParams({
                              'count': '${detail.quantity}',
                            }),
                            'total': serviceMru(detail.subtotal),
                          },
                          if (detail.emptyCylinders > 0)
                            {
                              'label': 'gas_empty_to_return'.tr,
                              'detail': '',
                              'total': '${detail.emptyCylinders}',
                            },
                        ]),
                      ],
                      if (spaces.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _sectionTitle('svc_spaces'.tr),
                        const SizedBox(height: 12),
                        _buildLineItemsCard(spaces),
                      ],
                      if (extras.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _sectionTitle('svc_extra_clean'.tr),
                        const SizedBox(height: 12),
                        _buildLineItemsCard(extras),
                      ],
                      if (!_isGas &&
                          (detail?.productSupply ?? '').isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _buildCleaningProductsSection(detail!),
                      ],
                      const SizedBox(height: 22),
                      _sectionTitle(
                        _isGas ? 'gas_delivery'.tr : 'svc_cleaning_details'.tr,
                      ),
                      const SizedBox(height: 12),
                      if (_locationTitle.isNotEmpty) ...[
                        _buildAddressCard(),
                        const SizedBox(height: 10),
                      ],
                      if (_slot.isNotEmpty) _buildSlotCard(),
                      if (!_isGas && detail != null) ...[
                        const SizedBox(height: 22),
                        _sectionTitle('svc_assigned_cleaner'.tr),
                        const SizedBox(height: 12),
                        _buildCleanerCard(detail.cleaner),
                      ],
                      if (detail != null) ...[
                        const SizedBox(height: 22),
                        _buildPaymentDetails(detail),
                      ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'svc_booking_number'.trParams({'id': _bookingId}),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const HelpSupportScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0D6CC), width: 1),
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
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildStatusCard() {
    const circleSize = 38.0;
    const lineTop = circleSize / 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 18),
            child: Text(
              'svc_booking_status'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final steps = _statusSteps;
              final count = steps.length;
              final stepWidth = constraints.maxWidth / count;
              final lineLeft = stepWidth / 2;
              final lineWidth = constraints.maxWidth - stepWidth;
              final done = steps.lastIndexWhere((step) => step['done'] == true);

              return SizedBox(
                height: 120,
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
                      width: lineWidth * (done < 1 ? 0 : done / (count - 1)),
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
    final custom = step['custom'] as String?;
    final iconColor = done ? Colors.white : const Color(0xFFB0A8A0);

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
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.38),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: custom == 'person'
              ? CustomPaint(
                  size: const Size(16, 18),
                  painter: _PersonStatusIconPainter(color: iconColor),
                )
              : Icon(step['icon'] as IconData, color: iconColor, size: 19),
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

  Widget _buildLineItemsCard(List<Map<String, String>> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3F0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homeCleaningLabelText(rows[i]['label']!),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (rows[i]['detail']!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            rows[i]['detail']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8A7E76),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    rows[i]['total']!,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCleaningProductsSection(ServiceBookingDetail detail) {
    final byProvider = detail.productSupply == 'vendor';
    final fee = detail.supplyFee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('svc_cleaning_products'.tr)),
            if (byProvider && fee > 0)
              Text(
                'svc_plus_mru'.trParams({'amount': '${fee.round()}'}),
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  byProvider
                      ? 'svc_provider_provides_products'.tr
                      : 'svc_self_provides_products'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  byProvider
                      ? 'svc_provider_products_hint'.tr
                      : 'svc_self_products_hint'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              color: const Color(0xFFFFF0E6),
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
                  _locationTitle,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_locationSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _locationSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8DC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
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
                    color: const Color(0xFF1A1A1A),
                    fontSize: 12.5,
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

  Widget _buildCleanerCard(Map<String, dynamic>? cleaner) {
    if (cleaner == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'svc_cleaner_pending'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF8A7E76),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    final photo = cleanerPhotoUrl(cleaner);
    final rating = double.tryParse('${cleaner['rating'] ?? ''}');
    final reviews = int.tryParse('${cleaner['reviews_count'] ?? ''}') ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            child: Image.network(
              photo,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                color: const Color(0xFFFFF0E6),
                child: const Icon(
                  Icons.person_rounded,
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
                  '${cleaner['name'] ?? ''}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'svc_reviews_count_paren'.trParams({
                          'count': '$reviews',
                        }),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8A7E76),
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildPaymentDetails(ServiceBookingDetail detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(32),
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
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('svc_subtotal'.tr, serviceMru(detail.subtotal)),
          if (detail.tax > 0) ...[
            const SizedBox(height: 10),
            _detailRow('svc_tax'.tr, serviceMru(detail.tax)),
          ],
          if (detail.paymentLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow('svc_payment'.tr, detail.paymentLabel),
          ],
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF4A4A4A), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                detail.isPaid ? 'svc_total_paid'.tr : 'svc_to_pay'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                serviceMru(detail.isPaid ? detail.totalPaid : detail.total),
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

  Widget _detailRow(String label, String value, {Color? valueColor}) {
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
            color: valueColor ?? Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      color: const Color(0xFFFAF6F0),
      child: GestureDetector(
        onTap: () => showCancelBookingBottomSheet(
          context,
          bookingId: _bookingId,
          apiOrderId: booking['apiOrderId'] as int?,
          onCancelled: () => Get.back(result: true),
        ),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE6DE),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            'cancel'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// White person icon: head + torso + two legs (matches booking status mock).
class _PersonStatusIconPainter extends CustomPainter {
  final Color color;

  const _PersonStatusIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Head
    final headRadius = w * 0.22;
    final headCenter = Offset(w / 2, headRadius);
    canvas.drawCircle(headCenter, headRadius, paint);

    // Torso (rounded top capsule)
    final torsoTop = headRadius * 2 + h * 0.06;
    final torsoWidth = w * 0.52;
    final torsoHeight = h * 0.42;
    final torsoLeft = (w - torsoWidth) / 2;
    final torsoRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(torsoLeft, torsoTop, torsoWidth, torsoHeight),
      topLeft: Radius.circular(torsoWidth / 2),
      topRight: Radius.circular(torsoWidth / 2),
      bottomLeft: Radius.circular(torsoWidth * 0.18),
      bottomRight: Radius.circular(torsoWidth * 0.18),
    );
    canvas.drawRRect(torsoRect, paint);

    // Legs
    final legWidth = w * 0.16;
    final legHeight = h * 0.28;
    final legTop = torsoTop + torsoHeight - h * 0.02;
    final gap = w * 0.08;
    final leftLegX = w / 2 - gap / 2 - legWidth;
    final rightLegX = w / 2 + gap / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftLegX, legTop, legWidth, legHeight),
        Radius.circular(legWidth / 2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightLegX, legTop, legWidth, legHeight),
        Radius.circular(legWidth / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PersonStatusIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
