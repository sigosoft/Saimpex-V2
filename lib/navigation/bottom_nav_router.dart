import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../views/main_shell_screen.dart';

/// For screens pushed above [MainShellScreen] (e.g. pharmacy → cart).
/// Pops back to the shell and selects the tab — no heavy route rebuild.
class BottomNavRouter {
  static HomeController _controller() {
    return Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);
  }

  static void go(int index) {
    _controller().selectNavigation(index);

    if (Get.key.currentState?.canPop() == true) {
      Get.until((route) => route.isFirst);
    }
  }

  /// Returns to the existing shell when possible (avoids rebuilding all tabs).
  /// Falls back to [MainShellScreen] only when the shell is not in the stack.
  static void returnToShell({
    required int tabIndex,
    int? ordersCategoryIndex,
  }) {
    final controller = _controller();

    if (ordersCategoryIndex != null) {
      controller.goToOrdersTab(categoryIndex: ordersCategoryIndex);
    } else {
      controller.selectNavigation(tabIndex);
    }

    if (Get.key.currentState?.canPop() == true) {
      Get.until((route) => route.isFirst);
      return;
    }

    Get.offAll(
      () => MainShellScreen(
        initialTabIndex: tabIndex,
        initialOrdersCategoryIndex: ordersCategoryIndex,
      ),
    );
  }
}
