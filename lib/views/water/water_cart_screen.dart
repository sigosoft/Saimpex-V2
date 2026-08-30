import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saimpex_v2/controllers/home_controller.dart';
import 'water_subscription_success_screen.dart';

class WaterCartScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  final bool isSubscription;

  const WaterCartScreen({super.key, this.product, this.isSubscription = false});

  @override
  State<WaterCartScreen> createState() => _WaterCartScreenState();
}

class _WaterCartScreenState extends State<WaterCartScreen> {
  bool _isDelivery =
      true; // true: Delivery (35 min), false: Self Pickup (15 min)
  int _quantity = 0;
  bool _usePoints = false;
  int _selectedPaymentMethod = 0; // 0: Wallet, 1: Online, 2: COD

  final TextEditingController _customQtyController = TextEditingController();
  final TextEditingController _deliveryNoteController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  bool _syncingQuantityField = false;

  @override
  void initState() {
    super.initState();
    _quantity = (widget.product != null) ? 1 : 0;
    _syncHomeCartBadgeCount(_quantity);
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
    _customQtyController.value = TextEditingValue(
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

  @override
  void dispose() {
    _customQtyController.dispose();
    _deliveryNoteController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSubscription) {
      return _buildSubscriptionCartView(context);
    }
    return _buildRegularCartView(context);
  }

  // -------------------------------------------------------------
  // ONE-TIME PURCHASE REGULAR CART VIEW (Matches Reference Images)
  // -------------------------------------------------------------
  Widget _buildRegularCartView(BuildContext context) {
    final title = widget.product?['title'] ?? 'Drinking Water';
    final image = widget.product?['image'] ?? 'lib/assets/images/19L water.png';
    final supplierName = widget.product?['supplier'] ?? 'PureLife Water Co.';

    // Dynamic Price Calculations
    final int itemTotal = 50 * _quantity;
    final int redeemedPoints = (_usePoints && _quantity > 0) ? 1 : 0;
    final int deliveryFee = (_isDelivery && _quantity > 0) ? 5 : 0;
    final int tax = _quantity > 0 ? 2 : 0;
    final int rawToPay = itemTotal - redeemedPoints + deliveryFee + tax;
    final int totalToPay = (_quantity == 0 || rawToPay < 0) ? 0 : rawToPay;
    // When _isDelivery: 50 - 1 + 5 + 2 = 56 MRU
    // When !_isDelivery: 50 - 1 + 0 + 2 = 51 MRU

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Header Bar
              _buildHeader(context),
              const SizedBox(height: 4),

              // Supplier Subtitle
              if (_quantity > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'From $supplierName',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C7E75),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Main Form Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Product Item Card (With quantity input box)
                      _buildRegularProductCard(title, image),
                      if (_quantity > 0) ...[
                        const SizedBox(height: 12),

                        // 2. Delivery Note Field (Shown if Delivery selected)
                        if (_isDelivery) ...[
                          _buildDeliveryNoteBox(),
                          const SizedBox(height: 16),
                        ],

                        // 3. Delivery Type Section (Delivery vs Self Pickup Toggle)
                        _buildDeliveryTypeSection(),
                        const SizedBox(height: 16),

                        // 4. Dynamic Location Card (Home vs Pickup Location)
                        _buildDynamicLocationCard(),
                        const SizedBox(height: 12),

                        // 5. Schedule for Later Card
                        _buildScheduleForLaterCard(),
                        const SizedBox(height: 18),

                        // 6. Save More Section
                        _buildSaveMoreSection(),
                        const SizedBox(height: 18),

                        // 7. Payment Options
                        _buildPaymentSection(),
                        const SizedBox(height: 20),

                        // 8. Dark Receipt Box (PAYMENT DETAILS)
                        _buildRegularDarkReceiptBox(
                          itemTotal,
                          redeemedPoints,
                          deliveryFee,
                          tax,
                          totalToPay,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Button (Pay 56 MRU / Pay 51 MRU)
              if (_quantity > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      _syncHomeCartBadgeCount(0);
                      Get.to(() => const WaterSubscriptionSuccessScreen());
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Pay $totalToPay MRU',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Regular Product Card (With Customize your quantity input box)
  Widget _buildRegularProductCard(String title, String image) {
    if (_quantity == 0) {
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
              onTap: () {
                setState(() => _quantity = 1);
                _syncCustomQuantityField();
              },
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 65,
                  height: 65,
                  color: const Color(0xFFEBF4FE),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.water_drop,
                      color: Color(0xFF007BFF),
                      size: 30,
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
                      title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '19L',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '50 MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Stepper Counter Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_quantity > 0) {
                          setState(() {
                            _quantity--;
                          });
                          _syncCustomQuantityField();
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF5E00),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.remove_rounded,
                          color: Color(0xFFFF5E00),
                          size: 14,
                        ),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _quantity++;
                        });
                        _syncCustomQuantityField();
                      },
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
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customize your quantity input box
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            child: TextField(
              controller: _customQtyController,
              onChanged: _onCustomQuantityChanged,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: 'Customize your quantity here',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 11,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delivery Note Field Box
  Widget _buildDeliveryNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      ),
      child: Text(
        '+ Add delivery note (Optional)',
        style: GoogleFonts.outfit(color: const Color(0xFFA59A94), fontSize: 11),
      ),
    );
  }

