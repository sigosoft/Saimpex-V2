import 'package:get/get.dart';

import '../controllers/home_controller.dart';

/// For screens pushed above [MainShellScreen] (e.g. pharmacy → cart).
/// Pops back to the shell and selects the tab — no heavy route rebuild.
class BottomNavRouter {
  static void go(int index) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    controller.selectNavigation(index);

    if (Get.key.currentState?.canPop() == true) {
      Get.until((route) => route.isFirst);
    }
  }
}
