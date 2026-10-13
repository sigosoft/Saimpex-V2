import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../core/storage/session_store.dart';
import '../models/profile_repository.dart';
import '../utils/api_language.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'account_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'my_bookings_screen.dart';
import 'my_orders_screen.dart';
import 'services/services_screen.dart';

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

class _MainShellScreenState extends State<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late final HomeController _controller;
  late final AnimationController _tabAnim;
  late final CurvedAnimation _tabCurve;
  Worker? _navWorker;
  int _from = HomeController.navHome;
  int _to = HomeController.navHome;

  static const _pages = <Widget>[
    HomeScreen(showBottomNav: false),
    MessagesScreen(showBottomNav: false),
    MyBookingsScreen(showBottomNav: false),
    ServicesScreen(showBottomNav: false),
    MyOrdersScreen(showBottomNav: false),
    CartScreen(showBottomNav: false),
    AccountScreen(showBottomNav: false),
  ];

  /// Left-to-right order of the bottom bar, used so slides follow the tap.
  static const _visualOrder = <int>[
    HomeController.navHome,
    HomeController.navBookings,
    HomeController.navOrders,
    HomeController.navServices,
    HomeController.navCart,
    HomeController.navChat,
    HomeController.navProfile,
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HomeController(), permanent: true);
    _tabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _tabCurve = CurvedAnimation(
      parent: _tabAnim,
      curve: Curves.easeInOutCubic,
    );
    _tabAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed && _from != _to && mounted) {
        setState(() => _from = _to);
      }
    });

    if (widget.initialOrdersCategoryIndex != null) {
      _controller.pendingOrdersCategoryIndex.value =
          widget.initialOrdersCategoryIndex!;
    }
    if (widget.initialTabIndex != null) {
      _controller.selectNavigation(widget.initialTabIndex!);
    }
    final initial = _controller.currentNavIndex.value.clamp(
      0,
      HomeController.navMaxIndex,
    );
    _from = initial;
    _to = initial;

    _navWorker = ever<int>(_controller.currentNavIndex, _onNavIndex);
    unawaited(_loadSavedProfile());
  }

  Future<void> _loadSavedProfile() async {
    if (!Get.isRegistered<SessionStore>() ||
        !Get.isRegistered<ProfileRepository>()) {
      return;
    }
    final session = Get.find<SessionStore>();
    final token = session.token;
    if (token == null || token.isEmpty) return;

    try {
      final profile = await Get.find<ProfileRepository>().fetchProfile(
        apiLanguageCode(),
      );
      final currentToken = session.token;
      if (!mounted || currentToken == null || currentToken.isEmpty) return;
      await session.saveSession(
        token: currentToken,
        user: profile.mergedWith(session.readUser()),
      );
    } catch (_) {}
  }

  void _onNavIndex(int index) {
    final next = index.clamp(0, HomeController.navMaxIndex);
    if (next == _to) return;
    setState(() {
      _from = _to;
      _to = next;
    });
    _tabAnim.forward(from: 0);
  }

  int _visualPosition(int index) {
    final position = _visualOrder.indexOf(index);
    return position < 0 ? index : position;
  }

  @override
  void dispose() {
    _navWorker?.dispose();
    _tabCurve.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.find<SessionStore>().isLoggedIn.value) {
        return const LoginScreen();
      }
      return _buildShell(context);
    });
  }

  Widget _buildShell(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_controller.currentNavIndex.value != HomeController.navHome) {
          _controller.selectNavigation(HomeController.navHome);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Stack(
          children: [
            Positioned.fill(child: _buildPages()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Obx(
                () => AppBottomNavBar(
                  selectedIndex: _controller.currentNavIndex.value.clamp(
                    0,
                    HomeController.navMaxIndex,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPages() {
    final direction =
        _visualPosition(_to) >= _visualPosition(_from) ? 1.0 : -1.0;
    final animating = _from != _to;

    return AnimatedBuilder(
      animation: _tabCurve,
      builder: (context, _) {
        final t = animating ? _tabCurve.value : 1.0;
        final width = MediaQuery.sizeOf(context).width;
        return Stack(
          children: [
            for (var index = 0; index < _pages.length; index++)
              Offstage(
                offstage: index != _to && !(animating && index == _from),
                child: IgnorePointer(
                  ignoring: index != _to,
                  child: _movedPage(
                    page: _pages[index],
                    incoming: index == _to,
                    animating: animating && (index == _to || index == _from),
                    t: t,
                    direction: direction,
                    width: width,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _movedPage({
    required Widget page,
    required bool incoming,
    required bool animating,
    required double t,
    required double direction,
    required double width,
  }) {
    final dx = !animating
        ? 0.0
        : incoming
        ? (1 - t) * direction * width
        : -t * direction * width;
    final opacity = !animating ? 1.0 : (incoming ? 1.0 : (1 - t));

    return Opacity(
      opacity: opacity,
      child: Transform.translate(offset: Offset(dx, 0), child: page),
    );
  }
}
