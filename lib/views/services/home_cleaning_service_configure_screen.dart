import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_cleaning_cart_screen.dart';
import 'home_cleaning_choose_slot_sheet.dart';
import '../../widgets/app_back_button.dart';

class HomeCleaningServiceConfigureScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;

  const HomeCleaningServiceConfigureScreen({
    super.key,
    required this.service,
    this.providerName = 'CleanPro Elite',
  });

  @override
  State<HomeCleaningServiceConfigureScreen> createState() =>
      _HomeCleaningServiceConfigureScreenState();
}

class _HomeCleaningServiceConfigureScreenState
    extends State<HomeCleaningServiceConfigureScreen> {
  String _propertyType = 'Apartment';
  int _bedrooms = 4;
  int _kitchens = 1;
  int _bathrooms = 0;
  int _balconies = 0;
  /// `self` = customer provides, `provider` = provider provides (+120)
  String _productsProvider = 'self';
  final _notesController = TextEditingController();
  int _fridgeCleaning = 0;
  int _dishWashing = 0;
  final Set<String> _selectedPests = {};

  static const _roomRates = [
    {
      'key': 'bedrooms',
      'label': 'Bedrooms',
      'unitLabel': '100 MRU / Room',
      'rate': 100,
    },
    {
      'key': 'kitchens',
      'label': 'Kitchens',
      'unitLabel': '150 MRU / Room',
      'rate': 150,
    },
    {
      'key': 'bathrooms',
      'label': 'Bathrooms / WC',
      'unitLabel': '80 MRU / Room',
      'rate': 80,
    },
    {
      'key': 'balconies',
      'label': 'Balconies',
      'unitLabel': '60 MRU / Unit',
      'rate': 60,
    },
  ];

  static const _extraClean = [
    {
      'key': 'fridge',
      'label': 'Fridge Cleaning',
      'unitLabel': '100 MRU / Unit',
      'rate': 100,
    },
    {
      'key': 'dish',
      'label': 'Dish Washing',
      'unitLabel': '150 MRU / Unit',
      'rate': 150,
    },
  ];

  static const _pestIssues = [
    {
      'id': 'cockroaches',
      'label': 'Cockroaches',
      'image': 'lib/assets/images/Cockroach.png',
    },
    {
      'id': 'ants',
      'label': 'Ants',
      'image': 'lib/assets/images/Ant.png',
    },
    {
      'id': 'bed_bugs',
      'label': 'Bed Bugs',
      'image': 'lib/assets/images/BedBug.png',
    },
    {
      'id': 'mosquitoes',
      'label': 'Mosquitoes',
      'image': 'lib/assets/images/Mosquito.png',
    },
    {
      'id': 'rodents',
      'label': 'Rodents',
      'image': 'lib/assets/images/Rodent.png',
    },
    {
      'id': 'termites',
      'label': 'Termites',
      'image': 'lib/assets/images/Termite.png',
    },
    {
      'id': 'disinfection',
      'label': 'General Disinfection',
      'image': 'lib/assets/images/BlueShield.png',
    },
    {
      'id': 'flies',
      'label': 'Flies',
      'image': 'lib/assets/images/Fly.png',
    },
    {
      'id': 'other',
      'label': 'Other',
    },
  ];

  String get _title => widget.service['title'] ?? 'Regular Cleaning';

  bool get _isPestControl =>
      _title.toLowerCase().contains('pest') ||
      _title.toLowerCase().contains('disinfection');

  int get _basePrice {
    final raw = widget.service['price'] ?? '550';
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 550;
  }

  int get _baseDurationMin {
    final raw = widget.service['duration'] ?? '1 hr 30 min';
    return _parseDurationMinutes(raw);
  }

  int get _roomsPrice =>
      _bedrooms * 100 + _kitchens * 150 + _bathrooms * 80 + _balconies * 60;

  int get _productsPrice => _productsProvider == 'provider' ? 120 : 0;

  int get _extrasPrice =>
      _isPestControl ? 0 : (_fridgeCleaning * 100 + _dishWashing * 150);

  int get _totalPrice =>
      _roomsPrice + (_isPestControl ? 0 : _productsPrice) + _extrasPrice;
  int get _totalDurationMin => _baseDurationMin;

  String get _heroImage {
    final image = widget.service['image'];
    if (image != null && image.isNotEmpty) return image;
    return 'lib/assets/images/cleanproelitee.jpg';
  }

  bool get _heroIsNetwork => _heroImage.startsWith('http');

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  static int _parseDurationMinutes(String raw) {
    var hours = 0;
    var mins = 0;
    final hourMatch = RegExp(r'(\d+)\s*hr').firstMatch(raw);
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(raw);
    if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
    if (minMatch != null) mins = int.parse(minMatch.group(1)!);
    if (hours == 0 && mins == 0) return 90;
    return hours * 60 + mins;
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

  Future<void> _openSlotAndGoToCart() async {
    final result = await HomeCleaningChooseSlotSheet.show(context);
    if (result == null || !mounted) return;

    final date = result['date'] as DateTime;
    final slot = _slotRangeFromLabel(result['slot'] as String);

    Get.to(
      () => HomeCleaningCartScreen(
        providerName: widget.providerName,
        serviceTitle: _title,
        serviceImage: _heroImage,
        serviceDescription: _isPestControl
            ? 'Pest control & disinfection handled by a specialized team'
            : 'Standard cleaning for bedrooms, bathrooms, living...',
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        kitchens: _kitchens,
        balconies: _balconies,
        spaces: [
          if (_bedrooms > 0)
            {'label': 'Bedrooms', 'rate': 100, 'qty': _bedrooms},
          if (_kitchens > 0)
            {'label': 'Kitchens', 'rate': 150, 'qty': _kitchens},
          if (_bathrooms > 0)
            {'label': 'Bathrooms / WC', 'rate': 80, 'qty': _bathrooms},
          if (_balconies > 0)
            {'label': 'Balconies', 'rate': 60, 'qty': _balconies},
        ],
        extras: [
          if (!_isPestControl && _fridgeCleaning > 0)
            {
              'label': 'Fridge Cleaning',
              'rate': 100,
              'qty': _fridgeCleaning,
            },
          if (!_isPestControl && _dishWashing > 0)
            {
              'label': 'Dish Washing',
              'rate': 150,
              'qty': _dishWashing,
            },
        ],
        productsProvider: _isPestControl ? 'self' : _productsProvider,
        productsFee: 120,
        selectedPests: _isPestControl
            ? _pestIssues
                .where((p) => _selectedPests.contains(p['id']))
                .map(
                  (p) => {
                    'id': p['id'],
                    'label': p['label'],
                    if (p['image'] != null) 'image': p['image'],
                  },
                )
                .toList()
            : const [],
        basePrice: _totalPrice,
        baseDurationMin: _totalDurationMin,
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
        statusBarColor: Color(0xFFFFEDE5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEDE5), Color(0xFFFAF6F0), Color(0xFFFAF6F0)],
            stops: [0.0, 0.22, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset + 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 12),
                        _buildInfoChips(),
                        const SizedBox(height: 22),
                        _buildPropertyType(),
                        const SizedBox(height: 22),
                        if (_isPestControl) ...[
                          _buildPestFacing(),
                          const SizedBox(height: 22),
                          _buildAreasToTreat(),
                          const SizedBox(height: 22),
                          _buildSpecialNotes(),
                        ] else ...[
                          _buildHomeDetails(),
                          const SizedBox(height: 22),
                          _buildCleaningProducts(),
                          const SizedBox(height: 22),
                          _buildAddons(),
                          const SizedBox(height: 22),
                          _buildSpecialNotes(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(bottomInset),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
            _title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: _isPestControl ? 15.5 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _heroIsNetwork
            ? Image.network(
                _heroImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'lib/assets/images/cleanproelitee.jpg',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                _heroImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'lib/assets/images/cleanproelitee.jpg',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoChips() {
    return Row(
      children: [
        _infoChip(
          imageAsset: 'lib/assets/images/currency.png',
          label: 'From $_basePrice MRU',
        ),
      ],
    );
  }

  Widget _infoChip({
    IconData? icon,
    String? imageAsset,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageAsset != null)
            Image.asset(
              imageAsset,
              width: 15,
              height: 15,
              color: const Color(0xFFFF5E00),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_wallet_outlined,
                size: 15,
                color: Color(0xFFFF5E00),
              ),
            )
          else
            Icon(icon, size: 15, color: const Color(0xFFFF5E00)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2B5A9E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
        color: const Color(0xFF1B2B4A),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _sectionTitleWithOptional(String title) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' (Optional)',
            style: GoogleFonts.outfit(
              color: const Color(0xFF6B6B6B),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitleWithOptional('Property Type'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _propertyCard(
                type: 'Apartment',
                icon: Icons.apartment_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _propertyCard(
                type: 'Villa',
                icon: Icons.home_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _propertyCard({required String type, required IconData icon}) {
    final selected = _propertyType == type;
    return GestureDetector(
      onTap: () => setState(() {
        // Property type is mandatory — switch between options, never clear.
        _propertyType = type;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFFF5E00) : const Color(0xFFE8DFD6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFB0A59C),
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              color: selected
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFF8A7E76),
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                type,
                style: GoogleFonts.outfit(
                  color: selected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFF1B2B4A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tell us about your home'),
        const SizedBox(height: 12),
        _buildRoomRatesCard(),
      ],
    );
  }

  Widget _buildAreasToTreat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Select Areas to Treat'),
        const SizedBox(height: 12),
        for (var i = 0; i < _roomRates.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _areaTreatCard(_roomRates[i]),
        ],
      ],
    );
  }

  Widget _buildRoomRatesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < _roomRates.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF0E8DF),
                indent: 16,
                endIndent: 16,
              ),
            _roomRateRow(_roomRates[i]),
          ],
        ],
      ),
    );
  }

  Widget _areaTreatCard(Map<String, Object> room) {
    final key = room['key'] as String;
    final rate = room['rate'] as int;
    final count = _roomCountFor(key);
    final lineTotal = count * rate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['label'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  room['unitLabel'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _areaStepper(
            value: count,
            onMinus: () => _setRoomCount(key, count - 1),
            onPlus: () => _setRoomCount(key, count + 1),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              '$lineTotal MRU',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pest mock: minus/plus without beige pill wrapper
  Widget _areaStepper({
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove_rounded,
          filled: false,
          onTap: onMinus,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add_rounded,
          filled: true,
          onTap: onPlus,
        ),
      ],
    );
  }

  Widget _buildPestFacing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('What are you facing?'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pestIssues.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final item = _pestIssues[index];
            final id = item['id'] as String;
            final selected = _selectedPests.contains(id);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedPests.remove(id);
                } else {
                  _selectedPests.add(id);
                }
              }),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFF5E00)
                        : const Color(0xFFEDE4DA),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFF0E6)
                            : const Color(0xFFE8F2FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: item['image'] != null
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                item['image'] as String,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.bug_report_outlined,
                                  size: 22,
                                  color: selected
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFF2B5A9E),
                                ),
                              ),
                            )
                          : Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFF1B2B4A),
                                  width: 1.6,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.north_east_rounded,
                                size: 14,
                                color: selected
                                    ? const Color(0xFFFF5E00)
                                    : const Color(0xFF1B2B4A),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1B2B4A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _roomCountFor(String key) {
    switch (key) {
      case 'bedrooms':
        return _bedrooms;
      case 'kitchens':
        return _kitchens;
      case 'bathrooms':
        return _bathrooms;
      case 'balconies':
        return _balconies;
      default:
        return 0;
    }
  }

  void _setRoomCount(String key, int value) {
    final next = value < 0 ? 0 : value;
    setState(() {
      switch (key) {
        case 'bedrooms':
          _bedrooms = next;
          break;
        case 'kitchens':
          _kitchens = next;
          break;
        case 'bathrooms':
          _bathrooms = next;
          break;
        case 'balconies':
          _balconies = next;
          break;
      }
    });
  }

  Widget _roomRateRow(Map<String, Object> room) {
    final key = room['key'] as String;
    final rate = room['rate'] as int;
    final count = _roomCountFor(key);
    final lineTotal = count * rate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['label'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  room['unitLabel'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _pillStepper(
            value: count,
            onMinus: () => _setRoomCount(key, count - 1),
            onPlus: () => _setRoomCount(key, count + 1),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              '$lineTotal MRU',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillStepper({
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0E8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            icon: Icons.remove_rounded,
            filled: false,
            onTap: onMinus,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _stepperButton(
            icon: Icons.add_rounded,
            filled: true,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Who provides the cleaning products?'),
        const SizedBox(height: 12),
        _productOptionCard(
          id: 'self',
          title: "I'll provide the products",
          description:
              'Standard cleaning prices apply. You provide detergents, mop, and cloths',
          priceLabel: '0 MRU',
          priceOrange: false,
        ),
        const SizedBox(height: 12),
        _productOptionCard(
          id: 'provider',
          title: 'Provider will provide products',
          description:
              'Cleaning products will be provided by the service provider',
          priceLabel: '+120MRU',
          priceOrange: true,
        ),
      ],
    );
  }

  Widget _productOptionCard({
    required String id,
    required String title,
    required String description,
    required String priceLabel,
    required bool priceOrange,
  }) {
    final selected = _productsProvider == id;
    return GestureDetector(
      onTap: () => setState(() => _productsProvider = id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEDE4DA),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1B2B4A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              priceLabel,
              style: GoogleFonts.outfit(
                color: priceOrange
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFF1B2B4A),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5E00) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: filled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : const Color(0xFFFF5E00),
        ),
      ),
    );
  }

  Widget _buildSpecialNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Special Notes'),
        const SizedBox(height: 12),
        Container(
          height: 120,
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
          child: Stack(
            children: [
              TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1B2B4A),
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      '(e.g. Please pay extra attention to the kitchen)',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFB0A59C),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 52, 14),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/Voice.png',
                    width: 15,
                    height: 15,
                    color: const Color(0xFFFF5E00),
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.settings_voice_rounded,
                      color: Color(0xFFFF5E00),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitleWithOptional('Make it extra clean'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < _extraClean.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _extraCleanRow(_extraClean[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  int _extraCountFor(String key) {
    switch (key) {
      case 'fridge':
        return _fridgeCleaning;
      case 'dish':
        return _dishWashing;
      default:
        return 0;
    }
  }

  void _setExtraCount(String key, int value) {
    final next = value < 0 ? 0 : value;
    setState(() {
      switch (key) {
        case 'fridge':
          _fridgeCleaning = next;
          break;
        case 'dish':
          _dishWashing = next;
          break;
      }
    });
  }

  Widget _extraCleanRow(Map<String, Object> item) {
    final key = item['key'] as String;
    final rate = item['rate'] as int;
    final count = _extraCountFor(key);
    final lineTotal = count * rate;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                  item['label'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['unitLabel'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _pillStepper(
            value: count,
            onMinus: () => _setExtraCount(key, count - 1),
            onPlus: () => _setExtraCount(key, count + 1),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              '$lineTotal MRU',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        color: Colors.white,
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
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openSlotAndGoToCart,
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
                'Choose Your Slot',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15.5,
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
