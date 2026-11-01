import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Map<String, dynamic>> coupons = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    if (!Get.isRegistered<OrderRepository>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final loaded = await Get.find<OrderRepository>().coupons(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        coupons = [
          for (var index = 0; index < loaded.length; index++)
            {
              ...loaded[index],
              'isPink': index.isEven,
              'badges': '${loaded[index]['discount'] ?? ''}'.trim().isEmpty
                  ? <String>[]
                  : <String>['${loaded[index]['discount']}'],
            },
        ];
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppBackButton(onTap: () => Navigator.pop(context)),
                ),
                Text(
                  'core_coupons_title'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
            )
          : ListView.builder(
              itemCount: coupons.length,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemBuilder: (context, index) {
                final coupon = coupons[index];
                final isPink = coupon['isPink'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCouponCard(context, coupon, isPink),
                );
              },
            ),
    );
  }

  Widget _buildCouponCard(
    BuildContext context,
    Map<String, dynamic> coupon,
    bool isPink,
  ) {
    return ClipPath(
      clipper: const TicketClipper(cornerRadius: 16, notchRadius: 10),
      child: Container(
        height: 116,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left gradient section
            SizedBox(
              width: 110,
              height: double.infinity,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: isPink
                          ? const LinearGradient(
                              colors: [Color(0xFFFF899B), Color(0xFFFFBCC3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF8CEE9D), Color(0xFFC7FCD1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 20,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              coupon['discount'].toString().replaceAll('%', ''),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '%',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'core_coupons_off'.tr,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ('${coupon['image'] ?? ''}'.isNotEmpty)
                    PositionedDirectional(
                      end: -10,
                      bottom: -10,
                      child: Image.network(
                        coupon['image'] as String,
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),

            // Right coupon details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badges row
                    Row(
                      children: (coupon['badges'] as List<String>).map((badge) {
                        final isBestDeal = badge.contains('BEST DEAL');
                        final isLimited = badge.contains('LIMITED');

                        Color textColor;
                        Color fillColor;
                        Color borderColor;

                        if (isBestDeal) {
                          textColor = const Color(0xFFFF3E56);
                          fillColor = const Color(0xFFFFF0F2);
                          borderColor = const Color(0xFFFFDCE0);
                        } else if (isLimited) {
                          textColor = const Color(0xFFFF8C3E);
                          fillColor = const Color(0xFFFFF5EE);
                          borderColor = const Color(0xFFFFE3D0);
                        } else {
                          // Free delivery
                          textColor = const Color(0xFF00B25C);
                          fillColor = const Color(0xFFE8FDF0);
                          borderColor = const Color(0xFFC7FCDD);
                        }

                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: fillColor,
                              border: Border.all(
                                color: borderColor,
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.outfit(
                                color: textColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Discount title
                    Text(
                      coupon['title'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Subtitle
                    Text(
                      coupon['subtitle'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Code and Apply button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: coupon['code'] as String),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'core_coupons_copied'.trParams({
                                    'code': '${coupon['code']}',
                                  }),
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: const Color(0xFFFF5E00),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: CustomPaint(
                            painter: DashedBorderPainter(
                              color: const Color(0xFFFFD2BB),
                              borderRadius: 10,
                              strokeWidth: 1.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    coupon['code'] as String,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5E00),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.copy_rounded,
                                    color: Color(0xFFFF5E00),
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'core_coupons_applied'.tr,
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: const Color(0xFFFF5E00),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 32,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5E00,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'core_coupons_apply'.tr,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchRadius;

  const TicketClipper({this.cornerRadius = 16.0, this.notchRadius = 10.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final R = cornerRadius;
    final r = notchRadius;
    final w = size.width;
    final h = size.height;
    final cy = h / 2;

    path.moveTo(R, 0);

    path.lineTo(w - R, 0);
    path.arcToPoint(Offset(w, R), radius: Radius.circular(R), clockwise: true);

    path.lineTo(w, h - R);
    path.arcToPoint(
      Offset(w - R, h),
      radius: Radius.circular(R),
      clockwise: true,
    );

    path.lineTo(R, h);
    path.arcToPoint(
      Offset(0, h - R),
      radius: Radius.circular(R),
      clockwise: true,
    );

    path.lineTo(0, cy + r);
    path.arcToPoint(
      Offset(0, cy - r),
      radius: Radius.circular(r),
      clockwise: false,
    );

    path.lineTo(0, R);
    path.arcToPoint(Offset(R, 0), radius: Radius.circular(R), clockwise: true);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.dashLength = 4.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
