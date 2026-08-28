import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterTrackOrderScreen extends StatefulWidget {
  final String orderId;

  const WaterTrackOrderScreen({super.key, this.orderId = "#22789002"});

  @override
  State<WaterTrackOrderScreen> createState() => _WaterTrackOrderScreenState();
}

class _WaterTrackOrderScreenState extends State<WaterTrackOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Map Canvas Background Display
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    Expanded(child: _buildMapGraphicArea()),
                    const SizedBox(height: 280), // Space for bottom sheet
                  ],
                ),
              ),

              // 2. Header Bar Overlay (Back Button + Title)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: _buildHeader(context),
              ),

              // 3. Sliding Bottom Sheet Container
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildTrackingBottomSheet(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar Widget
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
            'Track Order ${widget.orderId}',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  // Styled Map Graphic Background
  Widget _buildMapGraphicArea() {
    return Container(
      color: const Color(0xFFF4EFE8),
      child: Stack(
        children: [
          // Map Background Grid / Roads illustration
          CustomPaint(size: Size.infinite, painter: MapRoadsPainter()),

          // Store / Supplier Pin (Top Left)
          Positioned(
            top: 60,
            left: 90,
            child: _buildMapPinIcon(
              icon: Icons.storefront_rounded,
              color: const Color(0xFFFF5E00),
            ),
          ),

          // Courier Vehicle Pin (Center Route)
          Positioned(
            top: 110,
            left: 140,
            child: _buildMapPinIcon(
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFFFF5E00),
              isLarge: true,
            ),
          ),

          // Home Destination Pin (Right)
          Positioned(
            top: 170,
            right: 80,
            child: _buildMapPinIcon(
              icon: Icons.home_rounded,
              color: const Color(0xFFFF5E00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPinIcon({
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    final double size = isLarge ? 42 : 34;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: isLarge ? 22 : 18),
    );
  }

  // Tracking Info Bottom Sheet
  Widget _buildTrackingBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ON THE WAY Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'ON THE WAY',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ETA Row (12 min ETA)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '12 min',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ETA',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7E75),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Order Subtitle Line
          Text(
            'Order ${widget.orderId} • PureLife Water Co.',
            style: GoogleFonts.outfit(
              color: const Color(0xFF8C7E75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // 4-Step Status Timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineHighlightStep(
                icon: Icons.check_rounded,
                title: 'Order placed',
                subtitle: '26 Jul 2026, 11:30 AM',
                isHighlighted: true,
              ),
              _buildTimelineLine(isActive: true),
              _buildTimelineStep(
                icon: Icons.work_outline_rounded,
                title: 'Packing items',
                isActive: true,
              ),
              _buildTimelineLine(isActive: true),
              _buildTimelineStep(
                icon: Icons.local_shipping_outlined,
                title: 'On the way',
                isActive: true,
              ),
              _buildTimelineLine(isActive: false),
              _buildTimelineStep(
                icon: Icons.check_rounded,
                title: 'Delivered',
                isActive: false,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Your Driver Header & Contact Card
          Text(
            'Your Driver',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Driver Contact Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFFF0E6),
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFFFF5E00),
                    size: 24,
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '4.6 (12k + reviews)',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8C7E75),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Phone Call Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5E00),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHighlightStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isHighlighted,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A50).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8C7E75),
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required bool isActive,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFEFEBE7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFFA59A94),
              size: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: isActive
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFA59A94),
              fontSize: 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine({required bool isActive}) {
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.only(top: 13),
      color: isActive ? const Color(0xFFFF5E00) : const Color(0xFFEAD8C9),
    );
  }
}

// Custom Painter for Map Route & Parks
class MapRoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Parks fill
    final parkPaint = Paint(), color = const Color(0xFFE4EFE0);

    final parkPath1 = Path()
      ..moveTo(size.width * 0.25, size.height * 0.2)
      ..lineTo(size.width * 0.55, size.height * 0.15)
      ..lineTo(size.width * 0.7, size.height * 0.35)
      ..lineTo(size.width * 0.35, size.height * 0.4)
      ..close();
    canvas.drawPath(parkPath1, parkPaint);

    final parkPath2 = Path()
      ..moveTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.65)
      ..lineTo(size.width * 0.1, size.height * 0.7)
      ..close();
    canvas.drawPath(parkPath2, parkPaint);

    // Roads Stroke
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFE6DCD3)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    final road1 = Path()
      ..moveTo(0, size.height * 0.25)
      ..lineTo(size.width, size.height * 0.45);
    canvas.drawPath(road1, roadBorderPaint);
    canvas.drawPath(road1, roadPaint);

    final road2 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.6, size.height);
    canvas.drawPath(road2, roadBorderPaint);
    canvas.drawPath(road2, roadPaint);

    // Curved Delivery Route Line
    final routePaint = Paint()
      ..color = const Color(0xFF4E3D35)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePath = Path()
      ..moveTo(105, 75)
      ..quadraticBezierTo(155, 125, size.width - 95, 185);

    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
