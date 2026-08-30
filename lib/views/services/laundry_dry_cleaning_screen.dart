import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'laundry_cart_screen.dart';
import 'laundry_choose_pickup_sheet.dart';

class LaundryDryCleaningScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;

  const LaundryDryCleaningScreen({
    super.key,
    required this.service,
    this.providerName = 'CleanPro Laundry',
  });

  @override
  State<LaundryDryCleaningScreen> createState() =>
      _LaundryDryCleaningScreenState();
}

class _LaundryDryCleaningScreenState extends State<LaundryDryCleaningScreen> {
  static const _items = [
    {
      'id': 'shirt',
      'title': 'Shirt',
      'price': 50,
      'image':
          'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=200&h=200&fit=crop',
    },
    {
      'id': 'trousers',
      'title': 'Trousers',
      'price': 40,
      'image':
          'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=200&h=200&fit=crop',
    },
    {
      'id': 'dress',
      'title': 'Dress',
      'price': 30,
      'image':
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=200&h=200&fit=crop',
    },
    {
      'id': 'jacket',
      'title': 'Jacket',
      'price': 80,
      'image':
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=200&h=200&fit=crop',
    },
    {
      'id': 'suit',
      'title': 'Suit',
      'price': 60,
      'image':
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=200&h=200&fit=crop',
    },
  ];

  final Map<String, int> _qty = {
    for (final item in _items) item['id'] as String: 0,
  };

  String get _heroImage => 'lib/assets/images/drycleaning_detail.png';

  int get _totalPrice => _items.fold<int>(
        0,
        (sum, item) =>
            sum +
            ((item['price'] as int) * (_qty[item['id'] as String] ?? 0)),
      );

  int get _totalItems =>
      _qty.values.fold<int>(0, (sum, value) => sum + value);

  String _slotRangeFromLabel(String label) {
    final match = RegExp(
      r'(\d+)\s*[–-]\s*(\d+)\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (match == null) return label;
    final start = match.group(1)!;
    final end = match.group(2)!;
    final period = match.group(3)!.toUpperCase();
    return '$start:00 $period – $end:00 $period';
  }

  Future<void> _openPickupAndCart() async {
    if (_totalItems == 0) return;
    final result = await LaundryChoosePickupSheet.show(context);
    if (result == null || !mounted) return;
    final date = result['date'] as DateTime;
    final slot = _slotRangeFromLabel(result['slot'] as String);
    Get.to(
      () => LaundryCartScreen(
        providerName: widget.providerName,
        serviceTitle: 'Dry Cleaning',
        serviceImage: _heroImage,
        estimateLabel:
            'Estimated $_totalItems item${_totalItems == 1 ? '' : 's'}',
        basePrice: _totalPrice,
        durationLabel: '24 hour',
        slotDate: date,
        slotLabel: slot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 18),
                      Text(
                        'Select the items you want to dry clean',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1B2B4A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < _items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _buildItemCard(_items[i]),
                      ],
                    ],
                  ),
                ),
              ),
              _buildBottomBar(bottomInset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF5E00),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFF5E00),
                size: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Dry Cleaning',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.asset(
          _heroImage,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFFFF3EB),
            alignment: Alignment.center,
            child: Image.asset(
              'lib/assets/images/Dry Cleaning.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.dry_cleaning_rounded,
                color: Color(0xFFFF5E00),
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final qty = _qty[id] ?? 0;
    final price = item['price'] as int;

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item['image'] as String,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 58,
                color: const Color(0xFFFFF3EB),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.checkroom_rounded,
                  color: Color(0xFFFF5E00),
                  size: 26,
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
                  item['title'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$price MRU / item',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildQtyStepper(id, qty),
        ],
      ),
    );
  }

  Widget _buildQtyStepper(String id, int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EB),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(
            icon: Icons.remove_rounded,
            filled: false,
            onTap: () {
              if (qty > 0) setState(() => _qty[id] = qty - 1);
            },
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _qtyButton(
            icon: Icons.add_rounded,
            filled: true,
            onTap: () => setState(() => _qty[id] = qty + 1),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5E00) : Colors.white,
          shape: BoxShape.circle,
          border: filled
              ? null
              : Border.all(color: const Color(0xFFFF5E00), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : const Color(0xFFFF5E00),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_totalPrice MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'DURATION',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '24 hours',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1B2B4A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _openPickupAndCart,
            child: Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Choose Pickup Time',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
