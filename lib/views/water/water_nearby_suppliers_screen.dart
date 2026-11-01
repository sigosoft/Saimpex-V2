import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/store_map_button.dart';
import '../widgets/search_camera_button.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/water_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import 'water_supplier_details_screen.dart';

class WaterNearbySuppliersScreen extends StatefulWidget {
  const WaterNearbySuppliersScreen({super.key});

  @override
  State<WaterNearbySuppliersScreen> createState() =>
      _WaterNearbySuppliersScreenState();
}

class _WaterNearbySuppliersScreenState
    extends State<WaterNearbySuppliersScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> suppliers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Nearby suppliers from waterHome for the selected location.
  Future<void> _load() async {
    if (!Get.isRegistered<WaterRepository>()) {
      setState(() => _loading = false);
      return;
    }
    try {
      final home = await Get.find<WaterRepository>().fetchHome(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() => suppliers = home.nearbySuppliers);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredSuppliers {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return suppliers;
    return suppliers.where((s) {
      final title = (s['name'] ?? '').toString().toLowerCase();
      final subtitle = (s['subtitle'] ?? '').toString().toLowerCase();
      return title.contains(query) || subtitle.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD8F0F8), Color(0xFFFFF4EE), Color(0xFFFFF9F5)],
            stops: [0.0, 0.18, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildStoreMapButton(),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5E00),
                          ),
                        )
                      : filteredSuppliers.isEmpty
                      ? Center(
                          child: Text(
                            'pw_no_suppliers_found'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filteredSuppliers.length,
                          itemBuilder: (context, index) {
                            return _buildSupplierCard(
                              controller,
                              filteredSuppliers[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'pw_nearby_suppliers'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8E4DF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF9A938C),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'pw_search_water_suppliers_products'.tr,
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SearchCameraButton(
              controller: searchController,
              onFilled: (_) => setState(() {}),
              child: Image.asset(
                'lib/assets/images/Camera.png',
                width: 20,
                height: 20,
                color: const Color(0xFF9A938C),
                errorBuilder: (_, _, _) => const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF9A938C),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/images/Voice.png',
                  width: 15,
                  height: 15,
                  color: const Color(0xFFFF5E00),
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFFFF5E00),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreMapButton() {
    return const Center(child: StoreMapButton());
  }

  Widget _buildSupplierCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final cardImage = '${item['image'] ?? ''}';
    final supplierId = (item['id'] ?? '').toString();

    return GestureDetector(
      onTap: () => Get.to(() => WaterSupplierDetailsScreen(supplier: item)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 168,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF7AD3F3), Color(0xFF2E9FE6)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                        child: Image.network(
                          cardImage,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.water_drop_outlined,
                                color: Colors.white,
                                size: 64,
                              ),
                        ),
                      ),
                    ),
                  ),
                  if ('${item['discount'] ?? ''}'.isNotEmpty)
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5E00),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['discount'] as String,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFAE00),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item['rating'] as String,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: Obx(() {
                      final liked = controller.isLiked(supplierId);
                      return GestureDetector(
                        onTap: () => controller.toggleLike(supplierId, item),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: liked
                                ? const Color(0xFFE03A3A)
                                : const Color(0xFF2C2520),
                            size: 17,
                          ),
                        ),
                      );
                    }),
                  ),
                  if ('${item['points'] ?? ''}'.isNotEmpty)
                    PositionedDirectional(
                      start: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'lib/assets/images/Coin.png',
                              width: 14,
                              height: 14,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Color(0xFFFFAE00),
                                    size: 14,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['points'] as String,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['name'] ?? ''}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFFF5E00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['time'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF5E00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['dist'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
