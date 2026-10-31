import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';

import '../../controllers/select_location_controller.dart';
import '../widgets/coupons_sheet.dart';
import 'widgets/pharmacy_background.dart';
import '../../utils/wallet_balance.dart';

/// What the customer chose on [PrescriptionCheckoutScreen]. [paymentType] is
/// wallet (3) or online (2); the server doesn't take cash for prescriptions.
typedef PrescriptionCheckoutChoice = ({
  bool delivery,
  String paymentType,
  String couponCode,
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
  String scheduleText = 'Pick a delivery time';
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

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
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(onTap: () => Navigator.pop(context)),
                  ),
                  Text(
                    'Checkout',
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
                'From ${widget.pharmacyName}',
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
                'Delivery Type',
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
              const SizedBox(height: 10),
              _buildScheduleCard(),
              const SizedBox(height: 18),
              _buildSaveMoreHeader(),
              const SizedBox(height: 10),
              _buildCouponField(),
              const SizedBox(height: 18),
              Text(
                'Payment',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                index: 0,
                icon: Icons.account_balance_wallet_outlined,
                title: 'SAIMPEX Wallet',
                subtitle: walletBalanceSubtitle(),
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                index: 1,
                icon: Icons.credit_card_rounded,
                title: 'Online payment',
                subtitle: 'Card • Mobile money',
              ),
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
        alignment: Alignment.centerLeft,
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
            hintText: '+ Add delivery note (Optional)',
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
            title: 'Delivery',
            subtitle: '30-35 min',
            onTap: () => setState(() => isDelivery = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _deliveryTypeCard(
            selected: !isDelivery,
            title: 'Self Pickup',
            subtitle: 'Ready in 15 min',
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
            'Edit',
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

  Widget _buildScheduleCard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          scheduleText = isDelivery
              ? 'Tomorrow, 10:00 - 11:00 AM'
              : 'Tomorrow, 4:00 - 5:00 PM';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled: $scheduleText',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF00B25C),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFCEF5DA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF00B25C),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule for later',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0E5A2A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheduleText,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF3BA162),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF00B25C),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveMoreHeader() {
    return Row(
      children: [
        Text(
          'Save More',
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
            'View Coupons',
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
                hintText: 'Enter coupon',
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
            'QUOTATION SUMMARY',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow('Item total', '$_itemTotal MRU'),
          const SizedBox(height: 10),
          Text(
            'Any delivery fee and coupon discount are worked out when you '
            'pay.',
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
                'To Pay',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$_toPay MRU',
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
    return GestureDetector(
      onTap: () => Navigator.pop<PrescriptionCheckoutChoice>(context, (
        delivery: isDelivery,
        paymentType: selectedPaymentIndex == 0
            ? paymentTypeWallet
            : paymentTypeOnline,
        couponCode: _couponController.text.trim(),
      )),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
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
          'Pay $_toPay MRU',
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
