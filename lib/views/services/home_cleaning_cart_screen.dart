import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import 'home_cleaning_choose_slot_sheet.dart';
import 'home_cleaning_booking_success_screen.dart';
import '../../widgets/app_back_button.dart';

class HomeCleaningCartScreen extends StatefulWidget {
  final String providerName;
  final String serviceTitle;
  final String serviceImage;
  final String serviceDescription;
  final int bedrooms;
  final int bathrooms;
  final int kitchens;
  final int balconies;
  final List<Map<String, dynamic>> spaces;
  final List<Map<String, dynamic>> extras;
  final List<Map<String, dynamic>> selectedPests;
  final String productsProvider;
  final int productsFee;
  final int basePrice;
  final int baseDurationMin;
  final DateTime slotDate;
  final String slotLabel;
  final Set<String> initialAddonIds;

  const HomeCleaningCartScreen({
    super.key,
    this.providerName = 'CleanPro Elite',
    this.serviceTitle = 'Regular Cleaning',
    this.serviceImage = 'lib/assets/images/regular_cleaning.jpg',
    this.serviceDescription =
        'Standard cleaning for bedrooms, bathrooms, living...',
    this.bedrooms = 2,
    this.bathrooms = 2,
    this.kitchens = 0,
    this.balconies = 0,
    this.spaces = const [],
    this.extras = const [],
    this.selectedPests = const [],
    this.productsProvider = 'self',
    this.productsFee = 120,
    this.basePrice = 750,
    this.baseDurationMin = 90,
    required this.slotDate,
    required this.slotLabel,
    this.initialAddonIds = const {},
  });

  @override
  State<HomeCleaningCartScreen> createState() => _HomeCleaningCartScreenState();
}

class _HomeCleaningCartScreenState extends State<HomeCleaningCartScreen> {
  late DateTime _slotDate;
  late String _slotLabel;
  late String _productsProvider;
  bool _usePoints = false;
  int _paymentIndex = 0; // mandatory — Wallet selected by default
  final _couponController = TextEditingController();

  static const _tax = 10;
  static const _pointsOff = 50;

  static const _roomLabels = {
    'Bedrooms',
    'Kitchens',
    'Bathrooms / WC',
    'Balconies',
  };

  static const _defaultRates = {
    'Bedrooms': 100,
    'Kitchens': 150,
    'Bathrooms / WC': 80,
    'Balconies': 60,
    'Fridge Cleaning': 100,
    'Dish Washing': 150,
  };

