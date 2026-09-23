import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'car_wash_choose_slot_sheet.dart';
import 'car_wash_booking_success_screen.dart';
import '../../controllers/car_wash_bookings_store.dart';

class CarWashCartScreen extends StatefulWidget {
  final String providerName;
  final String serviceTitle;
  final String serviceDescription;
  final String serviceImage;
  final String vehicleLabel;
  final String vehicleImage;
  final String plateNumber;
  final int servicePrice;
  final int basePrice;
  final int baseDurationMin;
  final DateTime slotDate;
  final String slotLabel;
  final List<Map<String, dynamic>> selectedAddons;
  final int selectedLocation;
  final String serviceAddress;
  final int homeServiceFee;

  const CarWashCartScreen({
    super.key,
    this.providerName = 'CleanRide Car Wash',
    this.serviceTitle = 'Exterior Wash',
    this.serviceDescription =
        'High pressure snow foam, detailed rim cleaning & streak-free hand dry',
    this.serviceImage =
        'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=300&h=300&fit=crop',
    this.vehicleLabel = 'Sedan',
    this.vehicleImage = 'lib/assets/images/Sedan.png',
    this.plateNumber = '1234 AB 01',
    this.servicePrice = 550,
    this.basePrice = 550,
    this.baseDurationMin = 30,
    required this.slotDate,
    required this.slotLabel,
    this.selectedAddons = const [],
    this.selectedLocation = 0,
    this.serviceAddress = '',
    this.homeServiceFee = 0,
    Set<String>? initialAddonIds,
  });

  @override
  State<CarWashCartScreen> createState() => _CarWashCartScreenState();
}

class _CarWashCartScreenState extends State<CarWashCartScreen> {
  late DateTime _slotDate;
  late String _slotLabel;
  bool _usePoints = false;
  int _paymentIndex = -1;
  final _couponController = TextEditingController();

  static const _tax = 10;
  static const _pointsOff = 50;

