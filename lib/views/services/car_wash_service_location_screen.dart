import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import '../../utils/toast_helper.dart';
import '../courier/courier_select_recipient_location_screen.dart';

import 'car_wash_select_vehicles_screen.dart';
import '../../widgets/app_back_button.dart';

class CarWashServiceLocationScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;

  const CarWashServiceLocationScreen({
    super.key,
    required this.service,
    this.providerName = '',
  });

  @override
  State<CarWashServiceLocationScreen> createState() =>
      _CarWashServiceLocationScreenState();
}

class _CarWashServiceLocationScreenState
    extends State<CarWashServiceLocationScreen> {
  /// Index into [carWashPlaces]: station, home, workplace, other.
  int _selectedLocation = 0;
  final _instructionsController = TextEditingController();
  // "Another address", picked on the map.
  ({String address, double latitude, double longitude})? _otherAddress;

  bool get _atCustomer => _selectedLocation != 0;

  /// Where the provider goes: the delivery location for home and
  /// workplace, the picked point for "another address".
  ({String address, double latitude, double longitude})? get _serviceAddress {
    if (_selectedLocation == 3) return _otherAddress;
    final subtitle = SelectLocationController.selectedSubtitle.trim();
    return (
      address: subtitle.isEmpty
          ? SelectLocationController.deliveryLabel.value
          : subtitle,
      latitude: SelectLocationController.selectedLatitude,
      longitude: SelectLocationController.selectedLongitude,
    );
  }

  Future<void> _pickOtherAddress() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => CourierSelectRecipientLocationScreen(
        title: 'car_wash_pick_address'.tr,
      ),
    );
    if (!mounted || result == null) return;
    final title = '${result['subtitle'] ?? result['title'] ?? ''}'.trim();
    final latitude = double.tryParse('${result['latitude']}');
    final longitude = double.tryParse('${result['longitude']}');
    if (title.isEmpty || latitude == null || longitude == null) return;
    setState(
      () => _otherAddress = (
        address: title,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

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
                        'car_wash_where'.tr,
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
                        title: 'car_wash_at_station'.tr,
                        subtitle: 'car_wash_at_station_hint'.tr,
                      ),
                      const SizedBox(height: 14),
                      _locationCard(
                        index: 1,
                        icon: Icons.home_outlined,
                        title: 'car_wash_at_home'.tr,
                        subtitle: 'car_wash_comes_to_you'.tr,
                      ),
                      const SizedBox(height: 14),
                      _locationCard(
                        index: 2,
                        icon: Icons.business_center_outlined,
                        title: 'car_wash_at_workplace'.tr,
                        subtitle: 'car_wash_comes_to_you'.tr,
                      ),
                      const SizedBox(height: 14),
                      _locationCard(
                        index: 3,
                        icon: Icons.place_outlined,
                        title: 'car_wash_at_other'.tr,
                        subtitle: 'car_wash_at_other_hint'.tr,
                      ),
                      if (_atCustomer) ...[
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
                    final address = _atCustomer ? _serviceAddress : null;
                    if (_atCustomer && address == null) {
                      showAppToast(
                        'car_wash_choose_address'.tr,
                        backgroundColor: const Color(0xFFEF4444),
                      );
                      return;
                    }
                    // The provider's home-service fee comes from the
                    // server quote before booking, not from the app.
                    Get.to(
                      () => CarWashSelectVehiclesScreen(
                        service: widget.service,
                        providerName: widget.providerName,
                        selectedLocation: _selectedLocation,
                        homeInstructions: _atCustomer
                            ? _instructionsController.text.trim()
                            : '',
                        serviceAddress: address?.address ?? '',
                        serviceLatitude: address?.latitude,
                        serviceLongitude: address?.longitude,
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
                          color: const Color(
                            0xFFFF5E00,
                          ).withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'car_wash_continue'.tr,
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
            alignment: AlignmentDirectional.centerStart,
            child: AppBackButton(onTap: () => Get.back()),
          ),
          Text(
            'car_wash_location_title'.tr,
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
            color: selected ? const Color(0xFFFF5E00) : const Color(0xFFE8DFD6),
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
            'car_wash_service_address'.tr,
            style: GoogleFonts.outfit(
              color: const Color.fromARGB(255, 94, 90, 87),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _selectedLocation == 3 ? _pickOtherAddress : null,
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 14, 12),
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
                          _serviceAddress?.address ??
                              'car_wash_choose_address'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: _serviceAddress == null
                                ? const Color(0xFF8A7E76)
                                : const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedLocation == 3)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9A8E86),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'car_wash_instructions'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color.fromARGB(255, 94, 90, 87),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'car_wash_optional'.tr,
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
                hintText: 'car_wash_instructions_hint'.tr,
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
        ],
      ),
    );
  }
}
