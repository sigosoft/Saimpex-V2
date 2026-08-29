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

  @override
  void initState() {
    super.initState();
    _quantity = (widget.product != null || widget.store != null) ? 1 : 0;
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
    final storeName = widget.store?['name'] ?? 'Golden Bakery';
    final productTitle = widget.product?['title'] ?? 'Butter Croissant';
    final productImage =
        widget.product?['image'] ?? 'lib/assets/images/Bakery.png';

    const int itemUnitPrice = 50;
    final int itemTotal = itemUnitPrice * _quantity;
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
            SizedBox(height: topInset + 10),

            // 1. Top Header Row (Back Button & Cart Title)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Sub-header Text: "From Golden Bakery"
            if (_quantity > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  'From $storeName',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8C7D73),
                    fontSize: 11,
                  ),
                ),
              ),

            // Main Scrollable Body Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_quantity > 0) ...[
                      // 2. Cart Item Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                                    width: 65,
                                    height: 65,
                                    child: Image.asset(
                                      productImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFF3E7DC),
                                        child: const Icon(
                                          Icons.fastfood_rounded,
                                          color: Color(0xFFFF5E00),
                                          size: 30,
                                        ),
                                      ),
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
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '50 MRU',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFF5E00),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Counter Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0EA),
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
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.remove_rounded,
                                              color: Color(0xFF8C7D73),
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          '$_quantity',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 13,
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
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF5E00),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Customize quantity input
                            Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(21),
                                border: Border.all(
                                  color: const Color(0xFFEAD8C9),
                                  width: 1.0,
                                ),
                              ),
                              child: TextField(
                                controller: _customQuantityController,
                                onChanged: _onCustomQuantityChanged,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 11,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Customize your quantity here',
                                  hintStyle: GoogleFonts.outfit(
                                    color: const Color(0xFFA59A94),
                                    fontSize: 11,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(
                                    top: 11,
                                  ),
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
                          borderRadius: BorderRadius.circular(24),
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
                      ),
                    ],

                    if (_quantity > 0) ...[
                      const SizedBox(height: 12),

                      // 3. Add Delivery Note (Optional) Container (Shown in Delivery mode)
                      if (!_isSelfPickup) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6ECE5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '+',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF8C7D73),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add delivery note (Optional)',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF8C7D73),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 4. Delivery Type Section
                      Text(
                        'Delivery Type',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Delivery Type Toggle Cards Row
                      Row(
                        children: [
                          // Delivery Option Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSelfPickup = false;
                                  if (_selectedPaymentMethod == 2) {
                                    _selectedPaymentMethod = 0;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: !_isSelfPickup
                                      ? Border.all(
                                          color: const Color(0xFFFF5E00),
                                          width: 1.5,
                                        )
                                      : Border.all(
                                          color: const Color(0xFFEAD8C9),
                                          width: 0.8,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: !_isSelfPickup
                                              ? const Color(0xFFFF5E00)
                                              : const Color(0xFFA59A94),
                                          width: 2,
                                        ),
                                      ),
                                      child: !_isSelfPickup
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
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delivery',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '35 min',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF8C7D73),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Self Pickup Option Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSelfPickup = true;
                                  if (_selectedPaymentMethod == 2) {
                                    _selectedPaymentMethod = 0;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isSelfPickup
                                      ? const Color(0xFFFFF0EA)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: _isSelfPickup
                                      ? Border.all(
                                          color: const Color(0xFFFF5E00),
                                          width: 1.5,
                                        )
                                      : Border.all(
                                          color: const Color(0xFFEAD8C9),
                                          width: 0.8,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isSelfPickup
                                              ? const Color(0xFFFF5E00)
                                              : const Color(0xFFA59A94),
                                          width: 2,
                                        ),
                                      ),
                                      child: _isSelfPickup
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
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Self Pickup',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ready in 15 min',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFFF5E00),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 5. Address / Location Details Card
                      if (!_isSelfPickup)
                        // Delivery Address Card
                        GestureDetector(
                          onTap: () =>
                              Get.to(() => const SavedAddressesScreen()),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF0EA),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sahara View Home',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Near Marhaba Supermarket, Household',
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        // Pickup Location Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF0EA),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
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
                                        fontWeight: FontWeight.bold,
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
                                size: 18,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // 6. Schedule for Later Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF7F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isSelfPickup
                                        ? 'Pick a pickup time'
                                        : 'Pick a delivery time',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF00875A),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF00875A),
                              size: 18,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 7. Save More Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Save More',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.to(() => const CouponsScreen()),
                            child: Text(
                              'View Coupons',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Coupon Input Box
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(23),
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
                                  contentPadding: const EdgeInsets.only(
                                    top: 10,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'Apply',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Points Toggle Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF0EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 12),
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
                                      color: const Color(0xFF2C2520),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '= 50 MRU off',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF8C7D73),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _usePoints = !_usePoints;
                                });
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _usePoints
                                        ? const Color(0xFFFF5E00)
                                        : const Color(0xFFA59A94),
                                    width: 2,
                                  ),
                                ),
                                child: _usePoints
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
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 8. Payment Options Section
                      Text(
                        'Payment',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Option 1: SAIMPEX Wallet
                      _buildPaymentOption(
                        index: 0,
                        title: 'SAIMPEX Wallet',
                        subtitle: 'Balance: 2,450 MRU',
                        icon: Icons.account_balance_wallet_outlined,
                      ),

                      const SizedBox(height: 8),

                      // Option 2: Online payment
                      _buildPaymentOption(
                        index: 1,
                        title: 'Online payment',
                        subtitle: 'Card • Mobile money',
                        icon: Icons.credit_card_rounded,
                      ),

                      // Option 3: Cash on Delivery (Delivery Mode Only)
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

                      // 9. Payment Details Card (Dark Theme Container)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2520),
                          borderRadius: BorderRadius.circular(24),
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
                                letterSpacing: 0.5,
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
                            Container(height: 1, color: Colors.white12),
                            const SizedBox(height: 14),
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

                      // 10. Bottom Pay Action Button
                      GestureDetector(
                        onTap: () {
                          _syncHomeCartBadgeCount(0);
                          Get.to(() => const OrderSuccessScreen());
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
                                color: const Color(
                                  0xFFFF5E00,
                                ).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Pay 750 MRU',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
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

  // Payment Option Card Widget Helper
  Widget _buildPaymentOption({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFFFF5E00), width: 1.5)
              : null,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7D73),
                      fontSize: 10,
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
                  width: 2,
                ),
              ),
              child: isSelected
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
            ),
          ],
        ),
      ),
    );
  }

  // Payment Detail Line Row Helper
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
            color: const Color(0xFFA59A94),
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