  @override
  void initState() {
    super.initState();
    _slotDate = widget.slotDate;
    _slotLabel = widget.slotLabel;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  int get _subtotal => widget.basePrice;

  int get _pointsDiscount => _usePoints ? _pointsOff : 0;
  int get _toPay => _subtotal - _pointsDiscount + _tax;

  static const _months = [
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

  String get _slotDisplay {
    final d = _slotDate;
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $_slotLabel';
  }

  String get _locationText {
    if (widget.selectedLocation == 1) {
      final addr = widget.serviceAddress.trim();
      if (addr.isNotEmpty) return addr;
      return 'At Home Service';
    }
    return '${widget.providerName}, Near Nouakchott, Mauritania';
  }

  String _slotRangeFromLabel(String label) {
    final full = RegExp(
      r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (full != null) {
      final startH = full.group(1)!;
      final startM = full.group(2)!;
      final endH = full.group(3)!;
      final endM = full.group(4)!;
      final period = full.group(5)!.toUpperCase();
      return '$startH:$startM $period - $endH:$endM $period';
    }
    final short = RegExp(
      r'(\d+)\s*[–-]\s*(\d+)\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (short == null) return label;
    return '${short.group(1)}:00 ${short.group(3)!.toUpperCase()} - ${short.group(2)}:00 ${short.group(3)!.toUpperCase()}';
  }

  Future<void> _changeSlot() async {
    final result = await CarWashChooseSlotSheet.show(context);
    if (result == null) return;
    setState(() {
      _slotDate = result['date'] as DateTime;
      _slotLabel = _slotRangeFromLabel(result['slot'] as String);
    });
  }

  void _pay() {
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
    final d = _slotDate;
    final slotDisplay =
        '${d.day} ${months[d.month - 1]} ${d.year}, $_slotLabel';
    final bookingId =
        '22789${(100 + CarWashBookingsStore.instance.bookings.length).toString().padLeft(3, '0')}';

    final washServices = <Map<String, dynamic>>[
      {
        'title': widget.serviceTitle,
        'description': widget.serviceDescription,
        'price': '${widget.servicePrice} MRU',
        'image': widget.serviceImage,
      },
      ...widget.selectedAddons.map(
        (a) => {
          'title': a['title'],
          'description': a['description'],
          'price': '+${a['price'] ?? 0} MRU',
          'image': a['image'],
          'isAddon': true,
        },
      ),
    ];

    CarWashBookingsStore.instance.add({
      'id': bookingId,
      'provider': widget.providerName,
      'category': 'Car Wash',
      'categoryColor': 0xFF2B7DE9,
      'service': widget.serviceTitle,
      'serviceTitle': widget.serviceTitle,
      'serviceDescription': widget.serviceDescription,
      'serviceImage': widget.serviceImage,
      'servicePrice': '${widget.servicePrice} MRU',
      'status': 'Confirmed',
      'datetime': slotDisplay,
      'slot': slotDisplay,
      'location': _locationText,
      'locationTitle': widget.providerName,
      'price': '$_toPay MRU',
      'vehicleLabel': widget.vehicleLabel,
      'vehicleImage': widget.vehicleImage,
      'plateNumber': widget.plateNumber,
      'image': widget.vehicleImage,
      'washServices': washServices,
      'addons': widget.selectedAddons
          .map(
            (a) => {
              'title': a['title'],
              'description': a['description'],
              'price': '+${a['price'] ?? 0} MRU',
              'image': a['image'],
            },
          )
          .toList(),
      'total': '$_subtotal MRU',
      'redeemed': '-$_pointsDiscount MRU',
      'tax': '$_tax MRU',
      'totalPaid': '$_toPay MRU',
    });

    Get.to(() => const CarWashBookingSuccessScreen());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFDF9F5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9F5),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From ${widget.providerName}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF9A8E86),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildOrderCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('Washing Details'),
                      const SizedBox(height: 12),
                      _buildLocationCard(),
                      const SizedBox(height: 10),
                      _buildSlotCard(),
                      const SizedBox(height: 22),
                      _buildSaveMoreHeader(),
                      const SizedBox(height: 12),
                      _buildCouponField(),
                      const SizedBox(height: 10),
                      _buildPointsCard(),
                      const SizedBox(height: 22),
                      _sectionTitle('Payment'),
                      const SizedBox(height: 12),
                      _buildPaymentOption(
                        index: 0,
                        imageAsset: 'lib/assets/images/wallet.png',
                        title: 'SAIMPEX Wallet',
                        subtitle: 'Balance: 2,450 MRU',
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentOption(
                        index: 1,
                        imageAsset: 'lib/assets/images/currency.png',
                        title: 'Online payment',
                        subtitle: 'Card - Mobile money',
                      ),
                      const SizedBox(height: 22),
                      _buildPaymentDetailsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(bottomInset),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
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
              color: const Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF1A1A1A),
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: const Color(0xFFF0F0F0),
                        child: Image.asset(
                          widget.vehicleImage,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Color(0xFFFF5E00),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.vehicleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plateNumber,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.serviceTitle,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF6B6560),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildNestedServiceRow(
            image: widget.serviceImage,
            title: widget.serviceTitle,
            description: widget.serviceDescription,
            priceLabel: '${widget.servicePrice} MRU',
          ),
          if (widget.selectedAddons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Add-On Services',
              style: GoogleFonts.outfit(
                color: const Color(0xFF5C6578),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < widget.selectedAddons.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildNestedServiceRow(
                image: widget.selectedAddons[i]['image'] as String? ??
                    widget.serviceImage,
                title: widget.selectedAddons[i]['title'] as String? ?? 'Add-On',
                description:
                    widget.selectedAddons[i]['description'] as String? ?? '',
                priceLabel:
                    '+${widget.selectedAddons[i]['price'] ?? 0} MRU',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNestedServiceRow({
    required String image,
    required String title,
    required String description,
    required String priceLabel,
  }) {
    final isNetwork = image.startsWith('http');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isNetwork
                ? Image.network(
                    image,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  )
                : Image.asset(
                    image,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            priceLabel,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFFFF3EB),
      child: const Icon(
        Icons.local_car_wash_rounded,
        color: Color(0xFFFF5E00),
        size: 22,
      ),
    );
  }

  Widget _buildLocationCard() {
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
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.selectedLocation == 1
                  ? Icons.home_rounded
                  : Icons.storefront_rounded,
              color: const Color(0xFFFF5E00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _locationText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12,
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

  Widget _buildSlotCard() {
    return GestureDetector(
      onTap: _changeSlot,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
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
                    'Your Slot',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _slotDisplay,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildSaveMoreHeader() {
    return Row(
      children: [
        Expanded(child: _sectionTitle('Save More')),
        Text(
          'View Coupons',
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF5E00),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCouponField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          const Icon(
            Icons.local_offer_outlined,
            color: Color(0xFFFF5E00),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _couponController,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: 'Enter coupon',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFB0A59C),
                  fontSize: 13.5,
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return GestureDetector(
      onTap: () => setState(() => _usePoints = !_usePoints),
      child: Container(
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
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(7),
              child: Image.asset(
                'lib/assets/images/Coin.png',
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on_rounded,
                  color: Color(0xFFFF5E00),
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
                      color: const Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '+ $_pointsOff MRU off',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _usePoints
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFC4B8AF),
                  width: 1.8,
                ),
              ),
              alignment: Alignment.center,
              child: _usePoints
                  ? Container(
                      width: 12,
                      height: 12,
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

  Widget _buildPaymentOption({
    required int index,
    required String imageAsset,
    required String title,
    required String subtitle,
  }) {
    final selected = _paymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _paymentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF5E00)
                : Colors.transparent,
            width: 1.2,
          ),
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
            Image.asset(
              imageAsset,
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFFF5E00),
                size: 28,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFC4B8AF),
                  width: 1.8,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
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

  Widget _buildPaymentDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT DETAILS',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _paymentRow('Total', '$_subtotal MRU'),
          const SizedBox(height: 10),
          _paymentRow(
            'Redeemed points',
            '-$_pointsDiscount MRU',
            valueColor: const Color(0xFFFF5E00),
          ),
          const SizedBox(height: 10),
          _paymentRow('Tax', '$_tax MRU'),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFF4A4A4A)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'To Pay',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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

  Widget _paymentRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 14 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2E3A59),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$_toPay MRU',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pay,
            child: Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
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
                'Pay $_toPay MRU',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
