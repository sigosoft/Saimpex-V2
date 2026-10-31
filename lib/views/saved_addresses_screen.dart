import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../controllers/select_location_controller.dart';
import '../core/network/api_exception.dart';
import '../models/profile_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'select_location_screen.dart';

/// The customer's address book (customer/addresses). Tap an address to
/// deliver there; add and edit go through the map picker.
class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, dynamic>> _addresses = const [];
  bool _loading = true;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Get.isRegistered<ProfileRepository>()) return;
    setState(() => _loading = true);
    try {
      final rows = await Get.find<ProfileRepository>().savedAddresses(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _addresses = rows;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static int? _id(Map<String, dynamic> address) =>
      int.tryParse('${address['id'] ?? ''}');

  static double? _coord(dynamic value) => double.tryParse('${value ?? ''}');

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final id = _id(address);
    if (id == null || _busyId != null) return;
    setState(() => _busyId = id);
    try {
      final message = await Get.find<ProfileRepository>().deleteAddress(
        addressId: id,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(
        () => _addresses = [
          for (final row in _addresses)
            if (_id(row) != id) row,
        ],
      );
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  /// Makes [address] the delivery location, here and on the server.
  Future<void> _useAddress(Map<String, dynamic> address) async {
    final id = _id(address);
    final text = '${address['address'] ?? ''}'.trim();
    final latitude = _coord(address['latitude']);
    final longitude = _coord(address['longitude']);
    if (id == null ||
        latitude == null ||
        longitude == null ||
        _busyId != null) {
      return;
    }
    setState(() => _busyId = id);
    try {
      await Get.find<ProfileRepository>().updateLocation(
        latitude: latitude,
        longitude: longitude,
        address: text,
        language: apiLanguageCode(),
      );
      SelectLocationController.applyFetchedLocation(
        address: text,
        latitude: latitude,
        longitude: longitude,
      );
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadHome();
      }
      showAppToast(
        'core_addresses_delivering_to'.trParams({
          'label': address['label'] == null
              ? 'core_addresses_this_address'.tr
              : _labelText('${address['label']}'),
        }),
        backgroundColor: const Color(0xFFFF5E00),
      );
      Get.back();
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openPicker({Map<String, dynamic>? editing}) async {
    // The picker opens on the shared selected point; aim it at the address
    // being edited, and put it back if the customer leaves without saving.
    final previous = (
      SelectLocationController.selectedLatitude,
      SelectLocationController.selectedLongitude,
    );
    final latitude = _coord(editing?['latitude']);
    final longitude = _coord(editing?['longitude']);
    if (latitude != null && longitude != null) {
      SelectLocationController.selectedLatitude = latitude;
      SelectLocationController.selectedLongitude = longitude;
    }
    final saved = await Get.to(
      () => SelectLocationScreen(
        saveToAddressBook: true,
        editAddressId: editing == null ? null : _id(editing),
        initialLabel: editing == null ? null : '${editing['label'] ?? ''}',
      ),
    );
    if (saved != true) {
      SelectLocationController.selectedLatitude = previous.$1;
      SelectLocationController.selectedLongitude = previous.$2;
      return;
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF5E00),
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    children: [
                      if (_loading && _addresses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5E00),
                          ),
                        )
                      else if (_addresses.isEmpty)
                        _buildEmptyState()
                      else
                        ..._addresses.map(
                          (address) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildAddressCard(address),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _buildAddButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(
        _error ?? 'core_addresses_empty'.tr,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: const Color(0xFFA59A94),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'core_addresses_title'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Balances the back button so the title stays centred.
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  static IconData _iconFor(String label) => switch (label) {
    'Office' => Icons.work_outline_rounded,
    'Other' => Icons.location_on_outlined,
    _ => Icons.home_outlined,
  };

  /// Translates the standard labels; a custom label is shown as typed.
  static String _labelText(String label) => switch (label) {
    'Home' => 'core_addresses_home'.tr,
    'Office' => 'core_addresses_office'.tr,
    'Other' => 'core_addresses_other'.tr,
    _ => label,
  };

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final label = '${address['label'] ?? 'Home'}';
    final busy = _busyId != null && _busyId == _id(address);
    return GestureDetector(
      onTap: () => _useAddress(address),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(label),
                    color: const Color(0xFFFF5E00),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelText(label),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${address['address'] ?? ''}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6B635C),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF5E00),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _deleteAddress(address),
                  child: Text(
                    'core_addresses_delete'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                GestureDetector(
                  onTap: () => _openPicker(editing: address),
                  child: Text(
                    'core_addresses_edit'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _openPicker(),
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
              color: const Color(0xFFFF5E00).withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          'core_addresses_add_new'.tr,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
