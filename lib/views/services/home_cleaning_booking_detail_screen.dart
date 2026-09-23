import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cancel_booking_bottom_sheet.dart';
import '../help_support_screen.dart';

class HomeCleaningBookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const HomeCleaningBookingDetailScreen({
    super.key,
    required this.booking,
  });

  String get _bookingId => (booking['id'] as String?) ?? '22789002';
  String get _slot =>
      (booking['slot'] as String?) ??
      (booking['datetime'] as String?) ??
      '15 Aug 2024, 2:00 – 4:00 PM';
  String get _locationTitle =>
      (booking['locationTitle'] as String?) ?? 'Sahara View Home';
  String get _locationSubtitle =>
      (booking['location'] as String?) ??
      'Near Marhaba Supermarket, Nouakchott';

  static const _statusSteps = [
    {
      'label': 'Booking\nConfirmed',
      'time': '15 Aug 2026,\n10:00 AM',
      'icon': Icons.check_rounded,
      'custom': null,
      'done': true,
    },
    {
      'label': 'Cleaner\nAssigned',
      'time': '15 Aug 2026,\n10:05 AM',
      'icon': Icons.person_rounded,
      'custom': 'person',
      'done': true,
    },
    {
      'label': 'Cleaner\nArriving',
      'time': '15 Aug 2026,\n10:10 AM',
      'icon': Icons.directions_car_filled_rounded,
      'custom': null,
      'done': true,
    },
    {
      'label': 'Completed',
      'time': '',
      'icon': Icons.check_rounded,
      'custom': null,
      'done': false,
    },
  ];

  static const _spaces = [
    {'label': 'Bedrooms', 'detail': '100 MRU x 4', 'total': '400 MRU'},
    {'label': 'Kitchens', 'detail': '150 MRU x 1', 'total': '150 MRU'},
  ];

  static const _extras = [
    {'label': 'Fridge Cleaning', 'detail': '100 MRU x 1', 'total': '100 MRU'},
  ];

  @override
  Widget build(BuildContext context) {
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
                  padding:
                      EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset + 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('Spaces'),
                      const SizedBox(height: 12),
                      _buildLineItemsCard(_spaces),
                      const SizedBox(height: 22),
                      _sectionTitle('Make it extra clean'),
                      const SizedBox(height: 12),
                      _buildLineItemsCard(_extras),
                      const SizedBox(height: 22),
                      _buildCleaningProductsSection(),
                      const SizedBox(height: 22),
                      _sectionTitle('Cleaning Details'),
                      const SizedBox(height: 12),
                      _buildAddressCard(),
                      const SizedBox(height: 10),
                      _buildSlotCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('Assigned Cleaner'),
                      const SizedBox(height: 12),
                      _buildCleanerCard(),
                      const SizedBox(height: 22),
                      _buildPaymentDetails(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildCancelBar(bottomInset),
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
                border: Border.all(
                  color: const Color(0xFFEAD8C9),
                  width: 0.8,
                ),
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
              'Booking #$_bookingId',
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
                'Help',
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
            padding: const EdgeInsets.only(left: 4, bottom: 18),
            child: Text(
              'Booking Status',
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = _statusSteps.length;
              final stepWidth = constraints.maxWidth / count;
              final lineLeft = stepWidth / 2;
              final lineWidth = constraints.maxWidth - stepWidth;

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
                      width: lineWidth * (2 / 3),
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
                        for (final step in _statusSteps)
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
              : Icon(
                  step['icon'] as IconData,
                  color: iconColor,
                  size: 19,
                ),
        ),
        const SizedBox(height: 10),
        Text(
          step['label'] as String,
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
                          rows[i]['label']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildCleaningProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Cleaning Products')),
            Text(
              '+120 MRU',
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
                  'Provider will provide products',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cleaning products will be provided by the service provider',
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
                  'Your Slot',
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

  Widget _buildCleanerCard() {
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
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop',
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
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
                  'Amadou Sy',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
                      '4.8',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(10k + reviews)',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A7E76),
                        fontSize: 12,
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

  Widget _buildPaymentDetails() {
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
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Total', '770 MRU'),
          const SizedBox(height: 10),
          _detailRow(
            'Redeemed points',
            '-50 MRU',
            valueColor: const Color(0xFFFF5E00),
          ),
          const SizedBox(height: 10),
          _detailRow('Tax', '10 MRU'),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF4A4A4A), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Total paid',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '730 MRU',
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
          Get.context!,
          bookingId: _bookingId,
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
            'Cancel',
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
