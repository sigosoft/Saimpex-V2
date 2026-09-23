import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'car_wash_add_vehicles_sheet.dart';
import 'car_wash_choose_wash_services_screen.dart';
import '../../widgets/app_back_button.dart';

class CarWashSelectVehiclesScreen extends StatefulWidget {
  final Map<String, String> service;
  final String providerName;
  final int selectedLocation;
  final int homeServiceFee;
  final String homeInstructions;
  final String serviceAddress;

  const CarWashSelectVehiclesScreen({
    super.key,
    required this.service,
    this.providerName = 'CleanRide Car Wash',
    this.selectedLocation = 0,
    this.homeServiceFee = 0,
    this.homeInstructions = '',
    this.serviceAddress = '',
  });

  @override
  State<CarWashSelectVehiclesScreen> createState() =>
      _CarWashSelectVehiclesScreenState();
}

class _CarWashSelectVehiclesScreenState
    extends State<CarWashSelectVehiclesScreen> {
  final List<CarWashAddedVehicle> _vehicles = [];
  final Set<int> _selectedIndexes = {};

  Future<void> _openAddVehiclesSheet() async {
    final added = await showCarWashAddVehiclesSheet(context);
    if (added == null || !mounted) return;
    setState(() {
      _vehicles.add(added);
      _selectedIndexes.add(_vehicles.length - 1);
    });
  }

  void _toggleVehicle(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  void _continueToServices() {
    if (_selectedIndexes.isEmpty) return;
    final selected = _selectedIndexes.toList()..sort();
    final vehicles = selected.map((i) => _vehicles[i]).toList();
    Get.to(
      () => CarWashChooseWashServicesScreen(
        vehicles: vehicles,
        providerName: widget.providerName,
        selectedLocation: widget.selectedLocation,
        homeServiceFee: widget.homeServiceFee,
        homeInstructions: widget.homeInstructions,
        serviceAddress: widget.serviceAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hasVehicles = _vehicles.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFFBF9),
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
              stops: [0.0, 0.35, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: hasVehicles
                      ? ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: _vehicles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _buildVehicleCard(
                              _vehicles[index],
                              index,
                            );
                          },
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_filled_rounded,
                                  size: 88,
                                  color: const Color(0xFFC5CAD3)
                                      .withValues(alpha: 0.95),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'No vehicles found',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF8A909C),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Add a vehicle to continue',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFB0B5C0),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
                  child: Column(
                    children: [
                      if (hasVehicles) ...[
                        GestureDetector(
                          onTap: _selectedIndexes.isEmpty
                              ? null
                              : _continueToServices,
                          child: Opacity(
                            opacity: _selectedIndexes.isEmpty ? 0.45 : 1,
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5E00),
                                    Color(0xFFFFAE00),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5E00)
                                        .withValues(alpha: 0.28),
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
                        ),
                        const SizedBox(height: 12),
                      ],
                      GestureDetector(
                        onTap: _openAddVehiclesSheet,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFFF5E00),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: Color(0xFFFF5E00),
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add New Vehicle',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(CarWashAddedVehicle vehicle, int index) {
    final selected = _selectedIndexes.contains(index);

    return GestureDetector(
      onTap: () => _toggleVehicle(index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3EB) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF8A5B)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                vehicle.image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFF5F0EB),
                  child: Center(
                    child: Icon(
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
                      color: const Color(0xFF1A1F36),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plateNumber,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
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
                  width: selected ? 1.8 : 1.4,
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
            'Select Vehicles',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1F36),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
