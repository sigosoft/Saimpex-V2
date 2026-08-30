import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'car_wash_selected_vehicles_screen.dart';

class CarWashServiceConfigureScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;

  const CarWashServiceConfigureScreen({
    super.key,
    required this.service,
    this.providerName = 'CleanRide Car Wash',
  });

  @override
  State<CarWashServiceConfigureScreen> createState() =>
      _CarWashServiceConfigureScreenState();
}

class _CarWashServiceConfigureScreenState
    extends State<CarWashServiceConfigureScreen> {
  int _selectedVehicle = 0;
  final _notesController = TextEditingController();
  final Set<String> _selectedAddons = {};

  static const _vehicles = [
    {
      'label': 'Sedan',
      'price': 550,
      'image':
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400&h=280&fit=crop',
    },
    {
      'label': 'SUV',
      'price': 650,
      'image':
          'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=400&h=280&fit=crop',
    },
    {
      'label': 'Pickup',
      'price': 750,
      'image':
          'https://images.unsplash.com/photo-1559416523-140ddc3d238c?w=400&h=280&fit=crop',
    },
  ];

  static const _addons = [
    {
      'id': 'vacuum',
      'title': 'Interior Vaccum',
      'price': 50,
      'durationMin': 15,
      'image':
          'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=200&h=200&fit=crop',
    },
    {
      'id': 'tire',
      'title': 'Tire Shine',
      'price': 50,
      'durationMin': 90,
      'image':
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&h=200&fit=crop',
    },
  ];

  static const _included = [
    {
      'label': 'Exterior Wash',
      'image':
          'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?auto=format&fit=crop&w=300&h=220&q=80',
    },
    {
      'label': 'Water Rinse',
      'image':
          'https://images.pexels.com/photos/6872149/pexels-photo-6872149.jpeg?auto=compress&cs=tinysrgb&w=300&h=220&fit=crop',
    },
  ];

  String get _title => widget.service['title'] ?? 'Basic Wash';

  int get _basePrice => _vehicles[_selectedVehicle]['price'] as int;

  int get _baseDurationMin {
    final raw = widget.service['duration'] ?? '30 min';
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
    return 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=800&h=480&fit=crop';
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
    if (hours == 0 && mins == 0) return 30;
    return hours * 60 + mins;
  }

  static String _formatDuration(int totalMin) {
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h > 0 && m > 0) return '$h hr $m min';
    if (h > 0) return '$h hr';
    return '$m min';
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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12 + bottomInset + 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 12),
                      _buildInfoChips(),
                      const SizedBox(height: 22),
                      _buildVehicleType(),
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
                  color: Color(0xFF8A7E76),
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
                  'lib/assets/images/car_wash.png',
                  fit: BoxFit.contain,
                ),
              )
            : Image.asset(
                _heroImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'lib/assets/images/car_wash.png',
                  fit: BoxFit.contain,
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
          label: '$_basePrice MRU',
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
        color: const Color(0xFFE8EDFB),
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

  Widget _buildVehicleType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Vehicle Type'),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final vehicle = _vehicles[index];
              final selected = _selectedVehicle == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedVehicle = index),
                child: Container(
                  width: 118,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFE8DFD6),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14.5),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  vehicle['image'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF5F0EB),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.directions_car_rounded,
                                      color: Color(0xFFFF5E00),
                                    ),
                                  ),
                                ),
                              ),
                              if (selected)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor: Color(0xFFFF5E00),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle['label'] as String,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1B2B4A),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${vehicle['price']} MRU',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF9A8E86),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
          'e.g. Please pay extra attention to the wheels',
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
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE8DFD6)),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              addon['image'] as String,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 58,
                color: const Color(0xFFFFF3EB),
                child: const Icon(
                  Icons.local_car_wash_rounded,
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
                borderRadius: BorderRadius.circular(30),
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
                  color:
                      selected ? const Color(0xFFFF5E00) : Colors.white,
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
      children: [
        Row(
          children: [
            Expanded(child: _fadeLine(opaqueAtStart: true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "What's Included",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1B2B4A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: _fadeLine(opaqueAtStart: false)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _included.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _buildIncludedCard(_included[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildIncludedCard(Map<String, String> item) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.15,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              item['image']!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFFFF3EB),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.local_car_wash_rounded,
                  color: Color(0xFFFF5E00),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['label']!,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1B2B4A),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _fadeLine({required bool opaqueAtStart}) {
    const lineColor = Color(0xFFEAD8C9);
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: opaqueAtStart
              ? [lineColor, lineColor.withValues(alpha: 0)]
              : [lineColor.withValues(alpha: 0), lineColor],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
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
              Column(
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
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              final vehicle = _vehicles[_selectedVehicle];
              Get.to(
                () => CarWashSelectedVehiclesScreen(
                  providerName: widget.providerName,
                  serviceTitle: _title,
                  vehicleLabel: vehicle['label'] as String,
                  vehicleImage: vehicle['image'] as String,
                  price: _totalPrice,
                  durationMin: _totalDurationMin,
                ),
              );
            },
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
                'Continue',
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
}
