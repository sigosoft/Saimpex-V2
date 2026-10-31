import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/wallet_repository.dart';
import '../../models/water_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/payment_page.dart';
import '../../utils/toast_helper.dart';
import '../../utils/wallet_balance.dart';
import '../../widgets/app_back_button.dart';

import 'water_subscription_success_screen.dart';

/// Review and buy a water subscription (water/subscribe): plan price ×
/// quantity, paid in cash on the first delivery, online (Masrvi) or from the
/// wallet. Success shows only once an online payment is confirmed.
class WaterSubscriptionCartScreen extends StatefulWidget {
  final int planId;
  final String storeName;
  final String itemName;
  final String itemSize;
  final String itemImage;
  final int pricePerDelivery;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final String startDateLabel;
  final String endDateLabel;
  final String timeSlot;
  final String subscriptionType;

  const WaterSubscriptionCartScreen({
    super.key,
    required this.planId,
    required this.storeName,
    required this.itemName,
    required this.itemSize,
    required this.itemImage,
    required this.pricePerDelivery,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.timeSlot,
    required this.subscriptionType,
  });

  @override
  State<WaterSubscriptionCartScreen> createState() =>
      _WaterSubscriptionCartScreenState();
}

class _WaterSubscriptionCartScreenState
    extends State<WaterSubscriptionCartScreen> {
  late int quantity;
  bool _submitting = false;
  // 1 cash on the first delivery (the server's default), 2 online, 3 wallet.
  String _paymentType = paymentTypeCash;
  // An online subscription created but not paid yet: paying again reopens
  // its payment page instead of buying a second subscription.
  ({String url, int topUpId})? _pendingPayment;

  @override
  void initState() {
    super.initState();
    quantity = widget.quantity < 1 ? 1 : widget.quantity.clamp(1, 50);
  }

  int get _total => widget.pricePerDelivery * quantity;

  /// Opens the payment page and waits for the server to confirm it.
  Future<void> _payOnline(String url, int topUpId) async {
    _pendingPayment = (url: url, topUpId: topUpId);
    await openPaymentPage(url);
    if (!mounted) return;
    var status = 'pending';
    for (var attempt = 0; attempt < 5; attempt++) {
      final data = await Get.find<WalletRepository>().topUpStatus(
        topUpId: topUpId,
        language: apiLanguageCode(),
      );
      status = '${data['status'] ?? 'pending'}';
      if (status != 'pending') break;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;
    if (status == 'paid') {
      _pendingPayment = null;
      Get.off(() => const WaterSubscriptionSuccessScreen());
      return;
    }
    showAppToast(
      status == 'failed'
          ? 'water_sub_payment_failed'.tr
          : 'water_sub_payment_pending'.tr,
      backgroundColor: const Color(0xFFEF4444),
    );
  }

  String get _address {
    final subtitle = SelectLocationController.selectedSubtitle.trim();
    return subtitle.isEmpty
        ? SelectLocationController.deliveryLabel.value
        : subtitle;
  }

  Future<void> _subscribe() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final pending = _pendingPayment;
      if (pending != null) {
        await _payOnline(pending.url, pending.topUpId);
        return;
      }
      final result = await Get.find<WaterRepository>().subscribe(
        planId: widget.planId,
        quantity: quantity,
        startDate: widget.startDate,
        endDate: widget.endDate,
        deliverySlot: widget.timeSlot,
        address: _address,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        paymentType: _paymentType,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      if (result.message.isNotEmpty) {
        showAppToast(result.message, backgroundColor: const Color(0xFFFF5E00));
      }
      final data = result.data;
      final needsPayment =
          data['payment_required'] == true || data['payment_required'] == 1;
      if (_paymentType == paymentTypeOnline && needsPayment) {
        final url = paymentPageUrl(data['payment_url']);
        final topUpId = int.tryParse('${data['topup_id'] ?? ''}');
        if (url == null || topUpId == null) {
          showAppToast(
            'payment_page_failed'.tr,
            backgroundColor: const Color(0xFFEF4444),
          );
          return;
        }
        await _payOnline(url, topUpId);
        return;
      }
      Get.off(() => const WaterSubscriptionSuccessScreen());
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFFBF5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        body: Column(
          children: [
            _buildHeader(),
            if (widget.storeName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'From ${widget.storeName}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7E75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductCard(),
                    const SizedBox(height: 18),
                    _buildSubscriptionDetails(),
                    const SizedBox(height: 14),
                    _buildAddressCard(),
                    const SizedBox(height: 18),
                    _buildPaymentOptions(),
                    const SizedBox(height: 6),
                    _buildPaymentDetails(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: _subscribe,
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF5E00,
                          ).withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            _paymentType == paymentTypeCash
                                ? 'water_sub_subscribe'.tr
                                : 'water_sub_pay'.trParams({
                                    'amount': '$_total',
                                  }),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        8,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'Subscription',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    final image = widget.itemImage;
    final isAsset = !image.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFEAF6FB),
              child: isAsset
                  ? Image.asset(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.water_drop_outlined,
                        color: Color(0xFF2E9FE6),
                      ),
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.water_drop_outlined,
                        color: Color(0xFF2E9FE6),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.itemSize.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.itemSize,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${widget.pricePerDelivery} MRU / delivery',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (quantity > 1 && _pendingPayment == null) {
                      setState(() => quantity--);
                    }
                  },
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.remove,
                      color: Color(0xFF2C2520),
                      size: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  // The server takes 1–50.
                  onTap: () {
                    if (quantity < 50 && _pendingPayment == null) {
                      setState(() => quantity++);
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5E00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Subscription Details',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Get.back(),
              child: Text(
                'Edit',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _detailBox(
                      label: 'Start Date',
                      value: widget.startDateLabel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailBox(
                      label: 'End Date',
                      value: widget.endDateLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _detailBox(
                      label: 'Time Slot',
                      value: widget.timeSlot,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _detailBox(
                      label: 'Type',
                      value: widget.subscriptionType,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailBox({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5E00),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deliver to',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _payRow('water_sub_plan_price'.tr, '${widget.pricePerDelivery} MRU'),
          const SizedBox(height: 10),
          _payRow('water_sub_quantity'.tr, '$quantity'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFF3A434E), height: 1),
          ),
          _payRow('water_sub_total'.tr, '$_total MRU'),
          const SizedBox(height: 10),
          Text(
            switch (_paymentType) {
              paymentTypeOnline => 'water_sub_note_online'.tr,
              paymentTypeWallet => 'water_sub_note_wallet'.tr,
              _ => 'water_sub_note_cash'.tr,
            },
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    Widget option(String type, IconData icon, String title, String subtitle) {
      final selected = _paymentType == type;
      return GestureDetector(
        // The subscription is already created once an online payment starts.
        onTap: _pendingPayment != null
            ? null
            : () => setState(() => _paymentType = type),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? const Color(0xFFFF5E00) : Colors.transparent,
              width: selected ? 1.4 : 0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0EA),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFF5E00), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFFD9D1C9),
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'water_sub_payment'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        option(
          paymentTypeCash,
          Icons.payments_outlined,
          'water_sub_pay_cash'.tr,
          'water_sub_pay_cash_hint'.tr,
        ),
        option(
          paymentTypeOnline,
          Icons.credit_card_outlined,
          'water_sub_pay_online'.tr,
          'Card • Mobile money',
        ),
        option(
          paymentTypeWallet,
          Icons.account_balance_wallet_outlined,
          'wallet_title'.tr,
          walletBalanceSubtitle(),
        ),
      ],
    );
  }

  Widget _payRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
