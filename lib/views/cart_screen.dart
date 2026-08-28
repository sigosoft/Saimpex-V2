import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_success_screen.dart';
import '../controllers/home_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';

class CartScreen extends StatefulWidget {
  final String? storeName;
  final String? itemName;
  final String? itemPortion;
  final int? basePrice;
  final String? itemImage;
  final bool showBottomNav;
  final bool isFoodOrGrocery;

  const CartScreen({
    Key? key,
    this.storeName,
    this.itemName,
    this.itemPortion,
    this.basePrice,
    this.itemImage,
    this.showBottomNav = false,
    this.isFoodOrGrocery = false,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isDelivery = true; // default to Delivery as in reference image 2
  int quantity = 1;
  bool usePoints = true;
  late int selectedPaymentIndex;
  String scheduleText = "Pick a delivery time";

  @override
  void initState() {
    super.initState();
    selectedPaymentIndex = widget.isFoodOrGrocery ? 3 : 0;
  }

  String get storeName => widget.storeName ?? "Pharmacy Nasr";
  String get itemTitle => widget.itemName ?? "Paracetamol 500 Mg";
  String get itemPortion => widget.itemPortion ?? "10 Tablets";
  int get basePrice => widget.basePrice ?? 50;
  String get itemImage =>
      widget.itemImage ??
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=350&auto=format&fit=crop';
  final int pointDiscountValue = 1;
  final int deliveryFee = 5;
  final int tax = 2;
  final TextEditingController _customQuantityController = TextEditingController();
  bool _syncingQuantityField = false;

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
    if (parsed != null && parsed >= 1 && parsed != quantity) {
      setState(() => quantity = parsed);
    }
  }

  void _setQuantity(int value) {
    final next = value < 1 ? 1 : value;
    setState(() => quantity = next);

    _syncingQuantityField = true;
    _customQuantityController.value = TextEditingValue(
      text: next.toString(),
      selection: TextSelection.collapsed(offset: next.toString().length),
    );
    _syncingQuantityField = false;
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic calculations
    final itemTotal = basePrice * quantity;
    final pointsOff = usePoints ? pointDiscountValue : 0;
    final currentDeliveryFee = isDelivery ? deliveryFee : 0;
    final toPay = itemTotal - pointsOff + currentDeliveryFee + tax;

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFFFFDF9),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: canPop
                    ? GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
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
                      )
                    : const SizedBox(width: 38),
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
              'From $storeName',
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // 1. Food Item Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
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
                      // Food Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          itemImage,
                          width: 74,
                          height: 74,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemTitle,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
                              '${basePrice * quantity} MRU',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity controls
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
                                if (quantity > 1) {
                                  _setQuantity(quantity - 1);
                                }
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
                                fontWeight: FontWeight.bold,
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
                      border: Border.all(
                        color: const Color(0xFFEAD8C9),
                        width: 0.8,
                      ),
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
                      textInputAction: TextInputAction.done,
                      onChanged: _onCustomQuantityChanged,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (isDelivery) ...[
              // Add Delivery Note — delivery only
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD9D0C8),
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
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
              const SizedBox(height: 18),
            ],

            // 3. Delivery Type
            Text(
              'Delivery type',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Delivery Option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isDelivery = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDelivery
                              ? const Color(0xFFFF5E00)
                              : const Color(0xFFEAD8C9),
                          width: isDelivery ? 1.5 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDelivery
                                    ? const Color(0xFFFF5E00)
                                    : const Color(0xFFA59A94),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: isDelivery
                                ? Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5E00),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                '30-35 min',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFA59A94),
                                  fontSize: 9,
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
                const SizedBox(width: 12),
                // Self Pickup Option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isDelivery = false;
                        if (selectedPaymentIndex == 2) {
                          selectedPaymentIndex =
                              0; // fallback to Wallet if COD is hidden
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !isDelivery
                              ? const Color(0xFFFF5E00)
                              : const Color(0xFFEAD8C9),
                          width: !isDelivery ? 1.5 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: !isDelivery
                                    ? const Color(0xFFFF5E00)
                                    : const Color(0xFFA59A94),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: !isDelivery
                                ? Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5E00),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: const Color(0xFFA59A94),
                                  fontSize: 9,
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

            const SizedBox(height: 14),

            // 4. Address Details (Shown conditionally based on delivery or pickup selection)
            if (isDelivery) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEAD8C9),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Near Marhaba Supermarket, Nouakchott.',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Edit',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEAD8C9),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
                      child: const Icon(
                        Icons.storefront_rounded,
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
                            storeName,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$storeName, Near Nouakchott, Mauritania',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
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
            ],

            // 5. Schedule for Later
            GestureDetector(
              onTap: () => _showScheduleBottomSheet(context),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFBBEAC5),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCEF5DA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF00B25C),
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
                              color: const Color(0xFF0E5A2A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scheduleText,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF3BA162),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF00B25C),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 6. Save More Header & Coupons list
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Opening Coupons Screen...',
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: const Color(0xFFFF5E00),
                      ),
                    );
                  },
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
            // Coupon input
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
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Coupon applied!',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: const Color(0xFFFF5E00),
                        ),
                      );
                    },
                    child: Text(
                      'Apply',
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
            const SizedBox(height: 10),
            // Use 500 points Card
            GestureDetector(
              onTap: () {
                setState(() {
                  usePoints = !usePoints;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEAD8C9),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monetization_on_outlined,
                        color: Color(0xFFFF5E00),
                        size: 15,
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
                              fontWeight: FontWeight.bold,
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

            const SizedBox(height: 18),

            // 7. Payment Header
            Text(
              'Payment',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Payment Cards list
            if (widget.isFoodOrGrocery) ...[
              // Card 0: Pay After Delivery (Featured Top Option for Food & Grocery)
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPaymentIndex = 3;
                  });
                  _showScheduleBottomSheet(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: selectedPaymentIndex == 3
                        ? const Color(0xFFFFF0EA)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedPaymentIndex == 3
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFEAD8C9),
                      width: selectedPaymentIndex == 3 ? 1.5 : 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFFFF5E00),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay After Delivery',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Enjoy your order first. Complete your payment whenever it's convenient after delivery.",
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF8C7D73),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedPaymentIndex == 3
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFA59A94),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: selectedPaymentIndex == 3
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

            // Card 1: SAIMPEX Wallet
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedPaymentIndex = 0;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedPaymentIndex == 0
                        ? const Color(0xFFFF5E00)
                        : const Color(0xFFEAD8C9),
                    width: selectedPaymentIndex == 0 ? 1.5 : 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
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
                            'SAIMPEX Wallet',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Balance: 2,450 MRU',
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
                          color: selectedPaymentIndex == 0
                              ? const Color(0xFFFF5E00)
                              : const Color(0xFFA59A94),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: selectedPaymentIndex == 0
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

            // Card 2: Online Payment
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedPaymentIndex = 1;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedPaymentIndex == 1
                        ? const Color(0xFFFF5E00)
                        : const Color(0xFFEAD8C9),
                    width: selectedPaymentIndex == 1 ? 1.5 : 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
                      child: const Icon(
                        Icons.credit_card_outlined,
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
                            'Online payment',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Card â€¢ Mobile money',
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
                          color: selectedPaymentIndex == 1
                              ? const Color(0xFFFF5E00)
                              : const Color(0xFFA59A94),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: selectedPaymentIndex == 1
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

            // Card 3: Cash on Delivery (Shown ONLY if Delivery type is Delivery)
            if (isDelivery)
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPaymentIndex = 2;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedPaymentIndex == 2
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFEAD8C9),
                      width: selectedPaymentIndex == 2 ? 1.5 : 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
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
                        child: const Icon(
                          Icons.monetization_on_outlined,
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
                              'Cash on Delivery',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pay the SAIMPEX driver',
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
                            color: selectedPaymentIndex == 2
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFA59A94),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: selectedPaymentIndex == 2
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

            const SizedBox(height: 14),

            // 8. Payment Details Box
            Container(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item total',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$itemTotal MRU',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                          'Redeemed points',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '-$pointDiscountValue MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isDelivery) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery fee',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$deliveryFee MRU',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$tax MRU',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$toPay MRU',
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
            ),

            const SizedBox(height: 24),

            // 9. Gradient Pay Button
            GestureDetector(
              onTap: () {
                Get.to(() => const OrderSuccessScreen());
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  selectedPaymentIndex == 3 ? 'Order Now' : 'Pay $toPay MRU',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: widget.showBottomNav
                ? AppBottomNavBar(
                    selectedIndex: HomeController.navCart,
                    onTap: BottomNavRouter.go,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showScheduleBottomSheet(BuildContext context) {
    final now = DateTime.now();
    final dates = List<DateTime>.generate(
      5,
      (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)),
    );
    DateTime selectedDate = dates.first;
    String? selectedTimeSlot;

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const timeSlots = [
      '8-10 AM',
      '10-12 PM',
      '2-4 PM',
      '4-6 PM',
      '6-8 PM',
      'Late night',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomPad = MediaQuery.paddingOf(context).bottom;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 56),
                  height: MediaQuery.of(context).size.height * 0.72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFF3EC),
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6F1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFD7C2),
                                ),
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
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
                                    'Schedule Delivery',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Choose your preferred delivery date and time',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFFEAD8C9), height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Date',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 86,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: dates.length,
                                  separatorBuilder: (_, index) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final date = dates[index];
                                    final isSelected =
                                        selectedDate.year == date.year &&
                                        selectedDate.month == date.month &&
                                        selectedDate.day == date.day;
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() => selectedDate = date);
                                      },
                                      child: Container(
                                        width: 62,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAD8C9),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              months[date.month - 1],
                                              style: GoogleFonts.outfit(
                                                color: isSelected
                                                    ? const Color(0xFFFF5E00)
                                                    : const Color(0xFFA59A94),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${date.day}',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF2C2520),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              weekdays[date.weekday - 1],
                                              style: GoogleFonts.outfit(
                                                color: isSelected
                                                    ? const Color(0xFFFF5E00)
                                                    : const Color(0xFFA59A94),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Time Slot',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 3.4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                                children: timeSlots.map((slot) {
                                  final isSelected = selectedTimeSlot == slot;
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(
                                        () => selectedTimeSlot = slot,
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFFF5E00)
                                              : const Color(0xFFE6E0DB),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            color: Color(0xFFFF5E00),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              slot,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFFFF5E00),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          16 + bottomPad,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            final month = months[selectedDate.month - 1];
                            final weekday = weekdays[selectedDate.weekday - 1];
                            final slot = selectedTimeSlot ?? timeSlots.first;
                            Navigator.pop(context);
                            setState(() {
                              scheduleText =
                                  '$weekday, $month ${selectedDate.day} • $slot';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Scheduled: $weekday, $month ${selectedDate.day} • $slot',
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: const Color(0xFFFF5E00),
                              ),
                            );
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF5E00),
                                  Color(0xFFFFAE00),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5E00,
                                  ).withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF5E00),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
