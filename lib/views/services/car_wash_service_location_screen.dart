import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'car_wash_select_vehicles_screen.dart';

class CarWashServiceLocationScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;

  const CarWashServiceLocationScreen({
    super.key,
    required this.service,
    this.providerName = 'CleanRide Car Wash',
  });

  @override
  State<CarWashServiceLocationScreen> createState() =>
      _CarWashServiceLocationScreenState();
}

class _CarWashServiceLocationScreenState
    extends State<CarWashServiceLocationScreen> {
  /// 0 = At Wash Station, 1 = At Home/Workplace
  int _selectedLocation = 0;
  final _instructionsController = TextEditingController();

  static const _homeServiceFee = 150;
  static const _addressTitle = 'Nouakchott, Mauritania';
  static const _addressSubtitle = 'Ilot V, près Ambassade de France';
  static const _distanceKm = '3.8 km';

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isHome = _selectedLocation == 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where should we wash your vehicle?',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _locationCard(
                        index: 0,
                        icon: Icons.storefront_outlined,
                        title: 'At Wash Station',
                        subtitle:
                            'Bring your vehicle to the selected wash center',
                      ),
                      const SizedBox(height: 14),
                      _locationCard(
                        index: 1,
                        icon: Icons.home_outlined,
                        title: 'At Home/Workplace',
                        subtitle:
                            'Our mobile team will come directly to your location',
                      ),
                      if (isHome) ...[
                        const SizedBox(height: 16),
                        _buildHomeDetailsCard(),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
                child: GestureDetector(
                  onTap: () {
                    Get.to(
                      () => CarWashSelectVehiclesScreen(
                        service: widget.service,
                        providerName: widget.providerName,
                        selectedLocation: _selectedLocation,
                        homeServiceFee: isHome ? _homeServiceFee : 0,
                        homeInstructions: isHome
                            ? _instructionsController.text.trim()
                            : '',
                        serviceAddress: isHome ? _addressTitle : '',
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
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
                          color:
                              const Color(0xFFFF5E00).withValues(alpha: 0.28),
                          blurRadius: 12,
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
              ),
            ],
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
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.25),
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
            'Service Location',
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

  Widget _locationCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedLocation == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedLocation = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0EA) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFE8DFD6),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? null
              : [
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EA),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFFFF5E00), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 10),
              Container(
                width: 22,
                height: 22,
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Text(
            'Service Address',
            style: GoogleFonts.outfit(
              color: const Color.fromARGB(255, 94, 90, 87),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F3),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFFE5E0DA)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF5E00).withValues(alpha: 0.20),
                        const Color(0xFFFF5E00).withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFFF5E00),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _addressTitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _addressSubtitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8A7E76),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9A8E86),
                  size: 22,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Home/Workplace Instructions',
                  style: GoogleFonts.outfit(
                    color: const Color.fromARGB(255, 94, 90, 87),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Optional',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFB0A59C),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD6)),
            ),
            child: TextField(
              controller: _instructionsController,
              maxLines: 3,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'e.g. Villa with grey gate, security guard will let team enter driveway...',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFB0A59C),
                  fontSize: 13,
                  height: 1.35,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5E00),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Home Service Fee',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          'Calculated from your address • $_distanceKm',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF8A7E76),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_homeServiceFee MRU',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
