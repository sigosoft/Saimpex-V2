import 'package:get/get.dart';

import '../controllers/home_controller.dart';

/// Payment type the API takes for each payment option.
const paymentTypeCash = '1';
const paymentTypeOnline = '2';
const paymentTypeWallet = '3';

/// Pay After Delivery: only offered when `customer/payAfterDelivery` says
/// `can_use`. The driver collects nothing; the customer pays later.
const paymentTypePayAfterDelivery = '4';

/// "Balance: 1,250 MRU" under the SAIMPEX Wallet payment option, from the
/// balance the home screen loads; "Balance: —" until it has loaded.
String walletBalanceSubtitle() {
  if (!Get.isRegistered<HomeController>()) return 'Balance: —';
  final label = Get.find<HomeController>().walletLabel.trim();
  return label.isEmpty ? 'Balance: —' : 'Balance: $label';
}
