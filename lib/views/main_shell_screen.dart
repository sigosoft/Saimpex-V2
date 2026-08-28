import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'my_orders_screen.dart';

/// Root shell after login — keeps tabs alive and switches without route jank.
class MainShellScreen extends StatefulWidget {
  final int? initialTabIndex;
  final int? initialOrdersCategoryIndex;

  const MainShellScreen({
    super.key,
    this.initialTabIndex,
    this.initialOrdersCategoryIndex,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HomeController(), permanent: true);

    if (widget.initialOrdersCategoryIndex != null) {
      _controller.pendingOrdersCategoryIndex.value =
          widget.initialOrdersCategoryIndex!;
    }
    if (widget.initialTabIndex != null) {
      _controller.selectNavigation(widget.initialTabIndex!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = _controller.currentNavIndex.value.clamp(0, 4);

      return Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: index,
                children: const [
                  HomeScreen(showBottomNav: false),
                  MessagesScreen(showBottomNav: false),
                  MyOrdersScreen(showBottomNav: false),
                  CartScreen(showBottomNav: false),
                  AccountScreen(showBottomNav: false),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavBar(selectedIndex: index),
            ),
          ],
        ),
      );
    });
  }
}
