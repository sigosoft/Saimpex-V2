import 'package:get/get.dart';

import '../controllers/home_controller.dart';

/// Payment type the API takes for each payment option.
const paymentTypeCash = '1';
const paymentTypeOnline = '2';
const paymentTypeWallet = '3';

/// Pay After Delivery: only offered when `customer/payAfterDelivery` says
/// `can_use`. The driver collects nothing; the customer pays later.
const paymentTypePayAfterDelivery = '4';

/// The wallet balance the home screen loads ("1,250 MRU"); "—" until loaded.
String walletBalanceAmount() {
  if (!Get.isRegistered<HomeController>()) return '—';
  final label = Get.find<HomeController>().walletLabel.trim();
  return label.isEmpty ? '—' : label;
}

/// "Balance: 1,250 MRU" under the SAIMPEX Wallet payment option, in the app
/// language.
String walletBalanceSubtitle() => 'core_account_wallet_balance'.trParams({
  'amount': walletBalanceAmount(),
});
