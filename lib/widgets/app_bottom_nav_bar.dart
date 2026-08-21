import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import 'bottom_chat_icon.dart';

/// Shared floating bottom navigation used by [MainShellScreen] and standalone pages.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  /// When set, called instead of default shell tab switching (for overlay routes).
  final ValueChanged<int>? onTap;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(
              index: 0,
              asset: 'lib/assets/images/Bottom Home.png',
              label: 'Home',
            ),
            _item(index: 1, asset: null, label: 'Chat'),
            _item(
              index: 2,
              asset: 'lib/assets/images/Bottom Order.png',
              label: 'Orders',
            ),
            _item(
              index: 3,
              asset: 'lib/assets/images/Bottom Cart.png',
              label: 'Cart',
              badgeCount: 2,
            ),
            _item(
              index: 4,
              asset: 'lib/assets/images/Bottom Profile.png',
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required int index,
    required String? asset,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;
    final color =
        isSelected ? const Color(0xFFFF5E00) : const Color(0xFFA59A94);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(index);
          return;
        }
        final controller = Get.find<HomeController>();
        if (controller.currentNavIndex.value == index) return;
        controller.selectNavigation(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: label == 'Chat'
                      ? BottomChatIcon(
                          key: ValueKey('chat-$isSelected'),
                          size: 22,
                          color: color,
                        )
                      : Image.asset(
                          asset!,
                          key: ValueKey('$label-$isSelected'),
                          width: 22,
                          height: 22,
                          color: color,
                        ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
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
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
