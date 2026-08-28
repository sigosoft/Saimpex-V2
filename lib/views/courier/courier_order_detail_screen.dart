import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../help_support_screen.dart';
import 'courier_track_order_screen.dart';

class CourierOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final String pickupAddress;
  final String dropOffAddress;
  final String deliveryFee;
  final String totalToPay;

  const CourierOrderDetailScreen({
    super.key,
    this.orderId = '#227890011',
    this.pickupAddress = 'Marhaba Supermarket, Nouakchott',
    this.dropOffAddress = 'Saimpex Logistics Hub, Wharf Sector',
    this.deliveryFee = '50 MRU',
    this.totalToPay = '51 MRU',
  });

  static const _steps = [
    _StatusStep(
      label: 'Booking\nConfirmed',
      time: '22 Oct 2025,\n10:00 AM',
      done: true,
      icon: Icons.check_rounded,
    ),
    _StatusStep(
      label: 'At Pickup',
      time: '22 Oct 2025,\n10:05 AM',
      done: true,
      icon: Icons.location_on_outlined,
    ),
    _StatusStep(
      label: 'On the way',
      time: '22 Oct 2025,\n10:10 AM',
      done: true,
      icon: Icons.two_wheeler_rounded,
      useDeliveryIcon: true,
    ),
    _StatusStep(
      label: 'Delivered',
      time: '',
      done: false,
      icon: Icons.check_rounded,
    ),
  ];

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
                child: SingleChildScrollView(
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
                      const SizedBox(height: 10),
                      _buildDriverCard(),
                      const SizedBox(height: 18),
                      _buildPaymentCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset * 0.2),
                child: Row(
                  children: [
                    Expanded(child: _buildCancelButton(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTrackButton()),
                  ],
                ),
              ),
            ],
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
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAD8C9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFFF5E00),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Order $orderId',
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
                          final active = i < 2;
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
                        for (var i = 0; i < _steps.length; i++)
                          Container(
                            width: circle,
                            height: circle,
                            decoration: BoxDecoration(
                              color: _steps[i].done
                                  ? const Color(0xFFFF5E00)
                                  : const Color(0xFFEFE8E1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: _steps[i].useDeliveryIcon && _steps[i].done
                                ? Image.asset(
                                    'lib/assets/images/delivery_icon.png',
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                    errorBuilder: (_, __, ___) => Icon(
                                      _steps[i].icon,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                : Icon(
                                    _steps[i].icon,
                                    color: _steps[i].done
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
                children: _steps.map((step) {
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 14,
              child: Column(
                children: [
                  _routeDot(const Color(0xFF2F80ED)),
                  Expanded(
                    child: CustomPaint(
                      painter: _VerticalDashedLinePainter(
                        color: const Color(0xFFD9D0C8),
                      ),
                    ),
                  ),
                  _routeDot(const Color(0xFFFF5E00)),
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
                    title: pickupAddress,
                    labelColor: const Color(0xFF2F80ED),
                  ),
                  const SizedBox(height: 14),
                  _buildRouteRow(
                    label: 'DROP-OFF',
                    title: dropOffAddress,
                    labelColor: const Color(0xFFFF5E00),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildRouteRow({
    required String label,
    required String title,
    required Color labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: labelColor.withValues(alpha: 0.85),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard() {
    return Container(
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
        children: [
          ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&auto=format&fit=crop',
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 46,
                color: const Color(0xFFF3EFEA),
                child: const Icon(Icons.person, color: Color(0xFFFF5E00)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amadou Sy',
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
                      '4.6 (10k + reviews)',
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
          Container(
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
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
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
          _payRow('Delivery fee', deliveryFee),
          const SizedBox(height: 10),
          _payRow(
            'Redeemed points',
            '-1 MRU',
            valueColor: const Color(0xFFFF5E00),
          ),
          const SizedBox(height: 10),
          _payRow('Tax', '2 MRU'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A3A3A)),
          ),
          Row(
            children: [
              Text(
                'To pay',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                totalToPay,
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
      onTap: () => Get.back(),
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
      onTap: () => Get.to(() => CourierTrackOrderScreen(orderId: orderId)),
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
