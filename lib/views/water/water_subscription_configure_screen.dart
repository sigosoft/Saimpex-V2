import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saimpex_v2/controllers/home_controller.dart';
import 'water_cart_screen.dart';

class WaterSubscriptionConfigureScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const WaterSubscriptionConfigureScreen({super.key, this.product});

  @override
  State<WaterSubscriptionConfigureScreen> createState() =>
      _WaterSubscriptionConfigureScreenState();
}

class _WaterSubscriptionConfigureScreenState
    extends State<WaterSubscriptionConfigureScreen> {
  int _quantity = 1;
  String _selectedSubType = 'Daily';
  String _selectedDuration = '6 Months';
  String _selectedTimeSlot = '8-10 AM';
  DateTime _startDate = DateTime(2026, 6, 1);
  DateTime _endDate = DateTime(2026, 12, 1);

  final List<String> _subTypes = ['Daily', 'Weekly', 'Custom'];
  final List<String> _timeSlots = [
    '8-10 AM',
    '10-12 PM',
    '2-4 PM',
    '4-6 PM',
    '6-8 PM',
    'Late night',
  ];

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final mon = months[dt.month - 1];
    return '$day-$mon-${dt.year}';
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5E00),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product?['title'] ?? 'Drinking Water 19L';
    final image = widget.product?['image'] ?? 'lib/assets/images/19L water.png';
    final rating = widget.product?['rating'] ?? '4.6';
    final reviews = widget.product?['reviews'] ?? '(10k + reviews)';
    final price = widget.product?['price'] ?? '50 MRU';
    final originalPrice = widget.product?['originalPrice'] ?? '100 MRU';

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
              // 1. Header Bar
              _buildHeader(context),
              const SizedBox(height: 12),

              // Scrollable Form Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Product Hero Bottle Image
                      Center(
                        child: Image.asset(
                          image,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.water_drop_rounded,
                            size: 90,
                            color: Color(0xFF007BFF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Product Title, Rating, Price & Quantity Stepper
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1A1A1A),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFB800),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF1A1A1A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      reviews,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF7A6A60),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      price,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFF5E00),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      originalPrice,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFA59A94),
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Quantity Stepper Counter Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF8C42),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_quantity > 1) {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
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
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_quantity',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _quantity++;
                                    });
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
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
                      const SizedBox(height: 24),

                      // 4. Subscription Type
                      Text(
                        'Subscription Type',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _subTypes.map((type) {
                          final isSelected = _selectedSubType == type;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSubType = type;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF5E00)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF5E00)
                                        : const Color(0xFFEAD8C9),
                                    width: 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFF5E00,
                                            ).withOpacity(0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    type,
                                    style: GoogleFonts.outfit(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2C2520),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 5. Start Date & End Date Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF6B635C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _pickDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEAD8C9),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(_startDate),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF1A1A1A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          color: Color(0xFFA59A94),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF6B635C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _pickDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFEAD8C9),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(_endDate),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF1A1A1A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          color: Color(0xFFA59A94),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 6. Subscription Duration Dropdown
                      Text(
                        'Subscription Duration',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6B635C),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEAD8C9),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Duration',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 13,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFFA59A94),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 7. Delivery Time Slot Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery Time Slot',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF6B635C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Color(0xFF6B635C),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _timeSlots.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.8,
                            ),
                        itemBuilder: (context, index) {
                          final slot = _timeSlots[index];
                          final isSelected = _selectedTimeSlot == slot;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTimeSlot = slot;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEAD8C9),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: isSelected
                                        ? const Color(0xFFFF5E00)
                                        : const Color(0xFFFF5E00),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    slot,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // 8. Return Empty Bottle Banner Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
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
                                const Icon(
                                  Icons.recycling_rounded,
                                  color: Color(0xFF00A859),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Return Empty Bottle',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF5E00),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You can return your empty water bottles when collecting your order via Self Pickup or hand them to the delivery partner during Home Delivery.',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF6B635C),
                                fontSize: 11,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 9. Bottom Action Bar (ADD Cart Button)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (Get.isRegistered<HomeController>()) {
                      Get.find<HomeController>().setCartItem(
                        storeName: widget.product?['supplier']?.toString() ?? 'PureLife Water Co.',
                        itemName: widget.product?['title']?.toString() ?? 'Drinking Water',
                        itemPortion: widget.product?['size']?.toString() ?? '19L',
                        basePrice: widget.product?['price'],
                        itemImage: widget.product?['image']?.toString(),
                      );
                    }
                    Get.to(
                      () => WaterCartScreen(
                        product: widget.product,
                        isSubscription: true,
                      ),
                    );
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ADD',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
              'Subscription',
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
}
