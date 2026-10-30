import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';

import '../../core/network/api_exception.dart';
import '../../models/order_tracking.dart';
import '../../utils/toast_helper.dart';
import '../help_support_screen.dart';
import '../../widgets/cancel_order_bottom_sheet.dart';
import 'courier_track_order_screen.dart';

/// A courier or express order's status, route, driver and payment, from
/// customer/orderDetails.
class CourierOrderDetailScreen extends StatefulWidget {
  /// Order code shown to the customer, used until the details load.
  final String orderId;

  /// Numeric order id for customer/orderDetails.
  final int? apiOrderId;

  /// Shown until the details load (e.g. from the My Orders list).
  final String pickupAddress;
  final String dropOffAddress;

  const CourierOrderDetailScreen({
    super.key,
    this.orderId = '',
    this.apiOrderId,
    this.pickupAddress = '',
    this.dropOffAddress = '',
  });

  @override
  State<CourierOrderDetailScreen> createState() =>
      _CourierOrderDetailScreenState();
}

class _CourierOrderDetailScreenState extends State<CourierOrderDetailScreen> {
  OrderTracking? _detail;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await loadOrderDetail(widget.apiOrderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = detail == null ? 'Order details are not available' : null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayId {
    final code = _detail?.orderCode.isNotEmpty == true
        ? _detail!.orderCode
        : widget.orderId.trim();
    if (code.isEmpty) return '';
    return code.startsWith('#') ? code : '#$code';
  }

  // Cancel is only accepted before a driver is assigned (status 1–2).
  bool get _canCancel {
    final detail = _detail;
    return detail != null && detail.status <= 2 && !detail.hasDriver;
  }

  bool get _canTrack => _detail != null && !_detail!.isCancelled;

  List<_StatusStep> get _steps {
    final detail = _detail;
    final status = detail?.status ?? 0;
    String time(int code) => _stepTime(detail?.timeOf(code) ?? '');
    final cancelled = detail?.isCancelled == true;
    return [
      _StatusStep(
        label: 'Booking\nConfirmed',
        time: _stepTime(detail?.placedAt ?? ''),
        done: status >= 1,
        icon: Icons.check_rounded,
      ),
      _StatusStep(
        label: 'At Pickup',
        time: time(6),
        done: !cancelled && status >= 6,
        icon: Icons.location_on_outlined,
      ),
      _StatusStep(
        label: 'On the way',
        time: time(7).isNotEmpty ? time(7) : time(8),
        done: !cancelled && status >= 7,
        icon: Icons.two_wheeler_rounded,
        useDeliveryIcon: true,
      ),
      cancelled
          ? _StatusStep(
              label: 'Cancelled',
              time: time(10),
              done: true,
              icon: Icons.close_rounded,
            )
          : _StatusStep(
              label: 'Delivered',
              time: time(9),
              done: status >= 9,
              icon: Icons.check_rounded,
            ),
    ];
  }

  /// "22 Oct 2025 10:00 AM" (or with a comma) → "22 Oct 2025,\n10:00 AM".
  static String _stepTime(String raw) {
    final parts = raw.replaceAll(',', '').trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return raw.trim();
    return '${parts.take(3).join(' ')},\n${parts.skip(3).join(' ')}';
  }

  static String _money(dynamic value, {bool negative = false}) {
    final number = double.tryParse('${value ?? ''}');
    if (number == null) return '— MRU';
    final text = '${number.round()} MRU';
    return negative && number > 0 ? '-$text' : text;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: _detail == null
                    ? _buildPlaceholder()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Order Status'),
                            const SizedBox(height: 10),
                            _buildOrderStatusCard(),
                            const SizedBox(height: 18),
                            _sectionTitle('Delivery Details'),
                            const SizedBox(height: 10),
                            _buildDeliveryRouteCard(),
                            if (_detail!.packageDescription.isNotEmpty ||
                                _detail!.packageSize.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _buildPackageCard(),
                            ],
                            const SizedBox(height: 10),
                            _buildDriverCard(),
                            const SizedBox(height: 18),
                            _buildPaymentCard(),
                          ],
                        ),
                      ),
              ),
              if (_canCancel || _canTrack)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12 + bottomInset * 0.2,
                  ),
                  child: Row(
                    children: [
                      if (_canCancel)
                        Expanded(child: _buildCancelButton(context)),
                      if (_canCancel && _canTrack) const SizedBox(width: 12),
                      if (_canTrack) Expanded(child: _buildTrackButton()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: _loading
          ? const CircularProgressIndicator(color: Color(0xFFFF5E00))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error ?? 'Order details are not available',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2C2520),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              _displayId.isEmpty ? 'Order' : 'Order $_displayId',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const HelpSupportScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAD8C9)),
              ),
              child: Text(
                'Help',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    final steps = _steps;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
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
                height: circle + 8,
                child: Stack(
                  alignment: Alignment.centerLeft,
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
                        for (final step in steps)
                          Container(
                            width: circle,
                            height: circle,
                            decoration: BoxDecoration(
                              color: step.done
                                  ? const Color(0xFFFF5E00)
                                  : const Color(0xFFEFE8E1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: step.useDeliveryIcon && step.done
                                ? Image.asset(
                                    'lib/assets/images/delivery_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                    errorBuilder: (_, _, _) => Icon(
                                      step.icon,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                : Icon(
                                    step.icon,
                                    color: step.done
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
                          step.label,
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

  Widget _buildDeliveryRouteCard() {
    final detail = _detail!;
    final pickup = detail.pickup;
    final dropoff = detail.dropoff;
    final pickupAddress = pickup.address.isNotEmpty
        ? pickup.address
        : widget.pickupAddress;
    final dropOffAddress = dropoff.address.isNotEmpty
        ? dropoff.address
        : widget.dropOffAddress;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  _routeDot(
                    fill: const Color(0xFF2F80ED),
                    halo: const Color(0xFFD6E6FB),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        painter: _VerticalDashedLinePainter(
                          color: const Color(0xFFD0C8C0),
                        ),
                      ),
                    ),
                  ),
                  _routeDot(
                    fill: const Color(0xFFFF5E00),
                    halo: const Color(0xFFFFE0CC),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteRow(
                    label: 'PICKUP',
                    title: pickupAddress.isEmpty ? '—' : pickupAddress,
                    contact: _contactLine(pickup),
                  ),
                  const SizedBox(height: 18),
                  _buildRouteRow(
                    label: 'DROP-OFF',
                    title: dropOffAddress.isEmpty ? '—' : dropOffAddress,
                    contact: _contactLine(dropoff),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _contactLine(CourierStop stop) => [
    if (stop.contactName.isNotEmpty) stop.contactName,
    if (stop.contactPhone.isNotEmpty) stop.contactPhone,
  ].join(' • ');

  Widget _routeDot({required Color fill, required Color halo}) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: halo, shape: BoxShape.circle),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildRouteRow({
    required String label,
    required String title,
    String contact = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        if (contact.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            contact,
            style: GoogleFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPackageCard() {
    final detail = _detail!;
    final size = detail.packageSize;
    final title = [
      if (size.isNotEmpty) '${size[0].toUpperCase()}${size.substring(1)} parcel',
      detail.isExpress ? 'Express' : 'Standard',
    ].join(' • ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFFFF5E00),
            size: 22,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (detail.packageDescription.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail.packageDescription,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildDriverCard() {
    final detail = _detail!;
    final placeholder = Container(
      width: 46,
      height: 46,
      color: const Color(0xFFF3EFEA),
      child: const Icon(Icons.person, color: Color(0xFFFF5E00)),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: !detail.hasDriver
          ? Text(
              detail.isFinished
                  ? 'No driver for this order'
                  : 'A driver will be assigned soon',
              style: GoogleFonts.outfit(
                color: const Color(0xFF7A6A60),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          : Row(
              children: [
                ClipOval(
                  child: detail.driverImage.isEmpty
                      ? placeholder
                      : Image.network(
                          detail.driverImage,
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
                        detail.driverName.isEmpty
                            ? 'Driver'
                            : detail.driverName,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                            [
                              detail.driverRating > 0
                                  ? detail.driverRating.toStringAsFixed(1)
                                  : 'New',
                              if (detail.driverReviews > 0)
                                '(${detail.driverReviews} reviews)',
                            ].join(' '),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
                  onTap: () => showAppToast(
                    'Calling your driver from the app is coming soon',
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5E00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentCard() {
    final payment = _detail!.payment;
    final redeemed = double.tryParse('${payment['redeemed_points'] ?? ''}');
    final tax = double.tryParse('${payment['tax'] ?? ''}') ?? 0;
    final discount = double.tryParse('${payment['discount'] ?? ''}') ?? 0;
    final isCash = '${payment['payment_type'] ?? ''}'.toLowerCase() == 'cash';
    final totalLabel = isCash && !_detail!.isDelivered ? 'To pay' : 'Total paid';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _payRow('Delivery fee', _money(payment['delivery_fee'])),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _payRow(
              'Discount',
              _money(discount, negative: true),
              valueColor: const Color(0xFFFF5E00),
            ),
          ],
          if (redeemed != null && redeemed > 0) ...[
            const SizedBox(height: 10),
            _payRow(
              'Redeemed points',
              '-${redeemed.round()} pts',
              valueColor: const Color(0xFFFF5E00),
            ),
          ],
          if (tax > 0) ...[
            const SizedBox(height: 10),
            _payRow('Tax', _money(tax)),
          ],
          const SizedBox(height: 10),
          _payRow('Payment', isCash ? 'Cash' : 'Online'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A3A3A)),
          ),
          Row(
            children: [
              Text(
                totalLabel,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _money(payment['total_bill']),
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
            color: const Color(0xFFD4CDC5),
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

  Widget _buildCancelButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showCancelOrderBottomSheet(
          context,
          orderId: _displayId,
          apiOrderId: widget.apiOrderId,
          onCancelled: _load,
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
          'Cancel',
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
      onTap: () => Get.to(
        () => CourierTrackOrderScreen(
          orderId: _displayId,
          apiOrderId: widget.apiOrderId,
        ),
      ),
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
          'Track Delivery',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusStep {
  final String label;
  final String time;
  final bool done;
  final IconData icon;
  final bool useDeliveryIcon;

  const _StatusStep({
    required this.label,
    required this.time,
    required this.done,
    required this.icon,
    this.useDeliveryIcon = false,
  });
}

class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;

  _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
