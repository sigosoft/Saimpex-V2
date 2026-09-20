import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saimpex_v2/controllers/home_controller.dart';
import '../order_success_screen.dart';
import '../coupons_screen.dart';
import '../saved_addresses_screen.dart';

class LocalStoreCartScreen extends StatefulWidget {
  final Map<String, dynamic>? store;
  final Map<String, dynamic>? product;

  const LocalStoreCartScreen({super.key, this.store, this.product});

  @override
  State<LocalStoreCartScreen> createState() => _LocalStoreCartScreenState();
}

class _LocalStoreCartScreenState extends State<LocalStoreCartScreen> {
  bool _isSelfPickup = false;
  int _quantity = 0;
  bool _usePoints = false;
  int _selectedPaymentMethod = 0; // 0: Wallet, 1: Online, 2: COD

  final TextEditingController _customQuantityController =
      TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _deliveryNoteController = TextEditingController();
  bool _syncingQuantityField = false;

  static const double _cardRadius = 28;

  @override
  void initState() {
    super.initState();
    _quantity = (widget.product != null || widget.store != null) ? 1 : 0;
    _syncCustomQuantityField();
  }

  void _syncHomeCartBadgeCount(int count) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().updateCartItemCount(count);
      }
    });
  }

  void _syncCustomQuantityField() {
    _syncingQuantityField = true;
    _customQuantityController.value = TextEditingValue(
      text: _quantity.toString(),
      selection: TextSelection.collapsed(offset: _quantity.toString().length),
    );
    _syncingQuantityField = false;
    _syncHomeCartBadgeCount(_quantity);
  }

  void _onCustomQuantityChanged(String value) {
    if (_syncingQuantityField) return;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final parsed = int.tryParse(trimmed);
    if (parsed != null && parsed >= 0 && parsed != _quantity) {
      setState(() => _quantity = parsed);
      _syncHomeCartBadgeCount(parsed);
    }
  }

  void _setQuantity(int value) {
    final next = value < 0 ? 0 : value;
    setState(() => _quantity = next);
    _syncCustomQuantityField();
  }

  int get _unitPrice {
    final price = widget.product?['price'];
    if (price is num) return price.toInt();
    if (price is String) {
      return int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 50;
    }
    if (Get.isRegistered<HomeController>()) {
      final saved = Get.find<HomeController>().lastCartItem;
      final base = saved?['basePrice'];
      if (base is num) return base.toInt();
    }
    return 50;
  }

  String _resolveProductImage(String title, String? image) {
    if (image != null &&
        image.isNotEmpty &&
        (image.startsWith('lib/assets/') || image.startsWith('assets/'))) {
      return image;
    }
    final t = title.toLowerCase();
    if (t.contains('artisan')) return 'lib/assets/images/artisan_bread.png';
    if (t.contains('pain') || t.contains('chocolat')) {
      return 'lib/assets/images/pain_chocolat.png';
    }
    if (t.contains('citrus') || t.contains('lemon')) {
      return 'lib/assets/images/citrus_lemon.png';
    }
    return 'lib/assets/images/butter_croissant.png';
  }

  Widget _cartImageFallback() {
    return Container(
      color: const Color(0xFFF3E7DC),
      child: const Icon(
        Icons.fastfood_rounded,
        color: Color(0xFFFF5E00),
        size: 30,
      ),
    );
  }

  @override
  void dispose() {
    _customQuantityController.dispose();
    _couponController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final saved = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().lastCartItem
        : null;

    final storeName = widget.store?['name']?.toString() ??
        saved?['storeName']?.toString() ??
        'Golden Bakery';
    final productTitle = widget.product?['title']?.toString() ??
        saved?['itemName']?.toString() ??
        'Butter Croissant';
    final productImage = _resolveProductImage(
      productTitle,
      widget.product?['image']?.toString() ??
          saved?['itemImage']?.toString(),
    );

    final int itemTotal = _unitPrice * _quantity;
    final int redeemedPoints = (_usePoints && _quantity > 0) ? 1 : 0;
    final int deliveryFee = (_isSelfPickup || _quantity == 0) ? 0 : 5;
    final int tax = _quantity > 0 ? 2 : 0;
    final int rawTotal = itemTotal - redeemedPoints + deliveryFee + tax;
    final int grandTotal = (_quantity == 0 || rawTotal < 0) ? 0 : rawTotal;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF7F2),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F2),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 0),
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
                            color: const Color(0xFFFF5E00),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_quantity > 0) ...[
                      Text(
                        'From $storeName',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7D73),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cart item card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 68,
                                    height: 68,
                                    child: productImage.startsWith('http')
                                        ? Image.network(
                                            productImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _cartImageFallback(),
                                          )
                                        : Image.asset(
                                            productImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _cartImageFallback(),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productTitle,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$_unitPrice MRU',
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
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6ECE5),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (_quantity > 0) {
                                            _setQuantity(_quantity - 1);
                                          }
                                        },
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Icon(
                                            Icons.remove_rounded,
                                            color: Color(0xFFE53935),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          '$_quantity',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            _setQuantity(_quantity + 1),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF5E00),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            color: Colors.white,
                                            size: 16,
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
                              height: 42,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFE0D5CC),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                controller: _customQuantityController,
                                keyboardType: TextInputType.number,
                                onChanged: _onCustomQuantityChanged,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 11,
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                      ),
                    ],

                    if (_quantity > 0) ...[
                      const SizedBox(height: 12),

                      if (!_isSelfPickup) ...[
                        CustomPaint(
                          painter: _DashedBorderPainter(
                            color: const Color(0xFFD9D0C8),
                            borderRadius: 28,
                          ),
                          child: Container(
                            height: 44,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            alignment: Alignment.centerLeft,
                            child: TextField(
                              controller: _deliveryNoteController,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: '+ Add delivery note (Optional)',
                                hintStyle: GoogleFonts.outfit(
                                  color: const Color(0xFFA59A94),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      Text(
                        'Delivery Type',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDeliveryTypeCard(
                              selected: !_isSelfPickup,
                              title: 'Delivery',
                              subtitle: '35 min',
                              onTap: () {
                                setState(() {
                                  _isSelfPickup = false;
                                  if (_selectedPaymentMethod == 2) {
                                    _selectedPaymentMethod = 0;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDeliveryTypeCard(
                              selected: _isSelfPickup,
                              title: 'Self Pickup',
                              subtitle: 'Ready in 15 min',
                              onTap: () {
                                setState(() {
                                  _isSelfPickup = true;
                                  if (_selectedPaymentMethod == 2) {
                                    _selectedPaymentMethod = 0;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (!_isSelfPickup)
                        GestureDetector(
                          onTap: () =>
                              Get.to(() => const SavedAddressesScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(_cardRadius),
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
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0EA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.home_rounded,
                                    color: Color(0xFFFF5E00),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sahara View Home',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Near Marhaba Supermarket, Nouakchott',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF8C7D73),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(_cardRadius),
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
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0EA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFFF5E00),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pickup Location',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF2C2520),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Salam Supermarket, Near Nouakchott, Mauritania',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF8C7D73),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFFFF5E00),
                                size: 20,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF7F2),
                          borderRadius: BorderRadius.circular(_cardRadius),
                          border: Border.all(
                            color: const Color(0xFFB7DFCF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF00875A),
                                size: 16,
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
                                      color: const Color(0xFF00875A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isSelfPickup
                                        ? 'Pick a pickup time'
                                        : 'Pick a delivery time',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2E9B6F),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF00875A),
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Save More',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.to(() => const CouponsScreen()),
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
                      ),
                      const SizedBox(height: 10),

                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_outlined,
                              color: Color(0xFFFF5E00),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon',
                                  hintStyle: GoogleFonts.outfit(
                                    color: const Color(0xFFA59A94),
                                    fontSize: 12,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            Text(
                              'Apply',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: () {
                          setState(() => _usePoints = !_usePoints);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(_cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'lib/assets/images/Coin.png',
                                width: 22,
                                height: 22,
                                errorBuilder: (_, __, ___) => const Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Use 500 points ',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '= 50 MRU off',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF8C7D73),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildRadio(_usePoints),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Payment',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildPaymentOption(
                        index: 0,
                        title: 'SAIMPEX Wallet',
                        subtitle: 'Balance: 2,450 MRU',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentOption(
                        index: 1,
                        title: 'Online payment',
                        subtitle: 'Card • Mobile money',
                        icon: Icons.credit_card_rounded,
                      ),
                      if (!_isSelfPickup) ...[
                        const SizedBox(height: 8),
                        _buildPaymentOption(
                          index: 2,
                          title: 'Cash on Delivery',
                          subtitle: 'Pay the SAIMPEX driver',
                          icon: Icons.monetization_on_outlined,
                        ),
                      ],

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2522),
                          borderRadius: BorderRadius.circular(32),
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
                            _buildDetailRow('Item total', '$itemTotal MRU'),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Redeemed points',
                              '-$redeemedPoints MRU',
                              isDiscount: true,
                            ),
                            if (!_isSelfPickup) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                'Delivery fee',
                                '$deliveryFee MRU',
                              ),
                            ],
                            const SizedBox(height: 8),
                            _buildDetailRow('Tax', '$tax MRU'),
                            const SizedBox(height: 14),
                            Container(height: 1, color: Colors.white24),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'To pay',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '$grandTotal MRU',
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
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () {
                          _syncHomeCartBadgeCount(0);
                          Get.to(() => const OrderSuccessScreen());
                        },
                        child: Container(
                          height: 54,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5E00)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Pay $grandTotal MRU',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTypeCard({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0EA) : Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEAD8C9),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildRadio(selected),
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7D73),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool selected) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? const Color(0xFFFF5E00)
              : const Color(0xFFA59A94),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = index);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEAD8C9),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFFF5E00), size: 17),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7D73),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _buildRadio(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFB8AFA8),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isDiscount ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, this.borderRadius = 28});

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
