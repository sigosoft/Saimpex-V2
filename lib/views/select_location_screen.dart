import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/select_location_controller.dart';
import '../widgets/app_back_button.dart';

class SelectLocationScreen extends StatelessWidget {
  final bool isInitialSetup;

  /// Save the picked spot to the address book (from Saved Addresses).
  final bool saveToAddressBook;

  /// Saved address being edited, and its label to preselect.
  final int? editAddressId;
  final String? initialLabel;

  const SelectLocationScreen({
    super.key,
    this.isInitialSetup = false,
    this.saveToAddressBook = false,
    this.editAddressId,
    this.initialLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<SelectLocationController>()) {
      Get.delete<SelectLocationController>(force: true);
    }
    final controller = Get.put(SelectLocationController());
    controller.isInitialSetup = isInitialSetup;
    controller.saveToAddressBook = saveToAddressBook;
    controller.editAddressId = editAddressId;
    if (initialLabel != null) controller.selectAddressType(initialLabel!);
    final orientation = MediaQuery.of(context).orientation;

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
        body: SafeArea(
          bottom: false,
          child: orientation == Orientation.portrait
              ? _buildPortraitLayout(context, controller)
              : _buildLandscapeLayout(context, controller),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    SelectLocationController controller,
  ) {
    return Column(
      children: [
        // 1. Header Bar
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              _buildBackButton(),
              const SizedBox(width: 16),
              Text(
                'core_location_title'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // 2. Map Area
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Google Map
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      SelectLocationController.selectedLatitude != 0.0
                          ? SelectLocationController.selectedLatitude
                          : SelectLocationController.defaultCenter.latitude,
                      SelectLocationController.selectedLongitude != 0.0
                          ? SelectLocationController.selectedLongitude
                          : SelectLocationController.defaultCenter.longitude,
                    ),
                    zoom: 16.0,
                  ),
                  onMapCreated: (mapController) {
                    controller.onMapCreated(mapController);
                  },
                  onCameraMove: (position) {
                    controller.onCameraMove(position);
                  },
                  onCameraIdle: () {
                    controller.onCameraIdle();
                  },
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: true,
                  myLocationEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                ),
              ),

              // Center Target Location Pin (stationary, ignore touch to allow map scroll)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: IgnorePointer(child: _buildCenterPin()),
                ),
              ),

              // Search Bar Overlay
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: _buildSearchBox(controller),
              ),

              // Current Location Overlay
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(child: _buildCurrentLocationButton(controller)),
              ),
            ],
          ),
        ),
        // 3. Bottom Sheet Card
        _buildBottomCard(context, controller),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    SelectLocationController controller,
  ) {
    return Row(
      children: [
        // Left Column: Map Area
        Expanded(
          flex: 6,
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    _buildBackButton(),
                    const SizedBox(width: 16),
                    Text(
                      'core_location_title'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Map Area
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Google Map
                    Positioned.fill(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            SelectLocationController.selectedLatitude != 0.0
                                ? SelectLocationController.selectedLatitude
                                : SelectLocationController
                                      .defaultCenter
                                      .latitude,
                            SelectLocationController.selectedLongitude != 0.0
                                ? SelectLocationController.selectedLongitude
                                : SelectLocationController
                                      .defaultCenter
                                      .longitude,
                          ),
                          zoom: 16.0,
                        ),
                        onMapCreated: (mapController) {
                          controller.onMapCreated(mapController);
                        },
                        onCameraMove: (position) {
                          controller.onCameraMove(position);
                        },
                        onCameraIdle: () {
                          controller.onCameraIdle();
                        },
                        zoomControlsEnabled: true,
                        myLocationButtonEnabled: false,
                        compassEnabled: true,
                        mapToolbarEnabled: true,
                        myLocationEnabled: true,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                      ),
                    ),

                    // Center Target Location Pin (stationary, ignore touch to allow map scroll)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: IgnorePointer(child: _buildCenterPinLandscape()),
                      ),
                    ),

                    // Search Bar Overlay
                    Positioned(
                      top: 8,
                      left: 16,
                      right: 16,
                      child: _buildSearchBox(controller),
                    ),

                    // Current Location Overlay
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildCurrentLocationButton(controller),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Vertical Divider
        Container(width: 1, color: const Color(0xFFEAD8C9)),
        // Right Column: Address Details Card
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFFAF6F0),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom:
                  24 +
                  (MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom
                      : 16),
            ),
            child: SingleChildScrollView(
              child: _buildBottomCardContent(context, controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return AppBackButton(onTap: () => Get.back());
  }

  Widget _buildSearchBox(SelectLocationController controller) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEAD8C9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFFA59A94), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller.searchController,
                  style: GoogleFonts.outfit(color: Colors.black, fontSize: 14),
                  textInputAction: TextInputAction.search,
                  onChanged: controller.onSearchQueryChanged,
                  onSubmitted: controller.searchAddress,
                  decoration: InputDecoration(
                    hintText: 'core_location_search_hint'.tr,
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Obx(() {
                if (controller.isSearching.value) {
                  return const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF5E00),
                    ),
                  );
                }
                if (controller.searchText.value.isEmpty &&
                    !controller.showSearchResults.value) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: controller.clearSearch,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFA59A94),
                    size: 18,
                  ),
                );
              }),
            ],
          ),
        ),
        Obx(() {
          if (!controller.showSearchResults.value) {
            return const SizedBox.shrink();
          }
          return _buildSearchResults(controller);
        }),
      ],
    );
  }

  Widget _buildSearchResults(SelectLocationController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: controller.searchResults.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 44, color: Color(0xFFF0E8E0)),
        itemBuilder: (context, index) {
          final result = controller.searchResults[index];
          final label = result['label']?.toString() ?? '';
          return InkWell(
            onTap: () => controller.selectSearchResult(result),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFFF5E00),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.location_on, color: Color(0xFFE03A3A), size: 48),
            Positioned(
              top: 9,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCenterPinLandscape() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.location_on, color: Color(0xFFE03A3A), size: 38),
            Positioned(
              top: 7,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentLocationButton(SelectLocationController controller) {
    return GestureDetector(
      onTap: controller.centerOnDefaultLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.gps_fixed_rounded,
              color: Color(0xFFE03A3A),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'core_location_current_location'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFFE03A3A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard(
    BuildContext context,
    SelectLocationController controller,
  ) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + (bottomInset > 0 ? bottomInset : 16),
      ),
      child: _buildBottomCardContent(context, controller),
    );
  }

  Widget _buildBottomCardContent(
    BuildContext context,
    SelectLocationController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Address Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Color(0xFFFF5E00), size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    return Text(
                      SelectLocationController.display(
                        controller.addressTitle.value,
                      ),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Obx(() {
                    return Text(
                      SelectLocationController.display(
                        controller.addressSubtitle.value,
                      ),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Row of quick buttons (Home, Office, Other)
        Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAddressTypeBtn(
                label: 'core_location_type_home'.tr,
                icon: Icons.home_outlined,
                isSelected: controller.selectedAddressType.value == 'Home',
                onTap: () => controller.selectAddressType('Home'),
              ),
              const SizedBox(width: 10),
              _buildAddressTypeBtn(
                label: 'core_location_type_office'.tr,
                icon: Icons.desktop_mac_outlined,
                isSelected: controller.selectedAddressType.value == 'Office',
                onTap: () => controller.selectAddressType('Office'),
              ),
              const SizedBox(width: 10),
              _buildAddressTypeBtn(
                label: 'core_location_type_other'.tr,
                icon: Icons.near_me_outlined,
                isSelected: controller.selectedAddressType.value == 'Other',
                onTap: () => controller.selectAddressType('Other'),
              ),
            ],
          );
        }),
        const SizedBox(height: 24),

        // Continue button
        _buildBottomContinueBtn(controller),
      ],
    );
  }

  Widget _buildAddressTypeBtn({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF5E00)
                  : const Color(0xFFEAD8C9),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFF5E00), size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContinueBtn(SelectLocationController controller) {
    return Obx(() {
      final isUpdating = controller.isUpdatingLocation.value;
      return GestureDetector(
        onTap: isUpdating ? null : controller.onContinuePressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isUpdating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'core_location_continue'.tr,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      );
    });
  }
}
