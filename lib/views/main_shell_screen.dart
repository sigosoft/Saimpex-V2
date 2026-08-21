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
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Obx(() {
      final index = controller.currentNavIndex.value.clamp(0, 4);

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
