import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import 'bottom_chat_icon.dart';
import 'motion.dart';

import '../utils/app_fonts.dart';
/// Shared bottom navigation used by [MainShellScreen] and standalone pages.
///
/// A floating rounded bar, inset from the screen edges, with a smooth dip
/// around the raised Services button. Items are icons only (their names stay
/// for screen readers); the open tab's icon turns orange with a soft bubble and
/// two small sparkle dots. Items press down and give haptics when tapped; the
/// cart shows an orange count badge.
class AppBottomNavBar extends StatelessWidget {
  static const double _barHeight = 60;
  static const double _barRadius = 24;
  static const double _sideMargin = 16;
  static const double _bottomGap = 10;
  static const double _iconSize = 24;
  static const double _iconStrokeFactor = 0.075;
  static const double _servicesDiscSize = 56;

  /// Half the width of the dip, measured along the bar's top edge.
  static const double _notchHalfWidth = 58;
  static const double _notchDepth = 38;

  static const Color _barColor = Color(0xFFF8F8F8);
  static const Color _orange = Color(0xFFFF5216);
  static const Color _orangeLight = Color(0xFFFF8A3D);
  static const Color _inactive = Color(0xFF6E6A73);

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

  /// The disc rises this far above the bar's top edge.
  static const double _discOverhang = 30;

  void _handleTap(int index) {
    if (index == selectedIndex) {
      // Re-tapping the open tab: a soft tick (Home also reloads).
      HapticFeedback.selectionClick();
      if (index == HomeController.navHome &&
          Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadHome();
      }
      return;
    }
    // Light tap per tab; the raised Services button answers a little firmer.
    if (index == HomeController.navServices) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
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
    final bottom = _bottomGap + bottomInset;

    return SizedBox(
      height: _discOverhang + _barHeight + bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _sideMargin,
            right: _sideMargin,
            bottom: bottom,
            height: _barHeight,
            child: CustomPaint(
              painter: const _NavBarPainter(
                color: _barColor,
                radius: _barRadius,
                notchHalfWidth: _notchHalfWidth,
                notchDepth: _notchDepth,
                shadowColor: _orange,
              ),
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
                  // The dip: the Services disc above covers it.
                  const SizedBox(width: _notchHalfWidth * 2),
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

  /// Item names, read out by screen readers (the bar shows icons only).
  static const _labelKeys = {
    'Home': 'core_nav_home',
    'Bookings': 'core_nav_bookings',
    'Orders': 'core_nav_orders',
    'Cart': 'core_nav_cart',
    'Chat': 'core_nav_chat',
    'Profile': 'core_nav_profile',
  };

  /// An icon in the middle of its slot. The open tab's icon turns orange over a
  /// soft orange bubble, with two sparkle dots beside it.
  Widget _navItem({
    required int index,
    required String label,
    required String? asset,
    bool observeCartBadge = false,
  }) {
    final isSelected = index == selectedIndex;
    Widget icon(int badgeCount) => _iconWithBadge(
      label: label,
      asset: asset,
      badgeCount: badgeCount,
      isSelected: isSelected,
    );

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: _labelKeys[label]?.tr ?? label,
        excludeSemantics: true,
        child: Pressable(
          onTap: () => _handleTap(index),
          scale: 0.86,
          child: SizedBox(
            height: _barHeight,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Bubble, a little below and after the icon's centre.
                    PositionedDirectional(
                      top: 14,
                      start: 15,
                      child: _Pop(
                        visible: isSelected,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _orange.withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 9,
                      start: 0,
                      child: _Pop(visible: isSelected, child: _dot(5)),
                    ),
                    PositionedDirectional(
                      top: 20,
                      end: 0,
                      child: _Pop(visible: isSelected, child: _dot(3)),
                    ),
                    SizedBox(
                      height: _iconSize,
                      child: observeCartBadge
                          ? Obx(() {
                              final controller =
                                  Get.isRegistered<HomeController>()
                                  ? Get.find<HomeController>()
                                  : Get.put(HomeController());
                              return icon(controller.cartItemCount.value);
                            })
                          : icon(0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _dot(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
  );

  Widget _servicesDisc() {
    final isSelected = selectedIndex == HomeController.navServices;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'core_nav_services'.tr,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => _handleTap(HomeController.navServices),
        scale: 0.9,
        child: Container(
          width: _servicesDiscSize,
          height: _servicesDiscSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_orange, _orangeLight],
            ),
            boxShadow: [
              BoxShadow(
                color: _orange.withValues(alpha: isSelected ? 0.5 : 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
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
      ),
    );
  }

  Widget _iconWithBadge({
    required String label,
    required String? asset,
    required int badgeCount,
    required bool isSelected,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: _buildIcon(label: label, asset: asset, isSelected: isSelected),
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
                style: AppFonts.outfit(
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
    final color = isSelected ? _orange : _inactive;

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

/// Scales and fades the active tab's bubble and dots in and out.
class _Pop extends StatelessWidget {
  const _Pop({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: Motion.normal,
      curve: visible ? Curves.easeOutBack : Motion.curve,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Motion.fast,
        child: child,
      ),
    );
  }
}

/// Rounded bar with a smooth dip at the top centre for the Services disc,
/// drawn with a soft orange-tinted shadow.
class _NavBarPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double notchHalfWidth;
  final double notchDepth;
  final Color shadowColor;

  const _NavBarPainter({
    required this.color,
    required this.radius,
    required this.notchHalfWidth,
    required this.notchDepth,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final w = notchHalfWidth;
    final d = notchDepth;
    final r = radius;

    // Each half of the dip is one S-shaped curve: flat where it leaves the top
    // edge, flat again at the bottom, so there are no corners.
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(cx - w, 0)
      ..cubicTo(cx - w * 0.5, 0, cx - w * 0.6, d, cx, d)
      ..cubicTo(cx + w * 0.6, d, cx + w * 0.5, 0, cx + w, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..close();

    canvas.drawShadow(path, shadowColor.withValues(alpha: 0.35), 10, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NavBarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.notchHalfWidth != notchHalfWidth ||
      oldDelegate.notchDepth != notchDepth ||
      oldDelegate.shadowColor != shadowColor;
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
