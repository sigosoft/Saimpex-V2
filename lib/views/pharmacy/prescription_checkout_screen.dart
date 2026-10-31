import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';

import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/order_repository.dart';
import '../../utils/api_language.dart';
import '../widgets/coupons_sheet.dart';
import 'widgets/pharmacy_background.dart';
import '../../utils/wallet_balance.dart';

/// What the customer chose on [PrescriptionCheckoutScreen]. [paymentType] is
/// wallet (3) or online (2); the server doesn't take cash for prescriptions.
typedef PrescriptionCheckoutChoice = ({
  bool delivery,
  String paymentType,
  String couponCode,
  String note,
});

/// Last step before paying a quotation. Pops with a [PrescriptionCheckoutChoice].
class PrescriptionCheckoutScreen extends StatefulWidget {
  final String pharmacyName;
  final num quoteAmount;

  const PrescriptionCheckoutScreen({
    super.key,
    required this.pharmacyName,
    required this.quoteAmount,
  });

  @override
  State<PrescriptionCheckoutScreen> createState() =>
      _PrescriptionCheckoutScreenState();
}

class _PrescriptionCheckoutScreenState
    extends State<PrescriptionCheckoutScreen> {
  bool isDelivery = true;
  int selectedPaymentIndex = 0; // 0 wallet, 1 online
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  /// Payment types Admin has switched on; null until loaded. If the list can't
  /// be loaded both options stay, and the server refuses a disabled one.
  Set<String>? _enabledPaymentTypes;

  bool get _walletEnabled =>
      _enabledPaymentTypes?.contains(paymentTypeWallet) ?? true;
  bool get _onlineEnabled =>
      _enabledPaymentTypes?.contains(paymentTypeOnline) ?? true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    if (!Get.isRegistered<OrderRepository>()) return;
    try {
      final enabled = await Get.find<OrderRepository>().enabledPaymentTypes(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _enabledPaymentTypes = enabled;
        if (!_walletEnabled) selectedPaymentIndex = 1;
        if (!_onlineEnabled) selectedPaymentIndex = 0;
      });
    } on ApiException {
      // Keep both options; the server still checks the method on pay.
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  int get _itemTotal => widget.quoteAmount.round();

  /// The amount charged is the quote from the pharmacy.
  int get _toPay => _itemTotal;

  String get _addressTitle => SelectLocationController.deliveryLabel.value;

  String get _addressSubtitle {
    final subtitle = SelectLocationController.selectedSubtitle.trim();
    return subtitle.isEmpty ? _addressTitle : subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppBackButton(onTap: () => Navigator.pop(context)),
                  ),
                  Text(
                    'pw_checkout'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'pw_from_pharmacy'.trParams({'name': widget.pharmacyName}),
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (isDelivery) ...[
                _buildDeliveryNote(),
                const SizedBox(height: 18),
              ],
              Text(
                'pw_delivery_type'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _buildDeliveryTypeRow(),
              const SizedBox(height: 14),
              if (isDelivery)
                _buildAddressCard()
              else
                _buildPharmacyPickupCard(),
              const SizedBox(height: 18),
              _buildSaveMoreHeader(),
              const SizedBox(height: 10),
              _buildCouponField(),
              const SizedBox(height: 18),
              Text(
                'water_sub_payment'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_walletEnabled) ...[
                const SizedBox(height: 10),
                _buildPaymentOption(
                  index: 0,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'wallet_title'.tr,
                  subtitle: walletBalanceSubtitle(),
                ),
              ],
              if (_onlineEnabled) ...[
                const SizedBox(height: 10),
                _buildPaymentOption(
                  index: 1,
                  icon: Icons.credit_card_rounded,
                  title: 'water_sub_pay_online'.tr,
                  subtitle: 'pw_card_mobile_money'.tr,
                ),
              ],
              if (!_walletEnabled && !_onlineEnabled) ...[
                const SizedBox(height: 10),
                Text(
                  'pw_no_payment_method'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryNote() {
    return CustomPaint(
      painter: _DashedRRectPainter(color: const Color(0xFFD9D0C8), radius: 24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: AlignmentDirectional.centerStart,
        child: TextField(
          controller: _noteController,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'pw_add_delivery_note'.tr,
            hintStyle: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryTypeRow() {
    return Row(
      children: [
        Expanded(
          child: _deliveryTypeCard(
            selected: isDelivery,
            title: 'pw_delivery'.tr,
            subtitle: 'pw_30_35_min'.tr,
            onTap: () => setState(() => isDelivery = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _deliveryTypeCard(
            selected: !isDelivery,
            title: 'pw_self_pickup'.tr,
            subtitle: 'pw_ready_in_15'.tr,
            onTap: () {
              setState(() {
                isDelivery = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _deliveryTypeCard({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFFF5E00) : const Color(0xFFEAD8C9),
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            _radio(selected),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFFFF5E00) : const Color(0xFFA59A94),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: selected
          ? Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Color(0xFFFF5E00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _addressTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _addressSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'pw_edit'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyPickupCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Color(0xFFFF5E00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pharmacyName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.pharmacyName}, $_addressSubtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF5E00),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveMoreHeader() {
    return Row(
      children: [
        Text(
          'pw_save_more'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final code = await showCouponsSheet(context);
            if (code == null || !mounted) return;
            setState(() => _couponController.text = code);
          },
          child: Text(
            'pw_view_coupons'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            color: Color(0xFFFF5E00),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _couponController,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF2C2520),
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'pw_enter_coupon'.tr,
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFFF5E00) : const Color(0xFFEAD8C9),
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFF5E00), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _radio(selected),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pw_quotation_summary_caps'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow(
            'pw_item_total'.tr,
            'mru'.trParams({'amount': '$_itemTotal'}),
          ),
          const SizedBox(height: 10),
          Text(
            'pw_fees_worked_out_on_pay'.tr,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFF3A434E)),
          ),
          Row(
            children: [
              Text(
                'pw_to_pay'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'mru'.trParams({'amount': '$_toPay'}),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    final canPay = _walletEnabled || _onlineEnabled;
    return GestureDetector(
      onTap: !canPay
          ? null
          : () => Navigator.pop<PrescriptionCheckoutChoice>(context, (
              delivery: isDelivery,
              paymentType: selectedPaymentIndex == 0
                  ? paymentTypeWallet
                  : paymentTypeOnline,
              couponCode: _couponController.text.trim(),
              // The note field only shows for delivery.
              note: isDelivery ? _noteController.text.trim() : '',
            )),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canPay
                ? const [Color(0xFFFF5E00), Color(0xFFFFAE00)]
                : const [Color(0xFFD9D0C8), Color(0xFFD9D0C8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'water_sub_pay'.trParams({'amount': '$_toPay'}),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
