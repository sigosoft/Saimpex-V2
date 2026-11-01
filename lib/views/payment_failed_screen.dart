import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import '../utils/api_language.dart';
import '../utils/app_fonts.dart';
import '../utils/payment_methods.dart';
import '../utils/toast_helper.dart';
import '../utils/wallet_balance.dart';
import '../widgets/app_back_button.dart';

/// What the customer chose on [PaymentFailedScreen].
enum PaymentFailedChoice { retry, placed }

/// "Payment not completed" (Figma V2 Additions → Payment Failed). The online
/// order waits for payment: try Masrvi again, or pay by wallet / cash instead
/// (`customer/orders/{id}/switchPayment`, API §6.59).
class PaymentFailedScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final String amount;
  final bool cashAllowed;

  const PaymentFailedScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.amount,
    this.cashAllowed = true,
  });

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
  static const _orange = Color(0xFFFF5216);
  String? _busy;

  Future<void> _switch(String method) async {
    if (_busy != null) return;
    setState(() => _busy = method);
    try {
      final message = await Get.find<OrderRepository>().switchPayment(
        orderId: widget.orderId,
        method: method,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      if (message.isNotEmpty) showAppToast(message);
      Get.back(result: PaymentFailedChoice.placed);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _row(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: AppFonts.outfit(
            color: color ?? const Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _outlined(String label, String method) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _busy == null ? () => _switch(method) : null,
      child: _busy == method
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
            )
          : Text(
              label,
              style: AppFonts.outfit(
                color: _orange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final balance = walletBalanceSubtitle().replaceFirst('Balance: ', '');
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: AppBackButton(onTap: () => Get.back()),
        ),
        centerTitle: true,
        title: Text(
          'orders_pf_title'.tr,
          style: AppFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E8),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '!',
                  style: AppFonts.outfit(
                    color: const Color(0xFFE11D48),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'orders_pf_heading'.tr,
                textAlign: TextAlign.center,
                style: AppFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'orders_pf_body'.trParams({'code': widget.orderCode}),
                textAlign: TextAlign.center,
                style: AppFonts.outfit(
                  color: const Color(0xFF7A6A60),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEAD8C9)),
                ),
                child: Column(
                  children: [
                    _row('orders_pf_order'.tr, '#${widget.orderCode}'),
                    _row('orders_pf_amount'.tr, widget.amount),
                    _row(
                      'orders_pf_status'.tr,
                      'orders_pf_pending'.tr,
                      color: const Color(0xFFF97316),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy == null
                      ? () => Get.back(result: PaymentFailedChoice.retry)
                      : null,
                  child: Text(
                    'orders_pf_try_again'.tr,
                    style: AppFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (widget.cashAllowed &&
                  PaymentMethods.isOn(paymentTypeCash)) ...[
                const SizedBox(height: 12),
                _outlined('orders_pf_cash'.tr, 'cash'),
              ],
              if (PaymentMethods.isOn(paymentTypeWallet)) ...[
                const SizedBox(height: 12),
                _outlined(
                  'orders_pf_wallet'.trParams({'balance': balance}),
                  'wallet',
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'orders_pf_note'.tr,
                textAlign: TextAlign.center,
                style: AppFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
