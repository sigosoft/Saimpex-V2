import 'package:get/get.dart';

import '../controllers/home_controller.dart';

/// The wallet chip on vertical home headers: the customer's real SAIMPEX
/// Wallet balance (loaded with home), or 0 MRU for guests / before it loads.
String walletChipText() {
  final label = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>().walletLabel.trim()
      : '';
  return label.isEmpty ? 'mru'.trParams({'amount': '0'}) : label;
}