  // Delivery Type Section (Delivery vs Self Pickup Radio Pills)
  Widget _buildDeliveryTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Type',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Pill 1: Delivery
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDelivery = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isDelivery ? const Color(0xFFFFF0E6) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isDelivery
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFEAD8C9),
                      width: _isDelivery ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDelivery
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _isDelivery
                            ? const Color(0xFFFF5E00)
                            : const Color(0xFFA59A94),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '30-35 min',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF8C7E75),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Pill 2: Self Pickup
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDelivery = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: !_isDelivery
                        ? const Color(0xFFFFF0E6)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: !_isDelivery
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFEAD8C9),
                      width: !_isDelivery ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !_isDelivery
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: !_isDelivery
                            ? const Color(0xFFFF5E00)
                            : const Color(0xFFA59A94),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Self Pickup',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ready in 15 min',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF8C7E75),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Dynamic Location Card (Sahara View Home vs Pickup Location)
  Widget _buildDynamicLocationCard() {
    if (_isDelivery) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_outlined,
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
                    'Sahara View Home',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Near Marhaba Supermarket, Nouakchott',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7E75),
                      fontSize: 10,
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
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
                      color: const Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Salam Supermarket, Near Nouakchott, Mauritania',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7E75),
                      fontSize: 10,
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
      );
    }
  }

  // Schedule for later Card
  Widget _buildScheduleForLaterCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC3EED5), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF00A859),
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
                    color: const Color(0xFF00A859),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pick a delivery time',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF00A859),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF00A859),
            size: 20,
          ),
        ],
      ),
    );
  }

  // Save More Section (With View Coupons link)
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
                color: const Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'View Coupons',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Coupon Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
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
                child: Text(
                  'Enter coupon',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'Apply',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Points Card
        GestureDetector(
          onTap: () {
            setState(() {
              _usePoints = !_usePoints;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'lib/assets/images/Coin.png',
                    width: 12,
                    height: 12,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use 500 points',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(- 50 MRU off)',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7E75),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _usePoints
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _usePoints
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFA59A94),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Payment Section (COD hidden when Self Pickup)
  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildPaymentOptionCard(
          index: 0,
          title: 'SAIMPEX Wallet',
          subtitle: 'Balance: 2,490 MRU',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 10),
        _buildPaymentOptionCard(
          index: 1,
          title: 'Online payment',
          subtitle: 'Card • Mobile Money',
          icon: Icons.credit_card_outlined,
        ),
        if (_isDelivery) ...[
          const SizedBox(height: 10),
          _buildPaymentOptionCard(
            index: 2,
            title: 'Cash on Delivery',
            subtitle: 'Pay the SAIMPEX driver',
            icon: Icons.payments_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5E00) : Colors.transparent,
            width: isSelected ? 1.5 : 0.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF5E00), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7E75),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFA59A94),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Dark Receipt Box (PAYMENT DETAILS - Matches both reference images)
  Widget _buildRegularDarkReceiptBox(
    int itemTotal,
    int redeemedPoints,
    int deliveryFee,
    int tax,
    int totalToPay,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildReceiptRow('Item total', '$itemTotal MRU'),
          const SizedBox(height: 8),
          _buildReceiptRow(
            'Redeemed points',
            '-$redeemedPoints MRU',
            isOrange: true,
          ),
          if (_isDelivery) ...[
            const SizedBox(height: 8),
            _buildReceiptRow('Delivery fee', '$deliveryFee MRU'),
          ],
          const SizedBox(height: 8),
          _buildReceiptRow('Tax', '$tax MRU'),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To pay',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalToPay MRU',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SUBSCRIPTION CART VIEW (From Previous Steps)
  // -------------------------------------------------------------
  Widget _buildSubscriptionCartView(BuildContext context) {
    final title = widget.product?['title'] ?? 'Drinking Water';
    final image = widget.product?['image'] ?? 'lib/assets/images/19L water.png';
    final price = widget.product?['price'] ?? '50 MRU';
    final supplierName = widget.product?['supplier'] ?? 'PureLife Water Co.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(context),
              if (_quantity > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'From $supplierName',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C7E75),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubscriptionProductCard(title, image, price),
                      if (_quantity > 0) ...[
                        const SizedBox(height: 12),
                        _buildDeliveryNoteBox(),
                        const SizedBox(height: 18),
                        _buildSubscriptionDetailsGrid(),
                        const SizedBox(height: 18),
                        _buildDynamicLocationCard(),
                        const SizedBox(height: 20),
                        _buildSaveMoreSection(),
                        const SizedBox(height: 20),
                        _buildPaymentSection(),
                        const SizedBox(height: 24),
                        _buildSubscriptionDarkReceiptBox(),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              if (_quantity > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      _syncHomeCartBadgeCount(0);
                      Get.to(() => const WaterSubscriptionSuccessScreen());
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5E00).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Pay 5500 MRU',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionProductCard(
    String title,
    String image,
    String price,
  ) {
    if (_quantity == 0) {
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
              onTap: () {
                setState(() => _quantity = 1);
                _syncCustomQuantityField();
              },
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 70,
              height: 70,
              color: const Color(0xFFEBF4FE),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.water_drop,
                  color: Color(0xFF007BFF),
                  size: 30,
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
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '19L',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_quantity > 0) {
                      setState(() {
                        _quantity--;
                      });
                      _syncCustomQuantityField();
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF5E00),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _quantity++;
                    });
                    _syncCustomQuantityField();
                  },
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
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetailsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subscription Details',
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Edit',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          children: [
            _buildSubInfoCard('Start Date', '01-Jun-2026'),
            _buildSubInfoCard('End Date', '31-Dec-2026'),
            _buildSubInfoCard('Time Slot', '8:00 - 10:00 AM'),
            _buildSubInfoCard('Type', 'Daily'),
          ],
        ),
      ],
    );
  }

  Widget _buildSubInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8C7E75),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDarkReceiptBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildReceiptRow('Subscription Amount', '9000 MRU'),
          const SizedBox(height: 8),
          _buildReceiptRow('Subscription Savings', '-4500 MRU', isOrange: true),
          const SizedBox(height: 8),
          _buildReceiptRow('Estimated Delivery Fee', '900 MRU'),
          const SizedBox(height: 8),
          _buildReceiptRow('Tax', '100 MRU'),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To pay',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '5500 MRU',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Header Bar Widget
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFFF5E00),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Cart',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isOrange = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFFD4CDC5),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: isOrange ? const Color(0xFFFF5E00) : Colors.white,
            fontSize: 12,
            fontWeight: isOrange ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
