import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saimpex_v2/controllers/home_controller.dart';
import '../../widgets/app_back_button.dart';

import 'water_subscription_cart_screen.dart';

class WaterProductSubscriptionScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic>? supplier;

  const WaterProductSubscriptionScreen({
    super.key,
    required this.product,
    this.supplier,
  });

  @override
  State<WaterProductSubscriptionScreen> createState() =>
      _WaterProductSubscriptionScreenState();
}

class _WaterProductSubscriptionScreenState
    extends State<WaterProductSubscriptionScreen> {
  int quantity = 1;
  int selectedTypeIndex = 0;
  int? selectedSlotIndex = 0;
  bool slotsExpanded = true;
  String? selectedDuration;
  DateTime startDate = DateTime(2026, 6, 1);
  DateTime endDate = DateTime(2026, 6, 30);

  final subscriptionTypes = ['Daily', 'Weekly', 'Custom'];
  final durations = ['1 Week', '2 Weeks', '1 Month', '3 Months', '6 Months'];
  final timeSlots = [
    '8–10 AM',
    '10–12 PM',
    '12–2 PM',
    '2–4 PM',
    '4–6 PM',
    'Late night',
  ];

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  String _formatDate(DateTime date) {
    const months = [
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
    final day = date.day.toString().padLeft(2, '0');
    return '$day -${months[date.month - 1]} -${date.year}';
  }

  String _formatCartDate(DateTime date) {
    const months = [
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
    final day = date.day.toString().padLeft(2, '0');
    return '$day-${months[date.month - 1]}-${date.year}';
  }

  DateTime _endDateFromDuration(DateTime start, String duration) {
    switch (duration) {
      case '1 Week':
        return start.add(const Duration(days: 7));
      case '2 Weeks':
        return start.add(const Duration(days: 14));
      case '1 Month':
        return DateTime(start.year, start.month + 1, start.day);
      case '3 Months':
        return DateTime(start.year, start.month + 3, start.day);
      case '6 Months':
        return DateTime(start.year, start.month + 6, start.day);
      default:
        return start.add(const Duration(days: 30));
    }
  }

  void _applyDurationToEndDate([String? duration]) {
    final value = duration ?? selectedDuration;
    if (value == null) return;
    endDate = _endDateFromDuration(startDate, value);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? startDate : endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5E00),
              onPrimary: Colors.white,
              surface: Color(0xFFFFF9F5),
              onSurface: Color(0xFF2C2520),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = picked;
        if (selectedDuration != null) {
          _applyDurationToEndDate();
        } else if (endDate.isBefore(startDate)) {
          endDate = startDate.add(const Duration(days: 30));
        }
      } else {
        endDate = picked.isBefore(startDate) ? startDate : picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final image = (product['image'] ?? 'lib/assets/images/19Lbottle.png')
        .toString();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFFBF5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        height: 180,
                        child: Image.asset(
                          image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.water_drop_outlined,
                                color: Color(0xFF2E9FE6),
                                size: 80,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (product['title'] ?? 'Drinking Water 19L').toString(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product['rating'] ?? '4.6'} (${product['reviews'] ?? '10k + reviews'})',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          (product['price'] ?? '50 MRU').toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (product['originalPrice'] ?? '100 MRU').toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0xFFA59A94),
                          ),
                        ),
                        const Spacer(),
                        _buildQuantitySelector(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Subscription Type',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(subscriptionTypes.length, (i) {
                        final selected = selectedTypeIndex == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTypeIndex = i),
                            child: Container(
                              height: 40,
                              margin: EdgeInsets.only(
                                right: i == subscriptionTypes.length - 1
                                    ? 0
                                    : 8,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFF5E00)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF5E00,
                                          ).withValues(alpha: 0.22),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.03,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Text(
                                subscriptionTypes[i],
                                style: GoogleFonts.outfit(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF7A6A60),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Start Date',
                            value: _formatDate(startDate),
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'End Date',
                            value: _formatDate(endDate),
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Subscription Duration',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDurationDropdown(),
                    const SizedBox(height: 16),
                    _buildDeliverySlots(),
                    const SizedBox(height: 16),
                    _buildReturnBottleCard(),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: () {
                    final slotLabel = selectedSlotIndex == null
                        ? '8:00 - 10:00 AM'
                        : (timeSlots[selectedSlotIndex!] == 'Late night'
                              ? 'Late night'
                              : timeSlots[selectedSlotIndex!].replaceAll(
                                  '–',
                                  ' - ',
                                ));

                    if (Get.isRegistered<HomeController>()) {
                      Get.find<HomeController>().setCartItem(
                        storeName:
                            widget.supplier?['title']?.toString() ??
                            'PureLife Water Co.',
                        itemName: (product['title'] ?? 'Drinking Water')
                            .toString(),
                        itemPortion: (product['size'] ?? '19L').toString(),
                        basePrice: parsePrice(
                          product['price']?.toString() ?? '50',
                        ),
                        itemImage: product['image']?.toString(),
                      );
                    }

                    Get.to(
                      () => WaterSubscriptionCartScreen(
                        storeName:
                            widget.supplier?['title']?.toString() ??
                            'PureLife Water Co.',
                        itemName: (product['title'] ?? 'Drinking Water')
                            .toString()
                            .replaceAll(RegExp(r'\s+\d+L$'), ''),
                        itemSize: (product['size'] ?? '19L').toString(),
                        itemImage:
                            (product['image'] ??
                                    'lib/assets/images/19Lbottle.png')
                                .toString(),
                        unitPrice: parsePrice(
                          product['price']?.toString() ?? '50',
                        ),
                        quantity: quantity,
                        startDate: _formatCartDate(startDate),
                        endDate: _formatCartDate(endDate),
                        timeSlot: slotLabel,
                        subscriptionType: subscriptionTypes[selectedTypeIndex],
                      ),
                    );
                  },
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF5E00,
                          ).withValues(alpha: 0.28),
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
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ADD',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        8,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back(),),
          Expanded(
            child: Text(
              'Subscription',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (quantity > 1) setState(() => quantity--);
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8DC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => quantity++),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF7A6A60),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDuration,
          isExpanded: true,
          hint: Text(
            'Select Duration',
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFA59A94),
          ),
          items: durations
              .map(
                (d) => DropdownMenuItem(
                  value: d,
                  child: Text(
                    d,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedDuration = value;
              _applyDurationToEndDate(value);
            });
          },
        ),
      ),
    );
  }

  Widget _buildDeliverySlots() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFE8DC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => slotsExpanded = !slotsExpanded),
            child: Row(
              children: [
                Text(
                  'Delivery Time Slot',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(
                  slotsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF7A6A60),
                ),
              ],
            ),
          ),
          if (slotsExpanded) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(timeSlots.length, (index) {
                final selected = selectedSlotIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedSlotIndex = index),
                  child: Container(
                    width:
                        (MediaQuery.sizeOf(context).width - 32 - 32 - 10) / 2,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFF5E00)
                            : Colors.transparent,
                        width: selected ? 1.2 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: selected
                              ? const Color(0xFFFF5E00)
                              : const Color(0xFF8A7F77),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeSlots[index],
                          style: GoogleFonts.outfit(
                            color: selected
                                ? const Color(0xFF2C2520)
                                : const Color(0xFF6B5E56),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReturnBottleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You can return your empty water bottles when collecting your order via Self Pickup or hand them to the delivery partner during Home Delivery',
            style: GoogleFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
