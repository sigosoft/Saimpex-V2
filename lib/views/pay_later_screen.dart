import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import '../utils/api_language.dart';
import '../utils/payment_page.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';

/// The customer's unpaid Pay After Delivery orders (customer/payAfterDelivery),
/// each paid online or from the wallet once it is delivered.
/// Built without a Figma screen, in the app's checkout style.
class PayLaterScreen extends StatefulWidget {
  const PayLaterScreen({super.key});

  @override
  State<PayLaterScreen> createState() => _PayLaterScreenState();
}

class _PayLaterScreenState extends State<PayLaterScreen> {
  List<Map<String, dynamic>> _orders = const [];
  bool _loading = true;
  int? _payingOrderId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final status = await Get.find<OrderRepository>().payAfterDeliveryStatus(
        apiLanguageCode(),
      );
      final raw = status['unpaid_orders'];
      if (!mounted) return;
      setState(() {
        _orders = raw is List
            ? raw.whereType<Map>().map(Map<String, dynamic>.from).toList()
            : const [];
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pay(int orderId, String method) async {
    if (_payingOrderId != null) return;
    setState(() => _payingOrderId = orderId);
    try {
      final result = await Get.find<OrderRepository>().payAfterDeliveryPay(
        orderId: orderId,
        method: method,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      if (method == 'wallet') {
        showAppToast(
          '${result['message'] ?? ''}'.trim().isEmpty
              ? 'pad_paid'.tr
              : '${result['message']}',
          backgroundColor: const Color(0xFFFF5E00),
        );
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().walletBalance.value =
              '${result['balance'] ?? ''}';
        }
      } else {
        final url = paymentPageUrl(result['payment_url']);
        if (url == null) {
          showAppToast(
            'payment_page_failed'.tr,
            backgroundColor: const Color(0xFFEF4444),
          );
          return;
        }
        final paid = await openPaymentPage(url);
        if (!mounted) return;
        showAppToast(
          paid == true ? 'pad_paid'.tr : 'payment_not_completed'.tr,
          backgroundColor: paid == true
              ? const Color(0xFFFF5E00)
              : const Color(0xFFEF4444),
        );
      }
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _payingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackButton(onTap: () => Get.back()),
                  ),
                  Text(
                    'pad_title'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'pad_nothing_due'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8C7D73),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFFF5E00),
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildOrder(_orders[index]),
      ),
    );
  }

  Widget _buildOrder(Map<String, dynamic> order) {
    final orderId = int.tryParse('${order['order_id'] ?? ''}') ?? 0;
    final code = '${order['order_code'] ?? ''}'.trim();
    final amount = num.tryParse('${order['amount'] ?? ''}') ?? 0;
    final delivered = order['delivered'] == true || order['delivered'] == 1;
    final payBy = DateTime.tryParse('${order['pay_by'] ?? ''}')?.toLocal();
    final paying = _payingOrderId == orderId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  code.isEmpty ? '#$orderId' : code,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'mru'.trParams({'amount': _money(amount)}),
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            !delivered
                ? 'pad_after_delivery'.tr
                : payBy == null
                ? 'pad_due_now'.tr
                : 'pad_pay_by'.trParams({'time': _dateTime(payBy)}),
            style: GoogleFonts.outfit(
              color: delivered
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF8C7D73),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (delivered) ...[
            const SizedBox(height: 14),
            if (paying)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _button(
                      'pad_pay_wallet'.tr,
                      outlined: true,
                      onTap: () => _pay(orderId, 'wallet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _button(
                      'pad_pay_online'.tr,
                      onTap: () => _pay(orderId, 'online'),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _button(
    String label, {
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : null,
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                ),
          borderRadius: BorderRadius.circular(22),
          border: outlined
              ? Border.all(color: const Color(0xFFFF5E00), width: 1.3)
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: outlined ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  static String _money(num value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';

  static String _dateTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)} ${two(time.hour)}:${two(time.minute)}';
  }
}
