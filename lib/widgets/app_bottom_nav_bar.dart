import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import 'bottom_chat_icon.dart';

/// Shared bottom navigation used by [MainShellScreen] and standalone pages.
///
/// A flat white bar with a notch cut around the raised Services disc. Every item
/// is an icon with a label under it; the cart shows an orange count badge.
class AppBottomNavBar extends StatelessWidget {
  static const double _barHeight = 66;
  static const double _iconSize = 22;
  static const double _iconStrokeFactor = 0.075;
  static const double _servicesDiscSize = 68;
  static const double _servicesBorder = 5;
  static const double _notchRadius = 44;
  static const double _iconSlotTop = 12;
  static const double _labelGap = 4;

  static const Color _barColor = Colors.white;
  static const Color _orange = Color(0xFFFF5E00);
  static const Color _inactive = Color(0xFF7B7B7B);

  final int selectedIndex;

  /// When set, called instead of default shell tab switching (for overlay routes).
  final ValueChanged<int>? onTap;

  final bool isServicesOption;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
    this.isServicesOption = false,
  });

  /// The disc sits above the bar top, so the widget reserves this much extra height.
  static const double _discOverhang = _servicesDiscSize / 2;

  void _handleTap(int index) {
    if (index == selectedIndex) {
      if (index == HomeController.navHome &&
          Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadHome();
      }
      return;
    }
    HapticFeedback.selectionClick();
    if (onTap != null) {
      onTap!(index);
      if (index == HomeController.navHome &&
          Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadHome();
      }
      return;
    }
    if (Get.isRegistered<HomeController>()) {
      final controller = Get.find<HomeController>();
      controller.selectNavigation(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final barHeight = _barHeight + bottomInset;

    return SizedBox(
      height: barHeight + _discOverhang,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: CustomPaint(
              painter: _NavBarPainter(
                color: _barColor,
                notchRadius: _notchRadius,
                bottomInset: bottomInset,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  children: [
                    _navItem(
                      index: HomeController.navHome,
                      label: 'Home',
                      asset: 'lib/assets/images/Bottom Home.png',
                    ),
                    _navItem(
                      index: HomeController.navBookings,
                      label: 'Bookings',
                      asset: null,
                    ),
                    _navItem(
                      index: HomeController.navOrders,
                      label: 'Orders',
                      asset: 'lib/assets/images/Bottom Order.png',
                    ),
                    _servicesItem(),
                    _navItem(
                      index: HomeController.navCart,
                      label: 'Cart',
                      asset: 'lib/assets/images/Bottom Cart.png',
                      observeCartBadge: true,
                    ),
                    _navItem(
                      index: HomeController.navChat,
                      label: 'Chat',
                      asset: null,
                    ),
                    _navItem(
                      index: HomeController.navProfile,
                      label: 'Profile',
                      asset: 'lib/assets/images/Bottom Profile.png',
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Centre of the bar's top edge is the centre of the disc
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _servicesDisc()),
          ),
        ],
      ),
    );
  }

  /// Labels stay English for the icon checks below; these keys are shown.
  static const _labelKeys = {
    'Home': 'core_nav_home',
    'Bookings': 'core_nav_bookings',
    'Orders': 'core_nav_orders',
    'Cart': 'core_nav_cart',
    'Chat': 'core_nav_chat',
    'Profile': 'core_nav_profile',
  };

  /// Icon above a label. Every item except Services has the same size and colour.
  Widget _navItem({
    required int index,
    required String label,
    required String? asset,
    bool observeCartBadge = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: _iconSlotTop),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _iconSize,
                child: observeCartBadge
                    ? Obx(() {
                        final controller = Get.isRegistered<HomeController>()
                            ? Get.find<HomeController>()
                            : Get.put(HomeController());
                        return _iconWithBadge(
                          label: label,
                          asset: asset,
                          badgeCount: controller.cartItemCount.value,
                        );
                      })
                    : _iconWithBadge(label: label, asset: asset, badgeCount: 0),
              ),
              const SizedBox(height: _labelGap),
              Text(
                _labelKeys[label]?.tr ?? label,
                style: GoogleFonts.outfit(
                  color: _inactive,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The raised disc sits in the notch; its label sits on the bar like the others.
  Widget _servicesItem() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(HomeController.navServices),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: _iconSlotTop),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: _iconSize),
              const SizedBox(height: _labelGap),
              Text(
                'core_nav_services'.tr,
                style: GoogleFonts.outfit(
                  color: _orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _servicesDisc() {
    return GestureDetector(
      onTap: () => _handleTap(HomeController.navServices),
      child: Container(
        width: _servicesDiscSize,
        height: _servicesDiscSize,
        decoration: BoxDecoration(
          color: _orange,
          shape: BoxShape.circle,
          border: Border.all(color: _barColor, width: _servicesBorder),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const _ServicesGridIcon(
          color: Colors.white,
          size: 24,
          outlined: true,
        ),
      ),
    );
  }

  Widget _iconWithBadge({
    required String label,
    required String? asset,
    required int badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: _buildIcon(label: label, asset: asset, isSelected: false),
        ),
        if (badgeCount > 0)
          PositionedDirectional(
            top: -4,
            end: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _barColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$badgeCount',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIcon({
    required String label,
    required String? asset,
    required bool isSelected,
  }) {
    final color = isSelected ? Colors.white : _inactive;

    if (label == 'Chat') {
      return BottomChatIcon(
        key: ValueKey('chat-$isSelected'),
        size: _iconSize,
        color: color,
        strokeFactor: _iconStrokeFactor,
      );
    }
    if (label == 'Bookings') {
      return _BookingsCalendarIcon(
        key: ValueKey('bookings-$isSelected'),
        size: _iconSize,
        color: color,
        strokeFactor: _iconStrokeFactor,
      );
    }
    return Image.asset(
      asset!,
      key: ValueKey('$label-$isSelected'),
      width: _iconSize,
      height: _iconSize,
      fit: BoxFit.contain,
      color: color,
      filterQuality: FilterQuality.high,
    );
  }
}

/// White bar with a circular notch at the top centre, drawn with a soft shadow.
class _NavBarPainter extends CustomPainter {
  final Color color;
  final double notchRadius;
  final double bottomInset;

  const _NavBarPainter({
    required this.color,
    required this.notchRadius,
    required this.bottomInset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = notchRadius;
    // The notch arc spans from angle pi - a to a; the shoulders run from the flat
    // bar edge into those two points, so the joins have no corners.
    const a = 0.7;
    const shoulder = 16.0;
    const handle = 12.0;
    final sinA = math.sin(a);
    final cosA = math.cos(a);
    final leftX = cx - r * cosA;
    final rightX = cx + r * cosA;
    final armY = r * sinA;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(cx - r - shoulder, 0)
      ..cubicTo(
        cx - r - shoulder / 2,
        0,
        leftX - handle * sinA,
        armY - handle * cosA,
        leftX,
        armY,
      )
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, 0), radius: r),
        math.pi - a,
        -(math.pi - 2 * a),
        false,
      )
      ..cubicTo(
        rightX + handle * sinA,
        armY - handle * cosA,
        cx + r + shoulder / 2,
        0,
        cx + r + shoulder,
        0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.25), 6, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NavBarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.bottomInset != bottomInset;
}

class _BookingsCalendarIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeFactor;

  const _BookingsCalendarIcon({
    super.key,
    required this.size,
    required this.color,
    this.strokeFactor = 0.075,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BookingsCalendarPainter(
          color: color,
          strokeFactor: strokeFactor,
        ),
      ),
    );
  }
}

class _BookingsCalendarPainter extends CustomPainter {
  final Color color;
  final double strokeFactor;

  _BookingsCalendarPainter({required this.color, required this.strokeFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * strokeFactor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.76, h * 0.68),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(body, stroke);

    canvas.drawLine(
      Offset(w * 0.12, h * 0.34),
      Offset(w * 0.88, h * 0.34),
      stroke,
    );

    canvas.drawLine(
      Offset(w * 0.32, h * 0.12),
      Offset(w * 0.32, h * 0.24),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.68, h * 0.12),
      Offset(w * 0.68, h * 0.24),
      stroke,
    );

    final dotR = w * 0.028;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(w * (0.28 + col * 0.18), h * (0.48 + row * 0.16)),
          dotR,
          fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BookingsCalendarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeFactor != strokeFactor;
  }
}

class _ServicesGridIcon extends StatelessWidget {
  final Color color;
  final double size;
  final bool outlined;

  const _ServicesGridIcon({
    required this.color,
    required this.size,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final cell = size * 0.38;
    final gap = size * 0.1;
    final stroke = size * 0.07;

    Widget square() {
      if (outlined) {
        return Container(
          width: cell,
          height: cell,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(color: color, width: stroke),
          ),
        );
      }
      return Container(
        width: cell,
        height: cell,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2.5),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              square(),
              SizedBox(width: gap),
              square(),
            ],
          ),
          SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              square(),
              SizedBox(width: gap),
              square(),
            ],
          ),
        ],
      ),
    );
  }
}
