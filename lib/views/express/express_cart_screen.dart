import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saimpex_v2/controllers/home_controller.dart';

import '../order_success_screen.dart';

class ExpressCartScreen extends StatefulWidget {
  final String? storeName;
  final String? itemName;
  final String? itemPortion;
  final int? basePrice;
  final String? itemImage;

  const ExpressCartScreen({
    super.key,
    this.storeName,
    this.itemName,
    this.itemPortion,
    this.basePrice,
    this.itemImage,
  });

  @override
  State<ExpressCartScreen> createState() => _ExpressCartScreenState();
}

class _ExpressCartScreenState extends State<ExpressCartScreen> {
  int quantity = 0;
  bool usePoints = false;
  int? selectedPaymentIndex;
  final int redeemedPointsDiscount = 1;
  final int expressDeliveryFee = 15;
  final int tax = 2;
  final TextEditingController _customQuantityController =
      TextEditingController();
  bool _syncingQuantityField = false;

  String get storeName => widget.storeName ?? 'Freshmart';

  String get itemTitle {
    final raw = widget.itemName ?? 'Potato 1Kg';
    return raw.replaceAll(RegExp(r'\s*\d+\s*[kKgGlL]+'), '').trim();
  }

  String get itemPortion =>
      widget.itemPortion ??
      RegExp(r'\d+\s*[kKgGlL]+').firstMatch(widget.itemName ?? '')?.group(0) ??
      '1 Kg';

  int get basePrice => widget.basePrice ?? 50;

  String get itemImage =>
      widget.itemImage ??
      'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=350&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();
    quantity = (widget.itemName != null || widget.storeName != null) ? 1 : 0;
    _syncHomeCartBadgeCount(quantity);
  }

  @override
  void dispose() {
    _customQuantityController.dispose();
    super.dispose();
  }

  void _onCustomQuantityChanged(String value) {
    if (_syncingQuantityField) return;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final parsed = int.tryParse(trimmed);
    if (parsed != null && parsed >= 0 && parsed != quantity) {
      setState(() => quantity = parsed);
      _syncHomeCartBadgeCount(parsed);
    }
  }

  void _setQuantity(int value) {
    final next = value < 0 ? 0 : value;
    setState(() => quantity = next);
    _syncHomeCartBadgeCount(next);

    _syncingQuantityField = true;
    _customQuantityController.value = TextEditingValue(
      text: next.toString(),
      selection: TextSelection.collapsed(offset: next.toString().length),
    );
    _syncingQuantityField = false;
  }

  void _syncHomeCartBadgeCount(int count) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().updateCartItemCount(count);
      }
    });
  }

  int get itemTotal => basePrice * quantity;

  int get pointsOff => usePoints ? 50 : 0;

  int get toPay {
    if (quantity == 0) return 0;
    final total =
        itemTotal -
        redeemedPointsDiscount -
        pointsOff +
        expressDeliveryFee +
        tax;
    return total < 0 ? 0 : total;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFFFDF9),
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEAD8C9),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFFF5E00),
                        size: 15,
                      ),
                    ),
                  ),
                ),
                Text(
                  'Cart',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quantity > 0) ...[
                    Text(
                      'From $storeName',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildItemCard(),
                  if (quantity > 0) ...[
                    const SizedBox(height: 14),
                    _buildDeliveryNote(),
                    const SizedBox(height: 18),
                    Text(
                      'Delivery Type',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildExpressDeliveryCard(),
                    const SizedBox(height: 14),
                    _buildAddressCard(),
                    const SizedBox(height: 18),
                    _buildSaveMoreSection(),
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
                      subtitle: 'Balance: 2,450 MRU',
                    ),
                    _buildPaymentOption(
                      index: 1,
                      icon: Icons.credit_card_outlined,
                      title: 'Online payment',
                      subtitle: 'Card • Mobile money',
                    ),
                    _buildPaymentOption(
                      index: 2,
                      icon: Icons.monetization_on_outlined,
                      title: 'Cash on Delivery',
                      subtitle: 'Pay the SAIMPEX driver',
                    ),
                    const SizedBox(height: 14),
                    _buildPaymentDetails(),
                    const SizedBox(height: 20),
                    _buildPayButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard() {
    if (quantity == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFFA59A94),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your cart is empty',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _setQuantity(1),
              child: Text(
                'Add Product',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  itemImage,
                  width: 74,
                  height: 74,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 74,
                    height: 74,
                    color: const Color(0xFFF3EFEA),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
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
                      itemTitle.isEmpty ? 'Potato' : itemTitle,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itemPortion,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$itemTotal MRU',
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
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (quantity > 0) _setQuantity(quantity - 1);
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Color(0xFFFF5E00),
                          size: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quantity.toString(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _setQuantity(quantity + 1),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: _customQuantityController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF2C2520),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Customize your quantity here',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onCustomQuantityChanged,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNote() {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0xFFD9D0C8),
        borderRadius: 20,
      ),
      child: Container(
        height: 40,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.add, color: Color(0xFFA59A94), size: 14),
            const SizedBox(width: 6),
            Text(
              'Add delivery note (Optional)',
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressDeliveryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF5E00), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF5E00), width: 1.5),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.bolt_rounded, color: Color(0xFFFF5E00), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  const TextSpan(text: 'Express Delivery'),
                  TextSpan(
                    text: ' • ',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: 'Estimated delivery 15–20 min',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_outlined,
              color: Color(0xFFFF5E00),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sahara View Home',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Near Marhaba Supermarket, Nouakchott',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 10,
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
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveMoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Save More',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'View Coupons',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF2C2520),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter coupon',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Text(
                'Apply',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => usePoints = !usePoints),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/images/Coin.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF0EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monetization_on_outlined,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use 500 points',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '= 50 MRU off',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: usePoints
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFA59A94),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: usePoints
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5E00),
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedPaymentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => selectedPaymentIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEAD8C9),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF5E00), size: 16),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFA59A94),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2520),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _paymentRow('Item total', '$itemTotal MRU'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Redeemed points',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '-$redeemedPointsDiscount MRU',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (usePoints) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Points discount',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '-$pointsOff MRU',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _paymentRow('Express delivery fee', '$expressDeliveryFee MRU'),
          const SizedBox(height: 10),
          _paymentRow('Tax', '$tax MRU'),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF423B36), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To pay',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$toPay MRU',
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

  Widget _paymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: () {
        _syncHomeCartBadgeCount(0);
        Get.to(() => const OrderSuccessScreen());
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Pay $toPay MRU',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, this.borderRadius = 20});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    const dashLength = 4.0;
    const gap = 3.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final extract = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(extract, paint);
        distance += dashLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
