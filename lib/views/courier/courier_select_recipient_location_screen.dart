import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/select_location_controller.dart';
import '../../utils/toast_helper.dart';

class CourierSelectRecipientLocationScreen extends StatefulWidget {
  const CourierSelectRecipientLocationScreen({super.key});

  @override
  State<CourierSelectRecipientLocationScreen> createState() =>
      _CourierSelectRecipientLocationScreenState();
}

class _CourierSelectRecipientLocationScreenState
    extends State<CourierSelectRecipientLocationScreen> {
  late final SelectLocationController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SelectLocationController>()) {
      Get.delete<SelectLocationController>(force: true);
    }
    controller = Get.put(SelectLocationController());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: controller.hideSearchResults,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF6F0),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: SelectLocationController.defaultCenter,
                            zoom: 15.5,
                          ),
                          onMapCreated: controller.onMapCreated,
                          onCameraMove: controller.onCameraMove,
                          onCameraIdle: controller.onCameraIdle,
                          onTap: (_) => controller.hideSearchResults(),
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationEnabled: true,
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 36),
                          child: IgnorePointer(child: _buildCenterPin()),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            _buildSearchBox(),
                            Obx(() {
                              if (!controller.showSearchResults.value) {
                                return const SizedBox.shrink();
                              }
                              return _buildSearchResults();
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomCard(bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFFAF6F0),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    color: const Color(0xFFEAD8C9),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Select Recipient\'s Location',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFFA59A94), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller.searchController,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 13,
              ),
              textInputAction: TextInputAction.search,
              onChanged: controller.onSearchQueryChanged,
              onSubmitted: controller.searchAddress,
              decoration: InputDecoration(
                hintText: 'Search for area, street name.....',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Obx(() {
            if (!controller.isSearching.value) {
              return const SizedBox.shrink();
            }
            return const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF5E00),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
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
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 44,
          color: Color(0xFFF0E8E0),
        ),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.location_on, color: Color(0xFFE03A3A), size: 52),
        Positioned(
          top: 10,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCard(double bottomInset) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20 + (bottomInset > 0 ? bottomInset : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFFF5E00),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.addressTitle.value,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.addressSubtitle.value,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              controller.hideSearchResults();
              final result = controller.getSelectedAddressResult();
              if (result == null) {
                showAppToast(
                  'Please select a valid location on the map or from search.',
                  backgroundColor: Colors.redAccent,
                );
                return;
              }
              Get.back(result: result);
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Continue',
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