  @override
  void initState() {
    super.initState();
    _slotDate = widget.slotDate;
    _slotLabel = widget.slotLabel;
    _productsProvider = widget.productsProvider;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allSourceRows {
    if (widget.spaces.isNotEmpty || widget.extras.isNotEmpty) {
      return [...widget.spaces, ...widget.extras];
    }
    final rows = <Map<String, dynamic>>[];
    if (widget.bedrooms > 0) {
      rows.add({'label': 'Bedrooms', 'rate': 100, 'qty': widget.bedrooms});
    }
    if (widget.kitchens > 0) {
      rows.add({'label': 'Kitchens', 'rate': 150, 'qty': widget.kitchens});
    }
    if (widget.bathrooms > 0) {
      rows.add({
        'label': 'Bathrooms / WC',
        'rate': 80,
        'qty': widget.bathrooms,
      });
    }
    if (widget.balconies > 0) {
      rows.add({'label': 'Balconies', 'rate': 60, 'qty': widget.balconies});
    }
    return rows;
  }

  List<Map<String, dynamic>> get _spaceRows => _allSourceRows
      .where((s) {
        final label = s['label'] as String? ?? '';
        final qty = (s['qty'] as int?) ?? 0;
        return qty > 0 && _roomLabels.contains(label);
      })
      .toList();

  List<Map<String, dynamic>> get _extraRows {
    if (widget.extras.isNotEmpty) {
      return widget.extras
          .where((s) => ((s['qty'] as int?) ?? 0) > 0)
          .toList();
    }
    return _allSourceRows
        .where((s) {
          final label = s['label'] as String? ?? '';
          final qty = (s['qty'] as int?) ?? 0;
          return qty > 0 &&
              !_roomLabels.contains(label) &&
              label != 'Cleaning Products';
        })
        .toList();
  }

  int _rowTotal(Map<String, dynamic> s) {
    final label = s['label'] as String? ?? '';
    final rate =
        (s['rate'] as int?) ?? (_defaultRates[label] ?? 0);
    final qty = (s['qty'] as int?) ?? 0;
    return rate * qty;
  }

  int get _spacesTotal =>
      _spaceRows.fold<int>(0, (sum, s) => sum + _rowTotal(s));

  int get _extrasTotal =>
      _extraRows.fold<int>(0, (sum, s) => sum + _rowTotal(s));

  int get _productsTotal =>
      _productsProvider == 'provider' ? widget.productsFee : 0;

  int get _subtotal => _spacesTotal + _extrasTotal + _productsTotal;
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

  String _slotRangeFromLabel(String label) {
    final match = RegExp(
      r'(\d+)\s*-\s*(\d+)\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (match == null) return label;
    final start = match.group(1)!;
    final end = match.group(2)!;
    final period = match.group(3)!.toUpperCase();
    return '$start:00 $period - $end:00 $period';
  }

  Future<void> _changeSlot() async {
    final result = await HomeCleaningChooseSlotSheet.show(context);
    if (result == null) return;
    setState(() {
      _slotDate = result['date'] as DateTime;
      _slotLabel = _slotRangeFromLabel(result['slot'] as String);
    });
  }

  bool get _isPestControl =>
      widget.serviceTitle.toLowerCase().contains('pest') ||
      widget.serviceTitle.toLowerCase().contains('disinfection');

  void _clearAll() {
    Get.back();
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
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 20 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFromClearRow(),
                      const SizedBox(height: 12),
                      _buildMainServiceCard(),
                      const SizedBox(height: 22),
                      if (_spaceRows.isNotEmpty) ...[
                        _sectionTitle(
                          _isPestControl ? 'Areas to Treat' : 'Spaces',
                        ),
                        const SizedBox(height: 12),
                        _buildLineItemsCard(_spaceRows),
                        const SizedBox(height: 22),
                      ],
                      if (_isPestControl &&
                          widget.selectedPests.isNotEmpty) ...[
                        _sectionTitle('What are you facing?'),
                        const SizedBox(height: 12),
                        _buildSelectedPestsRow(),
                        const SizedBox(height: 22),
                      ],
                      if (!_isPestControl && _extraRows.isNotEmpty) ...[
                        _sectionTitle('Make it extra clean'),
                        const SizedBox(height: 12),
                        _buildLineItemsCard(_extraRows),
                        const SizedBox(height: 22),
                      ],
                      if (!_isPestControl) ...[
                        _buildCleaningProductsSection(),
                        const SizedBox(height: 22),
                      ],
                      _sectionTitle('Cleaning Details'),
                      const SizedBox(height: 12),
                      _buildAddressCard(),
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
                        subtitle: 'Card • Mobile money',
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
            child: AppBackButton(onTap: () => Get.back()),
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

  Widget _buildFromClearRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'From ${widget.providerName}',
            style: GoogleFonts.outfit(
              color: const Color(0xFF9A8E86),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: _clearAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF5E00),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Clear All',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF1A1A1A),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildMainServiceCard() {
    final image = widget.serviceImage;
    final isNetwork = image.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(
                    image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(72),
                  )
                : Image.asset(
                    image,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(72),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.serviceTitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Edit',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.serviceDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsCard(List<Map<String, dynamic>> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _spaceRow(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedPestsRow() {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.selectedPests.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final pest = widget.selectedPests[index];
          final label = pest['label'] as String? ?? '';
          final image = pest['image'] as String?;
          return Container(
            width: 100,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFC9A8)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: image != null
                      ? Image.asset(
                          image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.bug_report_outlined,
                            color: Color(0xFF2B5A9E),
                            size: 22,
                          ),
                        )
                      : Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1B2B4A),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.north_east_rounded,
                            color: Color(0xFF1B2B4A),
                            size: 14,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCleaningProductsSection() {
    final providerSelected = _productsProvider == 'provider';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Cleaning Products')),
            Text(
              providerSelected ? '+${widget.productsFee} MRU' : '0 MRU',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFFD8C2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF5E00),
                        width: 1.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerSelected
                              ? 'Provider will provide products'
                              : "I'll provide the products",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          providerSelected
                              ? 'Cleaning products will be provided by the service provider'
                              : 'Standard cleaning prices apply. You provide detergents, mop, and cloths',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF8A7E76),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() {
                  _productsProvider =
                      providerSelected ? 'self' : 'provider';
                }),
                child: Text(
                  providerSelected
                      ? "Switch to 'I'll provide' (0 MRU)"
                      : "Switch to 'Provider will provide' (+${widget.productsFee} MRU)",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _spaceRow(Map<String, dynamic> space) {
    final label = space['label'] as String? ?? '';
    final rate = (space['rate'] as int?) ?? (_defaultRates[label] ?? 0);
    final qty = (space['qty'] as int?) ?? 0;
    final total = rate * qty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$rate MRU x$qty',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$total MRU',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            child: const Icon(
              Icons.home_rounded,
              color: Color(0xFFFF5E00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SelectLocationController.selectedTitle.isNotEmpty
                      ? SelectLocationController.selectedTitle
                      : 'Sahara View Home',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SelectLocationController.selectedSubtitle.isNotEmpty
                      ? SelectLocationController.selectedSubtitle
                      : 'Near Marhaba Supermarket, Nouakchott',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Edit',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF5E00), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 22,
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
                      color: const Color(0xFF6B6B6B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFFF5E00),
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
              style: GoogleFonts.outfit(fontSize: 13.5),
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
            Image.asset(
              'lib/assets/images/Coin.png',
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.monetization_on_rounded,
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
                    'Use 500 points',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '= $_pointsOff MRU off',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
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
      onTap: () => setState(() {
        // Payment type is mandatory — switch between options, never clear.
        _paymentIndex = index;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
              alignment: Alignment.center,
              child: Image.asset(
                imageAsset,
                width: 20,
                height: 20,
                color: const Color(0xFFFF5E00),
                errorBuilder: (_, __, ___) => Icon(
                  index == 0
                      ? Icons.account_balance_wallet_outlined
                      : Icons.credit_card_rounded,
                  color: const Color(0xFFFF5E00),
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
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(32),
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
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Total', '$_subtotal MRU'),
          const SizedBox(height: 10),
          _detailRow(
            'Redeemed points',
            '-$_pointsDiscount MRU',
            valueColor: const Color(0xFFFF5E00),
          ),
          const SizedBox(height: 10),
          _detailRow('Tax', '$_tax MRU'),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF4A4A4A), height: 1),
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

  Widget _detailRow(String label, String value, {Color? valueColor}) {
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
            fontWeight: FontWeight.w600,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
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
              color: const Color(0xFF8A7E76),
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
            onTap: () {
              Get.to(() => const HomeCleaningBookingSuccessScreen());
            },
            child: Container(
              width: double.infinity,
              height: 54,
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Pay $_toPay MRU',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFFFF3EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.cleaning_services_rounded,
        color: Color(0xFFFF5E00),
      ),
    );
  }
}
