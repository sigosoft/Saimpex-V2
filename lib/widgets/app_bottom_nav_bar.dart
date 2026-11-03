import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import 'bottom_chat_icon.dart';
import 'motion.dart';

import '../utils/app_fonts.dart';

/// Shared bottom navigation used by [MainShellScreen] and standalone pages.
///
/// A full-width white bar with a smooth dip around the raised Services button,
/// which sits in a pale orange ring. Each item is an icon with its name under
/// it (Services' name sits under the dip); the open tab's icon and name turn
/// orange.
/// Items press down and give haptics when tapped; the cart shows an orange
/// count badge.
class AppBottomNavBar extends StatelessWidget {
  static const double _barHeight = 68;
  static const double _iconSize = 22;
  static const double _iconStrokeFactor = 0.075;
  static const double _servicesDiscSize = 52;
  static const double _servicesRing = 7;

  /// Half the width of the dip, measured along the bar's top edge.
  static const double _notchHalfWidth = 60;
  static const double _notchDepth = 36;

  /// Tall enough for Cairo (Arabic), whose line is taller than Outfit's.
  static const double _labelHeight = 18;
  // Below this a slot doesn't grow for its name (English names all fit).
  static const double _minSlotWidth = 52;

  static const Color _barColor = Colors.white;
  static const Color _orange = Color(0xFFFF5216);
  static const Color _inactive = Color(0xFF3F3A40);

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

  /// The ringed disc rises this far above the bar's top edge.
  static const double _discOverhang = 32;

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
    final barHeight = _barHeight + bottomInset;

    return SizedBox(
      height: _discOverhang + barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: CustomPaint(
              painter: const _NavBarPainter(
                color: _barColor,
                notchHalfWidth: _notchHalfWidth,
                notchDepth: _notchDepth,
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

  static String _nameOf(String label) => _labelKeys[label]?.tr ?? label;

  /// Equal slots while every name fits one; a longer name ("Réservations",
  /// "Commandes") takes a wider slot instead of shrinking to an unreadable
  /// size. Names are measured bold, as on the open tab.
  static int _flexOf(String name) {
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: AppFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width + 4; // the name's side padding
    painter.dispose();
    return width < _minSlotWidth ? _minSlotWidth.round() : width.round();
  }

  /// Icon above its name; both turn orange on the open tab.
  Widget _navItem({
    required int index,
    required String label,
    required String? asset,
    bool observeCartBadge = false,
  }) {
    final isSelected = index == selectedIndex;
    final name = _nameOf(label);
    Widget icon(int badgeCount) => _iconWithBadge(
      label: label,
      asset: asset,
      badgeCount: badgeCount,
      isSelected: isSelected,
    );

    return Expanded(
      flex: _flexOf(name),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: name,
        excludeSemantics: true,
        child: Pressable(
          onTap: () => _handleTap(index),
          scale: 0.86,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: _iconSize,
                child: observeCartBadge
                    ? Obx(() {
                        final controller = Get.isRegistered<HomeController>()
                            ? Get.find<HomeController>()
                            : Get.put(HomeController());
                        return icon(controller.cartItemCount.value);
                      })
                    : icon(0),
              ),
              const SizedBox(height: 5),
              _name(name, isSelected),
            ],
          ),
        ),
      ),
    );
  }

  /// An item's name under its icon: orange and bold on the open tab. Long
  /// names ("Réservations") shrink to fit their slot, with a small gap so
  /// neighbours never run together.
  static Widget _name(String name, bool isSelected) {
    return SizedBox(
      height: _labelHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedDefaultTextStyle(
          duration: Motion.fast,
          curve: Motion.curve,
          style: AppFonts.outfit(
            color: isSelected ? _orange : _inactive,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name, maxLines: 1),
          ),
        ),
      ),
    );
  }

  /// The slot under the dip: the Services name, level with the other names
  /// (the disc above stands in for its icon).
  Widget _servicesItem() {
    final isSelected = selectedIndex == HomeController.navServices;
    return SizedBox(
      width: _notchHalfWidth * 2 - 16,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(HomeController.navServices),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: _iconSize + 5),
              _name('core_nav_services'.tr, isSelected),
            ],
          ),
        ),
      ),
    );
  }

  /// Solid orange disc in a pale orange ring, sitting in the dip.
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
        child: AnimatedContainer(
          duration: Motion.normal,
          curve: Motion.curve,
          width: _servicesDiscSize + _servicesRing * 2,
          height: _servicesDiscSize + _servicesRing * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _orange.withValues(alpha: isSelected ? 0.3 : 0.18),
          ),
          alignment: Alignment.center,
          child: Container(
            width: _servicesDiscSize,
            height: _servicesDiscSize,
            decoration: BoxDecoration(
              color: _orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _orange.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const _ServicesGridIcon(
              color: Colors.white,
              size: 22,
              outlined: true,
            ),
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

/// Full-width bar with a smooth dip at the top centre for the Services disc,
/// drawn with a soft shadow.
class _NavBarPainter extends CustomPainter {
  final Color color;
  final double notchHalfWidth;
  final double notchDepth;

  const _NavBarPainter({
    required this.color,
    required this.notchHalfWidth,
    required this.notchDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final w = notchHalfWidth;
    final d = notchDepth;

    // Each half of the dip is one S-shaped curve: flat where it leaves the top
    // edge, flat again at the bottom, so there are no corners.
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(cx - w, 0)
      ..cubicTo(cx - w * 0.5, 0, cx - w * 0.6, d, cx, d)
      ..cubicTo(cx + w * 0.6, d, cx + w * 0.5, 0, cx + w, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.2), 6, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NavBarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.notchHalfWidth != notchHalfWidth ||
      oldDelegate.notchDepth != notchDepth;
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
