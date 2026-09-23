import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'car_wash_cart_screen.dart';
import 'car_wash_choose_slot_sheet.dart';
import 'car_wash_no_vehicle_warning_dialog.dart';
import 'car_wash_selected_vehicle_sheet.dart';

class _ConfirmedVehicle {
  final String label;
  final String image;
  final int price;
  final String plateNumber;

  const _ConfirmedVehicle({
    required this.label,
    required this.image,
    required this.price,
    required this.plateNumber,
  });
}

class CarWashServiceConfigureScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;
  final int selectedLocation;
  final int homeServiceFee;
  final String homeInstructions;
  final String serviceAddress;

  const CarWashServiceConfigureScreen({
    super.key,
    required this.service,
    this.providerName = 'CleanRide Car Wash',
    this.selectedLocation = 0,
    this.homeServiceFee = 0,
    this.homeInstructions = '',
    this.serviceAddress = '',
  });

  @override
  State<CarWashServiceConfigureScreen> createState() =>
      _CarWashServiceConfigureScreenState();
}

class _CarWashServiceConfigureScreenState
    extends State<CarWashServiceConfigureScreen> {
  /// 0 = At Wash Station, 1 = At Home/Workplace
  late int _selectedLocation;
  int _selectedVehicle = -1;
  final _notesController = TextEditingController();
  final Set<String> _selectedAddons = {};
  final List<_ConfirmedVehicle> _confirmedVehicles = [];
  final _vehicleTypeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;
  }

  static const _vehicles = [
    {
      'label': 'Sedan',
      'price': 550,
      'image': 'lib/assets/images/Sedan.png',
    },
    {
      'label': 'SUV',
      'price': 650,
      'image': 'lib/assets/images/SUV.png',
    },
    {
      'label': 'Pickup',
      'price': 750,
      'image': 'lib/assets/images/Pickup.png',
    },
  ];

  static const _addons = [
    {
      'id': 'engine',
      'title': 'Engine Wash',
      'description':
          'Safe hydraulic degreasing and rinse for bay components without water damage.',
      'price': 50,
      'durationMin': 15,
      'image':
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=200&h=200&fit=crop',
    },
  ];

  String get _title => widget.service['title'] ?? 'Exterior Wash';

  int get _serviceBasePrice {
    final raw = widget.service['price'] ?? '550 MRU';
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 550;
  }

  int get _baseDurationMin {
    final raw = widget.service['duration'] ?? '30 min';
    return _parseDurationMinutes(raw);
  }

  int get _vehiclesPrice => _confirmedVehicles.isEmpty
      ? _serviceBasePrice
      : _confirmedVehicles.fold<int>(0, (sum, v) => sum + v.price);

  int get _vehiclesDuration => _confirmedVehicles.isEmpty
      ? _baseDurationMin
      : _confirmedVehicles.length * _baseDurationMin;

  bool get _hasVehicle => _confirmedVehicles.isNotEmpty;

  int get _locationFee =>
      _selectedLocation == 1
          ? (widget.homeServiceFee > 0 ? widget.homeServiceFee : 150)
          : 0;

  int get _addonsPrice => _addons
      .where((a) => _selectedAddons.contains(a['id']))
      .fold<int>(0, (sum, a) => sum + (a['price'] as int));

  int get _addonsDuration => _addons
      .where((a) => _selectedAddons.contains(a['id']))
      .fold<int>(0, (sum, a) => sum + (a['durationMin'] as int));

  int get _totalPrice => _vehiclesPrice + _locationFee + _addonsPrice;
  int get _totalDurationMin => _vehiclesDuration + _addonsDuration;

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

  String _slotRangeFromLabel(String label) {
    final match = RegExp(
      r'(\d+)\s*[–-]\s*(\d+)\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(label);
    if (match == null) return label;
    final start = match.group(1)!;
    final end = match.group(2)!;
    final period = match.group(3)!.toUpperCase();
    return '$start:00 $period - $end:00 $period';
  }

  Future<void> _openSelectedVehicleSheet(int index) async {
    final vehicle = _vehicles[index];
    setState(() {
      _selectedVehicle = index;
    });

    final plate = await showCarWashSelectedVehicleSheet(
      context,
      label: vehicle['label'] as String,
      image: vehicle['image'] as String,
      price: vehicle['price'] as int,
    );

    if (!mounted) return;

    if (plate == null) {
      setState(() {
        if (_confirmedVehicles.isEmpty) {
          _selectedVehicle = -1;
        } else {
          final lastLabel = _confirmedVehicles.last.label;
          _selectedVehicle = _vehicles.indexWhere(
            (v) => v['label'] == lastLabel,
          );
        }
      });
      return;
    }

    setState(() {
      _confirmedVehicles.add(
        _ConfirmedVehicle(
          label: vehicle['label'] as String,
          image: vehicle['image'] as String,
          price: vehicle['price'] as int,
          plateNumber: plate,
        ),
      );
    });
  }

  Future<void> _continueToSelectSlot() async {
    if (!_hasVehicle) {
      final addVehicle = await showNoVehicleWarningDialog(context);
      if (addVehicle == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _vehicleTypeKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: 0.15,
            );
          }
        });
      }
      return;
    }

    final result = await CarWashChooseSlotSheet.show(context);
    if (result == null || !mounted) return;

    final first = _confirmedVehicles.first;
    Get.to(
      () => CarWashCartScreen(
        providerName: widget.providerName,
        serviceTitle: _title,
        vehicleLabel: first.label,
        vehicleImage: first.image,
        basePrice: _totalPrice,
        baseDurationMin: _totalDurationMin,
        slotDate: result['date'] as DateTime,
        slotLabel: _slotRangeFromLabel(result['slot'] as String),
        initialAddonIds: Set<String>.from(_selectedAddons),
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
                      if (_confirmedVehicles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        for (var i = 0; i < _confirmedVehicles.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _buildConfirmedVehicleCard(_confirmedVehicles[i]),
                        ],
                        const SizedBox(height: 16),
                        _buildAddAnotherVehicle(),
                      ],
                      const SizedBox(height: 22),
                      _buildSpecialNotes(),
                      const SizedBox(height: 22),
                      _buildAddons(),
                      const SizedBox(height: 8),
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
                  border: Border.all(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.2),
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
            _title,
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

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
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
          icon: Icons.receipt_long_rounded,
          label: '$_serviceBasePrice MRU',
        ),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
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
        color: const Color(0xFF1A1A1A),
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _radio({required bool selected}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? const Color(0xFFFF5E00)
              : const Color(0xFFC4B8AF),
          width: selected ? 1.8 : 1.5,
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
    );
  }

  Widget _buildVehicleType() {
    const cardRadius = 28.0;

    return Column(
      key: _vehicleTypeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Vehicle Type'),
        const SizedBox(height: 12),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final vehicle = _vehicles[index];
              final selected = _selectedVehicle == index;
              final borderWidth = selected ? 1.8 : 1.0;

              return GestureDetector(
                onTap: () => _openSelectedVehicleSheet(index),
                child: Container(
                  width: 136,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFF0EA)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFE8DFD6),
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      cardRadius - borderWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                vehicle['image'] as String,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF5F0EB),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: Color(0xFFFF5E00),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: _radio(selected: selected),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle['label'] as String,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1A1A1A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${vehicle['price']} MRU',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF9A8E86),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedVehicleCard(_ConfirmedVehicle vehicle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    vehicle.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF5F0EB),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Color(0xFFFF5E00),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: Text(
                        vehicle.label,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
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
                  vehicle.plateNumber,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF9A8E86),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_baseDurationMin),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A8E86),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${vehicle.price} MRU',
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

  Widget _buildAddAnotherVehicle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3EB), Color(0xFFFFE8D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFFF5E00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Another Vehicle',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Do you have another vehicle you'd like to wash?",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A7E76),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _openSelectedVehicleSheet(
              _selectedVehicle >= 0 ? _selectedVehicle : 0,
            ),
            child: Container(
              width: double.infinity,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'ADD',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
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
              color: const Color(0xFF1A1A1A),
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
        _sectionTitle('Add-on'),
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
    final description = addon['description'] as String? ?? '';

    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedAddons.remove(id);
        } else {
          _selectedAddons.add(id);
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                addon['image'] as String,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
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
                      color: const Color(0xFF1A1A1A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8A7E76),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '+$price MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '  •  ',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF9A8E86),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '+${_formatDuration(durationMin)}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF9A8E86),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _radio(selected: selected),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 14 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
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
                      color: const Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _continueToSelectSlot,
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
                'Continue to Select Slot',
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
