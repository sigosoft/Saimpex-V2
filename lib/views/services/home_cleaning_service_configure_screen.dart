import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_cleaning_cart_screen.dart';
import 'home_cleaning_choose_slot_sheet.dart';

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
  String? _propertyType = 'Apartment';
  int _bedrooms = 1;
  int _bathrooms = 1;
  final _notesController = TextEditingController();
  final Set<String> _selectedAddons = {};

  static const _addons = [
    {
      'id': 'window',
      'title': 'Window Cleaning',
      'price': 50,
      'durationMin': 90,
      'image': 'lib/assets/images/Kitchen Cleaning.png',
    },
    {
      'id': 'sofa',
      'title': 'Sofa Cleaning',
      'price': 50,
      'durationMin': 90,
      'image': 'lib/assets/images/Sofa Cleaning.png',
    },
  ];

  static const _included = [
    {
      'label': 'Dusting & wiping',
      'image': 'lib/assets/images/Deep Cleaning.png',
    },
    {
      'label': 'Floor cleaning',
      'image': 'lib/assets/images/bedroom_cleaning.png',
    },
    {
      'label': 'Kitchen surface cleaning',
      'image': 'lib/assets/images/Kitchen Cleaning.png',
    },
    {
      'label': 'Bathroom cleaning',
      'image': 'lib/assets/images/Deep Cleaning.png',
    },
  ];

  String get _title => widget.service['title'] ?? 'Regular Cleaning';

  int get _basePrice {
    final raw = widget.service['price'] ?? '550';
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 550;
  }

  int get _baseDurationMin {
    final raw = widget.service['duration'] ?? '1 hr 30 min';
    return _parseDurationMinutes(raw);
  }

  int get _addonsPrice => _addons
      .where((a) => _selectedAddons.contains(a['id']))
      .fold<int>(0, (sum, a) => sum + (a['price'] as int));

  int get _addonsDuration => _addons
      .where((a) => _selectedAddons.contains(a['id']))
      .fold<int>(0, (sum, a) => sum + (a['durationMin'] as int));

  int get _totalPrice => _basePrice + _addonsPrice;
  int get _totalDurationMin => _baseDurationMin + _addonsDuration;

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

  static String _formatDuration(int totalMin) {
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h > 0 && m > 0) return '$h hr $m min';
    if (h > 0) return '$h hr';
    return '$m min';
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
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        basePrice: _totalPrice,
        baseDurationMin: _totalDurationMin,
        slotDate: date,
        slotLabel: slot,
        initialAddonIds: {..._selectedAddons},
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
                        _buildHomeDetails(),
                        const SizedBox(height: 22),
                        _buildSpecialNotes(),
                        const SizedBox(height: 22),
                        _buildAddons(),
                        const SizedBox(height: 22),
                        _buildWhatsIncluded(),
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
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
            _title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 18,
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
          icon: Icons.access_time_rounded,
          label: _formatDuration(_baseDurationMin),
        ),
        const SizedBox(width: 10),
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

  Widget _buildPropertyType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Property Type [Optional]'),
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
        _propertyType = selected ? null : type;
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
        _stepperRow(
          label: 'How many bedrooms?',
          value: _bedrooms,
          onMinus: () {
            if (_bedrooms > 1) setState(() => _bedrooms--);
          },
          onPlus: () => setState(() => _bedrooms++),
        ),
        const SizedBox(height: 10),
        _stepperRow(
          label: 'How many bathrooms?',
          value: _bathrooms,
          onMinus: () {
            if (_bathrooms > 1) setState(() => _bathrooms--);
          },
          onPlus: () => setState(() => _bathrooms++),
        ),
      ],
    );
  }

  Widget _stepperRow({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _stepperButton(
            icon: Icons.remove_rounded,
            filled: false,
            onTap: onMinus,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$value',
              style: GoogleFonts.outfit(
                color: const Color(0xFF1B2B4A),
                fontSize: 16,
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

  Widget _stepperButton({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5E00) : const Color(0xFFFFF0E6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD6)),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              hintText: 'Anything the team should know?',
              hintStyle: GoogleFonts.outfit(
                color: const Color(0xFFB0A59C),
                fontSize: 13.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'e.g. Please pay extra attention to the kitchen.',
          style: GoogleFonts.outfit(
            color: const Color(0xFF9A8E86),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAddons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Make it extra clean'),
        const SizedBox(height: 12),
        for (var i = 0; i < _addons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _addonCard(_addons[i]),
        ],
      ],
    );
  }

  Widget _addonCard(Map<String, dynamic> addon) {
    final id = addon['id'] as String;
    final selected = _selectedAddons.contains(id);
    final price = addon['price'] as int;
    final durationMin = addon['durationMin'] as int;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD6)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              addon['image'] as String,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 58,
                color: const Color(0xFFFFF3EB),
                child: const Icon(
                  Icons.cleaning_services_rounded,
                  color: Color(0xFFFF5E00),
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
                  addon['title'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+$price MRU',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+${_formatDuration(durationMin)}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9A8E86),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedAddons.remove(id);
              } else {
                _selectedAddons.add(id);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: selected
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: selected ? const Color(0xFFFFF0E6) : null,
                border: selected
                    ? Border.all(color: const Color(0xFFFF5E00), width: 1.2)
                    : null,
              ),
              child: Text(
                selected ? 'ADDED' : 'ADD',
                style: GoogleFonts.outfit(
                  color: selected
                      ? const Color(0xFFFF5E00)
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsIncluded() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE0D6CC))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "What's Included",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1B2B4A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE0D6CC))),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _included.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.28,
          ),
          itemBuilder: (context, index) {
            final item = _included[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      item['image']!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFF3EB),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          color: Color(0xFFFF5E00),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['label']!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            );
          },
        ),
      ],
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
                      _formatDuration(_totalDurationMin),
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
