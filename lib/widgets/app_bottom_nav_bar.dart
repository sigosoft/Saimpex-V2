import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import 'bottom_chat_icon.dart';

/// Shared floating bottom navigation used by [MainShellScreen] and standalone pages.
class AppBottomNavBar extends StatelessWidget {
  static const double _barHeight = 76;
  static const double _servicesFabSize = 58;
  static const double _servicesSlotWidth = 76;

  // Side items (Home, Chat, Bookings, Orders, Cart, Profile)
  static const double _sideIconBoxSize = 28;
  static const double _sideIconSize = 26;
  static const double _sideLabelFontSize = 11;
  static const double _sideLabelHeight = 14;
  static const double _sideDotSlotHeight = 7;
  static const double _sideIconGap = 5;
  static const double _sideDotSize = 5;
  static const double _iconStrokeFactor = 0.075;

  // Services FAB (label uses same slot metrics as side items)
  static const double _servicesGridIconSize = 24;

  double get _stackHeight => _barHeight + (_servicesFabSize / 2) + 4;

  final int selectedIndex;

  /// When set, called instead of default shell tab switching (for overlay routes).
  final ValueChanged<int>? onTap;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  void _handleTap(int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }
    final controller = Get.find<HomeController>();
    if (controller.currentNavIndex.value == index) return;
    controller.selectNavigation(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 2, right: 2, bottom: 10),
        child: SizedBox(
          height: _stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: Container(
                  clipBehavior: Clip.none,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _sideItem(
                          index: HomeController.navHome,
                          asset: 'lib/assets/images/Bottom Home.png',
                          label: 'Home',
                        ),
                      ),
                      Expanded(
                        child: _sideItem(
                          index: HomeController.navChat,
                          asset: null,
                          label: 'Chat',
                        ),
                      ),
                      Expanded(
                        child: _sideItem(
                          index: HomeController.navBookings,
                          asset: null,
                          label: 'Bookings',
                        ),
                      ),
                      SizedBox(
                        width: _servicesSlotWidth,
                        child: _servicesItem(),
                      ),
                      Expanded(
                        child: _sideItem(
                          index: HomeController.navOrders,
                          asset: 'lib/assets/images/Bottom Order.png',
                          label: 'Orders',
                        ),
                      ),
                      Expanded(
                        child: _sideItem(
                          index: HomeController.navCart,
                          asset: 'lib/assets/images/Bottom Cart.png',
                          label: 'Cart',
                          badgeCount: 2,
                        ),
                      ),
                      Expanded(
                        child: _sideItem(
                          index: HomeController.navProfile,
                          asset: 'lib/assets/images/Bottom Profile.png',
                          label: 'Profile',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _servicesItem() {
    final isSelected = selectedIndex == HomeController.navServices;

    return GestureDetector(
      onTap: () => _handleTap(HomeController.navServices),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _barHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: -_servicesFabSize / 2,
              child: Container(
                width: _servicesFabSize,
                height: _servicesFabSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const _ServicesGridIcon(
                  color: Colors.white,
                  size: _servicesGridIconSize,
                  outlined: true,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: _sideIconBoxSize,
                  height: _sideIconBoxSize,
                ),
                const SizedBox(height: _sideIconGap),
                SizedBox(
                  height: _sideLabelHeight,
                  child: Center(
                    child: isSelected
                        ? ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0xFFFF5E00),
                                Color(0xFFFFAE00),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'SERVICES',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: _sideLabelFontSize,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: 0.35,
                              ),
                            ),
                          )
                        : Text(
                            'SERVICES',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: _sideLabelFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: 0.35,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: _sideDotSlotHeight,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? _sideDotSize : 0,
                      height: isSelected ? _sideDotSize : 0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideItem({
    required int index,
    required String? asset,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;
    final color =
        isSelected ? const Color(0xFFFF5E00) : const Color(0xFFA59A94);

    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _barHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _sideIconBoxSize,
              height: _sideIconBoxSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _buildSideIcon(
                    label: label,
                    asset: asset,
                    color: color,
                    isSelected: isSelected,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -3,
                      right: -7,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: label == 'Cart'
                              ? const Color(0xFFE53935)
                              : const Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badgeCount',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: _sideIconGap),
            SizedBox(
              height: _sideLabelHeight,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: _sideLabelFontSize,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    height: 1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _sideDotSlotHeight,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? _sideDotSize : 0,
                  height: isSelected ? _sideDotSize : 0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5E00),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideIcon({
    required String label,
    required String? asset,
    required Color color,
    required bool isSelected,
  }) {
    if (label == 'Chat') {
      return BottomChatIcon(
        key: ValueKey('chat-$isSelected'),
        size: _sideIconSize,
        color: color,
        strokeFactor: _iconStrokeFactor,
      );
    }
    if (label == 'Bookings') {
      return _BookingsCalendarIcon(
        key: ValueKey('bookings-$isSelected'),
        size: _sideIconSize,
        color: color,
        strokeFactor: _iconStrokeFactor,
      );
    }
    return Image.asset(
      asset!,
      key: ValueKey('$label-$isSelected'),
      width: _sideIconSize,
      height: _sideIconSize,
      fit: BoxFit.contain,
      color: color,
      filterQuality: FilterQuality.high,
    );
  }
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

  _BookingsCalendarPainter({
    required this.color,
    required this.strokeFactor,
  });

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
          Offset(
            w * (0.28 + col * 0.18),
            h * (0.48 + row * 0.16),
          ),
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
