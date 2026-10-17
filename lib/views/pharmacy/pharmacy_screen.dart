import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../models/pharmacy_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import 'pharmacy_items_screen.dart';
import 'pharmacy_search_screen.dart';
import 'widgets/pharmacy_background.dart';
import 'pharmacy_stores_screen.dart';
import 'upload_prescription_screen.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/store_map_button.dart';
import '../../widgets/see_all_button.dart';
import '../widgets/search_camera_button.dart';
import '../select_location_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _sliderController = PageController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();
  bool _showStickySearch = false;
  List<String> _sliderImages = const [];
  List<Map<String, dynamic>> _quickCategories = const [];
  bool _categoriesLoading = true;
  bool _openingCategory = false;
  List<Map<String, dynamic>> _trustedPharmacies = const [];
  List<Map<String, dynamic>> _nearbyPharmacies = const [];
  List<Map<String, dynamic>> _sections = const [];
  int _sliderIndex = 0;
  Timer? _sliderTimer;

  /// search bar height (48) + small padding
  static const double _stickyExtent = 56;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadSliders();
  }

  Future<void> _loadSliders() async {
    if (!Get.isRegistered<PharmacyRepository>()) {
      _categoriesLoading = false;
      return;
    }
    final repository = Get.find<PharmacyRepository>();
    final latitude = SelectLocationController.selectedLatitude;
    final longitude = SelectLocationController.selectedLongitude;
    final language = apiLanguageCode();
    try {
      final home = await repository.fetchHome(
        latitude: latitude,
        longitude: longitude,
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _sliderImages = home.sliders;
        _trustedPharmacies = home.trustedPharmacies;
        _nearbyPharmacies = home.nearbyPharmacies;
        _sections = home.sections;
        _sliderIndex = 0;
      });
      _startSliderAutoScroll();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message);
    }
    try {
      final categories = await repository.fetchHomeCategories(
        latitude: latitude,
        longitude: longitude,
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _quickCategories = categories;
        _categoriesLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
      showAppToast(error.message);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _sliderTimer?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  void _startSliderAutoScroll() {
    _sliderTimer?.cancel();
    if (_sliderImages.length < 2) return;
    _sliderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_sliderController.hasClients) return;
      _sliderController.animateToPage(
        _sliderIndex + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  double _headerBottomY() {
    final ctx = _headerKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.localToGlobal(Offset.zero).dy + box.size.height;
      }
    }
    return MediaQuery.paddingOf(context).top + 56;
  }

  void _handleScroll() {
    if (!mounted) return;
    final ctx = _searchAnchorKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final shouldShow = top <= _headerBottomY();
    if (shouldShow != _showStickySearch) {
      setState(() => _showStickySearch = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    Get.find<HomeController>();

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed app bar (location)
                  _buildHeader(context),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Collapses: title, promo, upload
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Pharmacy', 
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _buildPromoSlider(),
                          const SizedBox(height: 12),
                          _buildPrescriptionUploadButton(context),
                          const SizedBox(height: 12),

                          // Pins when scrolled: search
                          KeyedSubtree(
                            key: _searchAnchorKey,
                            child: _showStickySearch
                                ? const SizedBox(height: _stickyExtent)
                                : _buildSearchBar(),
                          ),

                          const SizedBox(height: 16),
                          if (_sectionTitle('categories', '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Text(
                                _sectionTitle('categories', ''),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          _buildQuickCategoriesGrid(),
                          const SizedBox(height: 12),
                          if (_sectionTitle('trusted_pharmacies', '').isNotEmpty ||
                              _trustedPharmacies.isNotEmpty) ...[
                            _buildSectionHeader(
                              _sectionTitle('trusted_pharmacies', ''),
                              onSeeAll: _showsSeeAll('trusted_pharmacies')
                                  ? () => _openPharmacyList(
                                      _sectionTitle('trusted_pharmacies', ''),
                                      _trustedPharmacies,
                                    )
                                  : null,
                            ),
                            _buildTrustedPharmaciesList(),
                            const SizedBox(height: 12),
                          ],
                          if (_sectionTitle('nearby_pharmacies', '').isNotEmpty ||
                              _nearbyPharmacies.isNotEmpty) ...[
                            _buildSectionHeader(
                              _sectionTitle('nearby_pharmacies', ''),
                              onMap: _showsMap('nearby_pharmacies')
                                  ? () => _openPharmacyMap(
                                      _sectionTitle('nearby_pharmacies', ''),
                                      _nearbyPharmacies,
                                    )
                                  : null,
                            ),
                            _buildNearbyPharmaciesList(),
                          ],
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sticky search (flush under measured location header)
            if (_showStickySearch)
              Positioned(
                top: _headerBottomY(),
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: PharmacyBackground.top,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildSearchBar(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildHeader(BuildContext context) {
    return ColoredBox(
      key: _headerKey,
      color: PharmacyBackground.top,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          AppBackButton(onTap: () => Get.back(),),
          const SizedBox(width: 12),

          // Location details
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final result = await Get.to(() => const SelectLocationScreen());
                if (result == true || mounted) {
                  _loadSliders();
                }
              },
              child: Row(
                children: [
                  Image.asset(
                    "lib/assets/images/Home.png",
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Deliver To',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Obx(
                                () => Text(
                                  SelectLocationController.deliveryLabel.value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF2C2520),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          Container(
            height: 36,
            padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/wallet_home.png',
                    width: 16,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '300 MRU',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Promotional Banner Slider with indicators
  Widget _buildPromoSlider() {
    final images = _sliderImages;
    final count = images.isEmpty ? 1 : images.length;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 130,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: images.isEmpty
                ? const _PharmacySliderFallback()
                : PageView.builder(
                    controller: _sliderController,
                    itemCount: images.length < 2 ? images.length : 10000,
                    onPageChanged: (index) {
                      setState(() => _sliderIndex = index);
                      _startSliderAutoScroll();
                    },
                    itemBuilder: (context, index) {
                      return _PharmacySliderImage(
                        url: images[index % images.length],
                      );
                    },
                  ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < count; index++) ...[
                if (index > 0) const SizedBox(width: 4),
                Container(
                  width: _sliderIndex % count == index ? 18 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _sliderIndex % count == index
                        ? const Color(0xFFFF5E00)
                        : const Color(0xFFDCD6CF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // Upload Your Prescription Button
  Widget _buildPrescriptionUploadButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Get.to(() => const UploadPrescriptionScreen());
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFCBEFF4), // soft light teal
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFA2E0E8), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF0097A7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Upload Your Prescription',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF006064),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFA59A94),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                onSubmitted: (value) {
                  Get.to(
                    () => PharmacySearchScreen(initialKeyword: value.trim()),
                  );
                },
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: 13,
                  height: 1,
                ),
                decoration: InputDecoration(
                  hintText: 'What do you need today?',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12.5,
                    height: 1,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SearchCameraButton(
              controller: _searchController,
              child: Image.asset(
                "lib/assets/images/Camera.png",
                width: 20,
                height: 20,
                color: const Color(0xFFA59A94),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 249, 210, 187),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "lib/assets/images/Voice.png",
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQuickCategory(
    Map<String, dynamic> category,
    bool isAll,
    int? categoryId,
  ) async {
    if (isAll || categoryId == null || categoryId == 0) {
      final store = _nearbyPharmacies.isNotEmpty
          ? Map<String, dynamic>.from(_nearbyPharmacies.first)
          : _trustedPharmacies.isNotEmpty
          ? Map<String, dynamic>.from(_trustedPharmacies.first)
          : null;
      if (store == null) return;
      Get.to(() => PharmacyItemsScreen(store: store));
      return;
    }
    if (_openingCategory || !Get.isRegistered<PharmacyRepository>()) return;
    _openingCategory = true;
    try {
      final stores = await Get.find<PharmacyRepository>()
          .fetchCategoryPharmacies(
            categoryId: categoryId,
            latitude: SelectLocationController.selectedLatitude,
            longitude: SelectLocationController.selectedLongitude,
            language: apiLanguageCode(),
          );
      if (!mounted) return;
      Get.to(
        () => PharmacyStoresScreen(
          title: category['label']?.toString() ?? '',
          stores: stores,
          categoryId: categoryId,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message);
    } finally {
      _openingCategory = false;
    }
  }

  // Shows the category image only when the API provides one.
  Widget _quickCategoryArt(Map<String, dynamic> category, bool isAll) {
    final image = category['image']?.toString() ?? '';
    if (!image.startsWith('http')) return const SizedBox.shrink();
    return Image.network(
      image,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  // Quick categories Grid View matching home screen stack design
  Widget _buildQuickCategoriesGrid() {
    if (_categoriesLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF5E00),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: _quickCategories.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 1.30,
        ),
        itemBuilder: (context, index) {
          final cat = _quickCategories[index];
          final isAll = cat['isAll'] == true;
          final categoryId = cat['id'] is int
              ? cat['id'] as int
              : int.tryParse('${cat['id']}');

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openQuickCategory(cat, isAll, categoryId),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Card Background (Starts 16px from top)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isAll
                          ? const LinearGradient(
                              colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFF6F6F6), Color(0xFFE8E8E8)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      cat['label']?.toString() ?? '',
                      style: GoogleFonts.outfit(
                        color: isAll
                            ? Colors.white
                            : const Color(0xFF2C2520),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 2. Overlapping Illustration Image
                Positioned(
                  top: isAll ? 12 : 0,
                  left: isAll ? 0 : 24,
                  right: isAll ? 0 : 24,
                  bottom: 22,
                  child: _quickCategoryArt(cat, isAll),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic>? _section(String key) {
    for (final section in _sections) {
      if (section['key'] == key) return section;
    }
    return null;
  }

  String _sectionTitle(String key, String fallback) {
    final title = _section(key)?['title']?.toString().trim() ?? '';
    return title.isEmpty ? fallback : title;
  }

  bool _showsSeeAll(String key) {
    if (_sections.isEmpty) return key == 'trusted_pharmacies';
    final value = _section(key)?['seeAll'];
    return value == true || value == 1 || value == 'true' || value == '1';
  }

  bool _showsMap(String key) {
    if (_sections.isEmpty) return key == 'nearby_pharmacies';
    return _section(key)?['seeAll']?.toString() == 'map';
  }

  void _openPharmacyList(String title, List<Map<String, dynamic>> stores) {
    if (stores.isEmpty) return;
    Get.to(() => PharmacyStoresScreen(title: title, stores: stores));
  }

  void _openPharmacyMap(String title, List<Map<String, dynamic>> stores) {
    final mapped = stores
        .where(
          (store) => store['latitude'] is num && store['longitude'] is num,
        )
        .toList();
    if (mapped.isEmpty) return;
    Get.to(() => PharmacyMapScreen(title: title, stores: mapped));
  }

  // Section header
  Widget _buildSectionHeader(
    String title, {
    VoidCallback? onSeeAll,
    VoidCallback? onMap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onMap != null)
            StoreMapButton(onTap: onMap)
          else if (onSeeAll != null)
            SeeAllButton(onTap: onSeeAll),
        ],
      ),
    );
  }

  // Horizontal Trusted Pharmacies List
  Widget _buildTrustedPharmaciesList() {
    if (_trustedPharmacies.isEmpty) return const SizedBox.shrink();
    return _buildHorizontalPharmaciesList(_trustedPharmacies);
  }

  // Horizontal Nearby Pharmacies List (same layout as Trusted)
  Widget _buildNearbyPharmaciesList() {
    if (_nearbyPharmacies.isEmpty) return const SizedBox.shrink();
    return _buildHorizontalPharmaciesList(_nearbyPharmacies);
  }

  Widget _buildHorizontalPharmaciesList(List<Map<String, dynamic>> pharmacies) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pharmacies.length,
        itemBuilder: (context, index) {
          final store = pharmacies[index];
          final homeController = Get.isRegistered<HomeController>()
              ? Get.find<HomeController>()
              : Get.put(HomeController());
          final isClosed = store['isClosed'] == true;
          final isTemporarilyClosed = store['isTemporarilyClosed'] == true;
          final opensAt = (store['opensAt'] ?? '').toString();
          final discount = (store['discount'] ?? '').toString();
          final points = (store['points'] ?? '').toString();

          return GestureDetector(
            onTap: () {
              Get.to(() => PharmacyItemsScreen(store: store));
            },
            child: Container(
              width: 240,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image & Badges
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _PharmacySliderImage(
                            url: (store['image'] ?? '').toString(),
                            fit: BoxFit.cover,
                            fallback: const ColoredBox(
                              color: Color(0xFFF3EFEA),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        if (discount.isNotEmpty)
                          Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE03A3A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              discount,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: discount.isEmpty ? 10 : 70,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFAE00),
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  store['rating'] as String,
                                  style: GoogleFonts.outfit(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Favorite Heart Badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Obx(() {
                            final isLiked = homeController.isLiked(
                              store['id'] as String,
                            );
                            return GestureDetector(
                              onTap: () {
                                homeController.toggleLike(
                                  store['id'] as String,
                                );
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: const Color(0xFFFF5E00),
                                  size: 16,
                                ),
                              ),
                            );
                          }),
                        ),
                        if (isClosed)
                          Positioned.fill(
                            child: _buildClosedOverlay(opensAt),
                          ),
                        if (isTemporarilyClosed)
                          Positioned.fill(
                            child: _buildTemporarilyClosedOverlay(),
                          ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: (isClosed || isTemporarilyClosed) ? 0.65 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  store['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (store['isOpen247'] == true)
                                Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Open 24/7',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF4CAF50),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (points.isNotEmpty)
                            Text(
                              points,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (points.isNotEmpty) const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFFFF5E00),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                store['time'] as String,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFFFF5E00),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                store['dist'] as String,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
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
  // Closed overlay
  Widget _buildClosedOverlay(String opensAt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD30000),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Closed',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Opens $opensAt',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Container(
                width: 8,
                height: 8,
                color: const Color(0xFFD30000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Temporarily Closed Overlay
  Widget _buildTemporarilyClosedOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Temporarily not accepting',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'orders',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Container(
                width: 8,
                height: 8,
                color: const Color(0xFFFF8A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _PharmacySliderFallback extends StatelessWidget {
  const _PharmacySliderFallback();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/assets/images/Pharmacy slider.png',
      fit: BoxFit.fill,
      width: double.infinity,
    );
  }
}

class _PharmacySliderImage extends StatefulWidget {
  const _PharmacySliderImage({
    required this.url,
    this.fit = BoxFit.fill,
    this.fallback = const _PharmacySliderFallback(),
  });

  final String url;
  final BoxFit fit;
  final Widget fallback;

  @override
  State<_PharmacySliderImage> createState() => _PharmacySliderImageState();
}

class _PharmacySliderImageState extends State<_PharmacySliderImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.url.isEmpty || !Get.isRegistered<DioClient>()) return;
    try {
      final response = await Get.find<DioClient>().dio.get<List<int>>(
        widget.url,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final data = response.data;
      final loaded =
          response.statusCode == 200 && data != null && _isImageBytes(data);
      if (!mounted) return;
      setState(() {
        _bytes = loaded
            ? (data is Uint8List ? data : Uint8List.fromList(data))
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bytes = null);
    }
  }

  bool _isImageBytes(List<int> data) {
    if (data.length < 8) return false;
    final jpeg = data[0] == 0xFF && data[1] == 0xD8;
    final png = data[0] == 0x89 && data[1] == 0x50;
    final gif = data[0] == 0x47 && data[1] == 0x49;
    final webp = data[0] == 0x52 && data[1] == 0x49;
    return jpeg || png || gif || webp;
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return widget.fallback;
    return Image.memory(
      bytes,
      fit: widget.fit,
      width: double.infinity,
      gaplessPlayback: true,
    );
  }
}
