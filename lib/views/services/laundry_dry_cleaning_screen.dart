import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'laundry_cart_screen.dart';
import 'laundry_choose_pickup_sheet.dart';
import '../../controllers/service_booking_draft.dart';
import '../../core/network/api_constants.dart';
import '../../widgets/app_back_button.dart';

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
  /// The provider's own garment list and prices for this service, as
  /// customer/serviceProvider returned it (picked on the provider screen).
  late final List<Map<String, dynamic>> _items = [
    for (final row
        in (ServiceBookingDraft.item['garments'] as List? ?? const []))
      if (row is Map && '${row['name'] ?? ''}'.trim().isNotEmpty)
        {
          'id': '${row['id'] ?? row['name']}',
          'title': '${row['name']}'.trim(),
          'price': (num.tryParse('${row['price'] ?? ''}') ?? 0).round(),
          'image':
              ApiConstants.mediaUrl(
                '${row['image'] ?? ''}'.trim().isEmpty
                    ? null
                    : '${row['image']}'.trim(),
              ) ??
              '',
        },
  ];

  late final Map<String, int> _qty = {
    for (final item in _items) item['id'] as String: 0,
  };

  /// `{name, quantity}` for every garment the customer added, as
  /// customer/service/book takes them.
  List<Map<String, dynamic>> get _pickedGarments => [
    for (final item in _items)
      if ((_qty[item['id']] ?? 0) > 0)
        {'name': item['title'], 'quantity': _qty[item['id']]},
  ];

  String get _heroImage => 'lib/assets/images/drycleaning_detail.png';

  int get _totalPrice => _items.fold<int>(
    0,
    (sum, item) =>
        sum + ((item['price'] as int) * (_qty[item['id'] as String] ?? 0)),
  );

  int get _totalItems => _qty.values.fold<int>(0, (sum, value) => sum + value);

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
        serviceTitle: 'svc_dry_cleaning'.tr,
        serviceImage: _heroImage,
        estimateLabel:
            (_totalItems == 1 ? 'svc_estimated_item' : 'svc_estimated_items')
                .trParams({'count': '$_totalItems'}),
        basePrice: _totalPrice,
        durationLabel: '24 hour',
        slotDate: date,
        slotLabel: slot,
        garments: _pickedGarments,
        quantity: _totalItems,
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
                        'svc_select_dry_clean_items'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1B2B4A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'svc_no_garments'.tr,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'svc_dry_cleaning'.tr,
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
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFFFFF3EB),
            alignment: Alignment.center,
            child: Image.asset(
              'lib/assets/images/Dry Cleaning.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
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
              errorBuilder: (_, _, _) => Container(
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
                  'svc_price_per_item'.trParams({'amount': '$price'}),
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
                      'svc_total_upper'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'mru'.trParams({'amount': '$_totalPrice'}),
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
                      'svc_duration_upper'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'svc_24_hours'.tr,
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
                'svc_choose_pickup_time'.tr,
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
