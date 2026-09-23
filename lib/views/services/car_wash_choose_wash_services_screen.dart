import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'car_wash_add_vehicles_sheet.dart';
import 'car_wash_cart_screen.dart';
import 'car_wash_choose_slot_sheet.dart';
import '../../widgets/app_back_button.dart';

class _VehicleWashConfig {
  int selectedService = 0;
  final Set<int> selectedAddons = {};
  final TextEditingController notesController = TextEditingController();

  void dispose() => notesController.dispose();
}

class CarWashChooseWashServicesScreen extends StatefulWidget {
  final List<CarWashAddedVehicle> vehicles;
  final String providerName;
  final int selectedLocation;
  final int homeServiceFee;
  final String homeInstructions;
  final String serviceAddress;

  const CarWashChooseWashServicesScreen({
    super.key,
    required this.vehicles,
    this.providerName = 'CleanRide Car Wash',
    this.selectedLocation = 0,
    this.homeServiceFee = 0,
    this.homeInstructions = '',
    this.serviceAddress = '',
  });

  CarWashAddedVehicle get vehicle => vehicles.first;

  @override
  State<CarWashChooseWashServicesScreen> createState() =>
      _CarWashChooseWashServicesScreenState();
}

class _CarWashChooseWashServicesScreenState
    extends State<CarWashChooseWashServicesScreen> {
  late final List<_VehicleWashConfig> _configs;

  static const _services = [
    {
      'title': 'Exterior Wash',
      'description':
          'High pressure snow foam, detailed rim cleaning & streak-free hand dry',
      'durationMin': 30,
      'image':
          'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=300&h=300&fit=crop',
    },
    {
      'title': 'Interior Wash',
      'description':
          'Deep antimicrobial vacuum, UV dashboard polish & crystal glass cleaning',
      'durationMin': 30,
      'image':
          'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=300&h=300&fit=crop',
    },
    {
      'title': 'Full Wash',
      'description':
          'Complete interior & exterior detailing with premium ceramic tire gloss',
      'durationMin': 45,
      'image':
          'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=300&h=300&fit=crop',
    },
  ];

  /// Exterior, Interior, Full — by vehicle type.
  static const _servicePricesByType = {
    'sedan': [350, 350, 690],
    'suv/4x4': [500, 400, 850],
    'pickup': [550, 450, 900],
    'mini bus': [750, 650, 1250],
  };

  List<int> _pricesForVehicle(CarWashAddedVehicle vehicle) {
    final key = vehicle.label.trim().toLowerCase();
    if (_servicePricesByType.containsKey(key)) {
      return _servicePricesByType[key]!;
    }
    if (key.contains('suv') || key.contains('4x4')) {
      return _servicePricesByType['suv/4x4']!;
    }
    if (key.contains('pickup')) {
      return _servicePricesByType['pickup']!;
    }
    if (key.contains('mini') || key.contains('bus')) {
      return _servicePricesByType['mini bus']!;
    }
    return _servicePricesByType['sedan']!;
  }

  int _servicePriceFor(CarWashAddedVehicle vehicle, int serviceIndex) {
    return _pricesForVehicle(vehicle)[serviceIndex];
  }

  static const _addons = [
    {
      'title': 'Engine Wash',
      'description':
          'Safe hydraulic degreasing and rinse for bay components without water damage.',
      'price': 50,
      'durationMin': 15,
      'image':
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=200&h=200&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _configs = List.generate(
      widget.vehicles.length,
      (_) => _VehicleWashConfig(),
    );
  }

  @override
  void dispose() {
    for (final config in _configs) {
      config.dispose();
    }
    super.dispose();
  }

  int _vehiclePrice(CarWashAddedVehicle vehicle, _VehicleWashConfig config) {
    final servicePrice = _servicePriceFor(vehicle, config.selectedService);
    final addonsPrice = config.selectedAddons.fold<int>(
      0,
      (sum, i) => sum + (_addons[i]['price'] as int),
    );
    return servicePrice + addonsPrice;
  }

  int _vehicleDuration(_VehicleWashConfig config) {
    final serviceDuration =
        _services[config.selectedService]['durationMin'] as int;
    final addonsDuration = config.selectedAddons.fold<int>(
      0,
      (sum, i) => sum + (_addons[i]['durationMin'] as int),
    );
    return serviceDuration + addonsDuration;
  }

  int get _totalPrice {
    var sum = widget.homeServiceFee;
    for (var i = 0; i < _configs.length; i++) {
      sum += _vehiclePrice(widget.vehicles[i], _configs[i]);
    }
    return sum;
  }

  int get _totalDuration =>
      _configs.fold<int>(0, (sum, c) => sum + _vehicleDuration(c));

  String _slotRangeFromLabel(String label) {
    // Already formatted as "8:00-10:00 AM" from Choose Your Slot.
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
    final start = short.group(1)!;
    final end = short.group(2)!;
    final period = short.group(3)!.toUpperCase();
    return '$start:00 $period - $end:00 $period';
  }

  Future<void> _continueToSelectSlot() async {
    final result = await CarWashChooseSlotSheet.show(context);
    if (result == null || !mounted) return;

    final first = widget.vehicles.first;
    final firstConfig = _configs.first;
    final service = _services[firstConfig.selectedService];
    final servicePrice = _servicePriceFor(first, firstConfig.selectedService);

    final addons = firstConfig.selectedAddons.map((i) {
      final a = _addons[i];
      return {
        'title': a['title'],
        'description': a['description'],
        'price': a['price'],
        'image': a['image'],
        'durationMin': a['durationMin'],
      };
    }).toList();

    // Multi-vehicle: fold remaining services into base/service totals.
    var extrasService = 0;
    final extraAddons = <Map<String, dynamic>>[];
    for (var i = 1; i < widget.vehicles.length; i++) {
      final v = widget.vehicles[i];
      final c = _configs[i];
      extrasService += _servicePriceFor(v, c.selectedService);
      for (final ai in c.selectedAddons) {
        final a = _addons[ai];
        extraAddons.add({
          'title': '${a['title']} (${v.label})',
          'description': a['description'],
          'price': a['price'],
          'image': a['image'],
          'durationMin': a['durationMin'],
        });
      }
    }

    Get.to(
      () => CarWashCartScreen(
        providerName: widget.providerName,
        serviceTitle: service['title'] as String,
        serviceDescription: service['description'] as String,
        serviceImage: service['image'] as String,
        vehicleLabel: first.label,
        vehicleImage: first.image,
        plateNumber: first.plateNumber,
        servicePrice: servicePrice + extrasService,
        basePrice: _totalPrice,
        baseDurationMin: _totalDuration,
        slotDate: result['date'] as DateTime,
        slotLabel: _slotRangeFromLabel(result['slot'] as String),
        selectedAddons: [...addons, ...extraAddons],
        selectedLocation: widget.selectedLocation,
        serviceAddress: widget.serviceAddress,
        homeServiceFee: widget.homeServiceFee,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFE5D9),
                Color(0xFFFFF3EB),
                Color(0xFFFFFBF9),
              ],
              stops: [0.0, 0.28, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: widget.vehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildVehicleCard(
                        widget.vehicles[index],
                        _configs[index],
                      );
                    },
                  ),
                ),
                _buildBottomBar(bottomInset),
              ],
            ),
          ),
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
            'Choose Wash Services',
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

  Widget _buildVehicleCard(
    CarWashAddedVehicle vehicle,
    _VehicleWashConfig config,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleHeader(vehicle),
          const SizedBox(height: 18),
          _sectionTitle('Services'),
          const SizedBox(height: 10),
          for (var i = 0; i < _services.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildServiceCard(vehicle, config, i),
          ],
          const SizedBox(height: 18),
          _sectionTitle('Add-On Services'),
          const SizedBox(height: 10),
          for (var i = 0; i < _addons.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildAddonCard(config, i),
          ],
          const SizedBox(height: 18),
          _sectionTitle('Special Notes'),
          const SizedBox(height: 10),
          _buildNotesField(config),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(CarWashAddedVehicle vehicle) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: const Color(0xFFF0F0F0),
            child: Image.asset(
              vehicle.image,
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: const Color(0xFFF5F0EB),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFFFF5E00),
                ),
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
                vehicle.label,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                vehicle.plateNumber,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8A7E76),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
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
        color: const Color(0xFF6B6560),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _radio({required bool selected}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? const Color(0xFFFF5E00)
              : const Color(0xFFC4B8AF),
          width: selected ? 1.8 : 1.4,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _buildServiceCard(
    CarWashAddedVehicle vehicle,
    _VehicleWashConfig config,
    int index,
  ) {
    final item = _services[index];
    final selected = config.selectedService == index;
    final price = _servicePriceFor(vehicle, index);

    return GestureDetector(
      onTap: () => setState(() => config.selectedService = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF2E9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFE5E5E5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item['image'] as String,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFFFF3EB),
                  child: const Icon(
                    Icons.local_car_wash_rounded,
                    color: Color(0xFFFF5E00),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (selected) _radio(selected: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String,
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
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$price MRU',
              style: GoogleFonts.outfit(
                color: selected
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFF1A1A1A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonCard(_VehicleWashConfig config, int index) {
    final item = _addons[index];
    final selected = config.selectedAddons.contains(index);
    final price = item['price'] as int;

    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          config.selectedAddons.remove(index);
        } else {
          config.selectedAddons.add(index);
        }
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF2E9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFE5E5E5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item['image'] as String,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFFFF3EB),
                  child: const Icon(
                    Icons.local_car_wash_rounded,
                    color: Color(0xFFFF5E00),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _radio(selected: selected),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String,
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
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+$price MRU',
              style: GoogleFonts.outfit(
                color: selected
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFF1A1A1A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField(_VehicleWashConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: TextField(
            controller: config.notesController,
            maxLines: 3,
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
              color: const Color(0xFF5C6578),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$_totalPrice MRU',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF5E00),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _continueToSelectSlot,
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
                'Continue to Select Slot',
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
