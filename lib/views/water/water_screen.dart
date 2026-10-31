import 'dart:ui';
import '../../widgets/app_back_button.dart';
import '../../widgets/store_map_button.dart';
import '../../widgets/see_all_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/select_location_controller.dart';
import '../select_location_screen.dart';
import '../rewards_referral_screen.dart';
import 'water_supplier_details_screen.dart';
import 'water_see_all_screen.dart';
import 'water_subscription_screen.dart';
import '../widgets/search_camera_button.dart';
import '../../core/network/api_exception.dart';
import '../../models/water_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  int _bannerIndex = 0;
  final PageController _bannerController = PageController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool _showStickySearch = false;

  /// search bar height
  static const double _stickyExtent = 48;

  List<Map<String, dynamic>> categories = const [];
  List<Map<String, dynamic>> topSuppliers = const [];
  List<Map<String, dynamic>> nearbySuppliers = const [];
  List<Map<String, dynamic>> popularProducts = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadHome();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  /// Loads the home sections from waterHome for the selected location.
  Future<void> _loadHome() async {
    if (!Get.isRegistered<WaterRepository>()) return;
    try {
      final home = await Get.find<WaterRepository>().fetchHome(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        categories = home.categories;
        topSuppliers = home.topRatedSuppliers;
        popularProducts = home.popularProducts;
        nearbySuppliers = home.nearbySuppliers;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  /// Opens the products of a water category (waterSearchV2 with category_id).
  Future<void> _openCategory(Map<String, dynamic> cat) async {
    if (!Get.isRegistered<WaterRepository>()) return;
    final label = cat['label']?.toString() ?? 'pw_category'.tr;
    try {
      final result = await Get.find<WaterRepository>().search(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
        categoryId: cat['id'] as int?,
      );
      if (!mounted) return;
      Get.to(() => WaterSeeAllScreen(title: label, items: result.products));
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  void _handleScroll() {
    if (!mounted) return;
    final ctx = _searchAnchorKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final shouldShow = top <= MediaQuery.paddingOf(context).top;
    if (shouldShow != _showStickySearch) {
      setState(() => _showStickySearch = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFDDCF), Color(0xFFFFEEE5), Color(0xFFFAF6F0)],
            stops: [0.0, 0.38, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const SizedBox(height: 16),
                      _buildBannerSlider(),
                      const SizedBox(height: 16),
                      KeyedSubtree(
                        key: _searchAnchorKey,
                        child: _showStickySearch
                            ? const SizedBox(height: _stickyExtent)
                            : _buildSearchBar(),
                      ),
                      const SizedBox(height: 24),
                      _buildCategoriesSection(),
                      const SizedBox(height: 24),
                      _buildTopRatedSuppliersSection(),
                      const SizedBox(height: 24),
                      _buildMidPageBanner(),
                      const SizedBox(height: 24),
                      _buildPopularProductsSection(),
                      const SizedBox(height: 24),
                      _buildNearbySuppliersSection(),
                    ],
                  ),
                ),
              ),

              if (_showStickySearch)
                Positioned(
                  top: MediaQuery.paddingOf(context).top,
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                    color: const Color(0xFFFFDDCF),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: _buildSearchBar(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Header Bar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back Button
          AppBackButton(onTap: () => Get.back()),
          const SizedBox(width: 12),

          // Deliver To Location
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => const SelectLocationScreen()),
              child: Row(
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: Color(0xFFFF5E00),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'pw_deliver_to_colon'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF7A6A60),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Obx(
                                () => Text(
                                  SelectLocationController.deliveryLabel.value,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF2C2520),
                              size: 18,
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

          GestureDetector(
            onTap: () => Get.to(() => const RewardsReferralScreen()),
            child: Container(
              height: 36,
              padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 6, 4),
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
                    'mru'.trParams({'amount': '300'}),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Title Heading
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'pw_water'.tr,
        style: GoogleFonts.outfit(
          color: const Color(0xFF1A1A1A),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 3. Banner Slider
  Widget _buildBannerSlider() {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: 3,
            onPageChanged: (index) {
              setState(() {
                _bannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'lib/assets/images/Water slider.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'pw_subscribe_save_20'.tr,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'pw_fresh_water_on_schedule'.tr,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'pw_delivery_plans_line'.tr,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'pw_set_up_plan'.tr,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF007BFF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              'lib/assets/images/19L water.png',
                              width: 90,
                              height: 90,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.water_drop,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = _bannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFF5E00)
                    : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 4. Search Bar
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
                controller: _searchController,
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
              controller: _searchController,
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

  // 5. Categories Section
  /// Heading plus the no-data placeholder, used when a home section has no items.
  Widget _buildNoDataSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/assets/images/Nodata.png',
                  width: 86,
                  height: 86,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  'pw_no_data_available'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    if (categories.isEmpty) return _buildNoDataSection('pw_categories'.tr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'pw_categories'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.map((cat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _openCategory(cat),
                    child: SizedBox(
                      height: 84,
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
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE6F4FF),
                                    Color(0xFFCBE8FE),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.only(
                                bottom: 6,
                                left: 2,
                                right: 2,
                              ),
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                cat['label']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // 2. Overlapping bottle image projecting above card
                          Positioned(
                            top: 0,
                            left: 4,
                            right: 4,
                            height: 52,
                            child: waterImage(
                              cat['image'] as String,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.water_drop,
                                color: Color(0xFF007BFF),
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 6. Top Rated Suppliers Section
  Widget _buildTopRatedSuppliersSection() {
    if (topSuppliers.isEmpty) {
      return _buildNoDataSection('pw_top_rated_suppliers'.tr);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'pw_top_rated_suppliers'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SeeAllButton(
                onTap: () => Get.to(
                  () => WaterSeeAllScreen(
                    title: 'pw_top_rated_suppliers'.tr,
                    items: topSuppliers,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topSuppliers.length,
            itemBuilder: (context, index) {
              final item = topSuppliers[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 14),
                child: _buildSupplierCard(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> item) {
    final isClosed = item['isClosed'] == true;
    final isTemporarilyClosed = item['isTemporarilyClosed'] == true;
    final isUnavailable = isClosed || isTemporarilyClosed;
    final opensAt = (item['opensAt'] ?? '10 AM').toString();

    return GestureDetector(
      onTap: () {
        Get.to(() => WaterSupplierDetailsScreen(supplier: item));
      },
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: isUnavailable
              ? Colors.white.withValues(alpha: 0.72)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            // Image with overlay tags
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred image when closed / temporarily unavailable
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: isUnavailable
                        ? ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 6,
                              sigmaY: 6,
                              tileMode: TileMode.clamp,
                            ),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.22),
                                BlendMode.darken,
                              ),
                              child: _buildSupplierImage(item),
                            ),
                          )
                        : _buildSupplierImage(item),
                  ),

                  if (isUnavailable)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),

                  // Discount Tag (Top-left)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Rating Tag
                  PositionedDirectional(
                    top: 8,
                    start: 72,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB800),
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item['rating'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Favorite Icon (Top-right)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: Color(0xFF2C2520),
                        size: 16,
                      ),
                    ),
                  ),

                  // Points Available Pill (Bottom-left overlay on image)
                  PositionedDirectional(
                    bottom: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'lib/assets/images/Coin.png',
                            width: 12,
                            height: 12,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.monetization_on,
                              color: Color(0xFFFFAE00),
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['points'] as String,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isClosed)
                    Positioned.fill(child: _buildClosedOverlay(opensAt)),
                  if (isTemporarilyClosed)
                    Positioned.fill(child: _buildTemporarilyClosedOverlay()),
                ],
              ),
            ),

            // Frosted details below image
            ClipRect(
              child: BackdropFilter(
                filter: isUnavailable
                    ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  width: double.infinity,
                  color: isUnavailable
                      ? const Color(0xFFE8E8E8).withValues(alpha: 0.78)
                      : Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFFFF5E00),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['time'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFFF5E00),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['dist'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSupplierImage(Map<String, dynamic> item) {
    return Container(
      height: 120,
      width: double.infinity,
      color: const Color(0xFFEBF5FF),
      child: waterImage(
        item['image'] as String,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.water_drop, size: 50, color: Color(0xFF007BFF)),
      ),
    );
  }

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
                  'pw_closed'.tr,
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
                      'pw_opens_at'.trParams({'time': opensAt}),
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
                      'pw_temp_not_accepting_line1'.tr,
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
                  'pw_temp_not_accepting_line2'.tr,
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

  // 7. Mid-Page Banner
  Widget _buildMidPageBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Get.to(() => const WaterSubscriptionScreen()),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'lib/assets/images/water_banner.png',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF001F54), Color(0xFF003366)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'pw_choose_water_supplier'.tr,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 8. Popular Products Section
  Widget _buildPopularProductsSection() {
    if (popularProducts.isEmpty) {
      return _buildNoDataSection('pw_popular_products'.tr);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'pw_popular_products'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SeeAllButton(
                onTap: () => Get.to(
                  () => WaterSeeAllScreen(
                    title: 'pw_popular_products'.tr,
                    items: popularProducts,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: popularProducts.length,
            itemBuilder: (context, index) {
              final prod = popularProducts[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 14),
                child: _buildProductCard(prod),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Rating
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  color: const Color(0xFFF4F9FF),
                  padding: const EdgeInsets.all(10),
                  child: waterImage(
                    prod['image'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.water_drop,
                      size: 40,
                      color: Color(0xFF007BFF),
                    ),
                  ),
                ),
              ),

              // Rating Tag
              PositionedDirectional(
                top: 8,
                start: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        prod['rating'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Details below image
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod['title'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  prod['supplier'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      prod['price'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF5E00,
                            ).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'pw_add_caps'.tr,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. Nearby Suppliers Section
  Widget _buildNearbySuppliersSection() {
    if (nearbySuppliers.isEmpty) {
      return _buildNoDataSection('pw_nearby_suppliers'.tr);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'pw_nearby_suppliers'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  SeeAllButton(
                    onTap: () => Get.to(
                      () => WaterSeeAllScreen(
                        title: 'pw_nearby_suppliers'.tr,
                        items: nearbySuppliers,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StoreMapButton(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nearbySuppliers.length,
            itemBuilder: (context, index) {
              final item = nearbySuppliers[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 14),
                child: _buildSupplierCard(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Network image for API URLs, bundled asset for the design images.
Widget waterImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (path.startsWith('http')) {
    return Image.network(path, fit: fit, errorBuilder: errorBuilder);
  }
  return Image.asset(path, fit: fit, errorBuilder: errorBuilder);
}
