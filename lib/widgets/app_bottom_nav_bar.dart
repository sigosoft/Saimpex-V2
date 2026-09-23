import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import 'bottom_chat_icon.dart';

/// Shared floating bottom navigation used by [MainShellScreen] and standalone pages.
///
/// App-themed pill bar: inactive items are muted circles; the selected item expands
/// into a peach capsule with an orange icon circle and label.
class AppBottomNavBar extends StatelessWidget {
  static const double _barHeight = 78;
  static const double _iconCircleSize = 34;
  static const double _iconSize = 18;
  static const double _iconStrokeFactor = 0.075;

  static const Color _outerBg = Color(0xFFFAF6F0);
  static const Color _barColor = Colors.white;
  static const Color _inactiveCircle = Color(0xFFFFF3EB);
  static const Color _activeCapsule = Color(0xFFFFE4CC);
  static const Color _orange = Color(0xFFFF5E00);
  static const Color _inactiveIcon = Color.fromARGB(255, 123, 123, 123);
  static const Color _activeLabel = Color(0xFF1A1A1A);

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
    return Container(
      width: double.infinity,
      color: _outerBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
          child: Container(
            width: double.infinity,
            height: _barHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: _barColor,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
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
                _navItem(
                  index: HomeController.navServices,
                  label: 'Services',
                  asset: null,
                ),
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
    );
  }

  Widget _navItem({
    required int index,
    required String label,
    required String? asset,
    bool observeCartBadge = false,
  }) {
    final isSelected = selectedIndex == index;

    final content = GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 4,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _activeCapsule : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isSelected ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (observeCartBadge)
              Obx(() {
                final controller = Get.isRegistered<HomeController>()
                    ? Get.find<HomeController>()
                    : Get.put(HomeController());
                return _iconWithBadge(
                  label: label,
                  asset: asset,
                  isSelected: isSelected,
                  badgeCount: controller.cartItemCount.value,
                );
              })
            else
              _iconWithBadge(
                label: label,
                asset: asset,
                isSelected: isSelected,
                badgeCount: 0,
              ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.outfit(
                      color: _activeLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Selected takes leftover width; inactive stays circle-sized only.
    if (isSelected) {
      return Expanded(child: content);
    }
    return content;
  }

  Widget _iconWithBadge({
    required String label,
    required String? asset,
    required bool isSelected,
    required int badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: _iconCircleSize,
          height: _iconCircleSize,
          decoration: BoxDecoration(
            color: isSelected ? _orange : _inactiveCircle,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: _buildIcon(
            label: label,
            asset: asset,
            isSelected: isSelected,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
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
    final color = isSelected ? Colors.white : _inactiveIcon;

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
    if (label == 'Services') {
      return _ServicesGridIcon(
        key: ValueKey('services-$isSelected'),
        color: color,
        size: _iconSize,
        outlined: true,
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
    super.key,
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
