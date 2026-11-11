import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import 'express_fifteen_min_delivery_screen.dart';
import 'express_trending_screen.dart';
import '../../core/network/api_exception.dart';
import '../../utils/toast_helper.dart';
import 'express_stores.dart';
import '../store_map_screen.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/store_map_button.dart';
import '../../widgets/see_all_button.dart';
import '../widgets/search_camera_button.dart';
import '../select_location_screen.dart';

import '../../utils/app_fonts.dart';
import '../../utils/wallet_chip.dart';

class ExpressScreen extends StatefulWidget {
  const ExpressScreen({super.key});

  @override
  State<ExpressScreen> createState() => _ExpressScreenState();
}

class _ExpressScreenState extends State<ExpressScreen> {
  int _bannerIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool _showStickySearch = false;

  /// search bar (46) + padding (14 top, 8 bottom)
  static const double _stickyExtent = 68;

  List<Map<String, String>> _stores = ExpressStores.stores;
  List<Map<String, String>> _categories = ExpressStores.categories;

  /// The picked store type (`vendorType`); null shows every store ("All").
  String? _selectedType;

  /// The stores of the picked type, nearest first.
  List<Map<String, String>> get _shownStores => _selectedType == null
      ? _stores
      : _stores.where((s) => s['vendorType'] == _selectedType).toList();

  // Nearest first from the API; the fast list is the closest few and
  // trending is the best rated.
  List<Map<String, String>> get fastDeliveryStores =>
      _shownStores.take(6).toList();

  List<Map<String, String>> get trendingStores {
    final sorted = [..._shownStores]
      ..sort(
        (a, b) => (double.tryParse(b['rating']!) ?? 0).compareTo(
          double.tryParse(a['rating']!) ?? 0,
        ),
      );
    return sorted.take(6).toList();
  }

  List<Map<String, String>> get nearbyStores => _shownStores;

  Future<void> _loadStores() async {
    try {
      final stores = await ExpressStores.load();
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _categories = ExpressStores.categories;
        // The picked type may be gone after a reload.
        if (!_categories.any((c) => c['vendorType'] == _selectedType)) {
          _selectedType = null;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadStores();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDE8DD), Color(0xFFFFF3EC), Color(0xFFFFFBF7)],
          stops: [0.0, 0.42, 1.0],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        'st_express'.tr,
                        style: AppFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildHeroBanner(),
                    KeyedSubtree(
                      key: _searchAnchorKey,
                      child: _showStickySearch
                          ? const SizedBox(height: _stickyExtent)
                          : _buildSearchBar(),
                    ),
                    _buildShopByCategory(),
                    // A picked type with no express stores shows only the
                    // message under the row, not three empty sections.
                    if (_selectedType == null || _shownStores.isNotEmpty) ...[
                      _buildSectionHeader(
                        'st_15_min_delivery'.tr,
                        'See All',
                        () => Get.to(
                          () => const ExpressFifteenMinDeliveryScreen(),
                        ),
                      ),
                      _buildFastDeliveryList(),
                      _buildSectionHeader(
                        'st_trending_express'.tr,
                        'See All',
                        () => Get.to(() => const ExpressTrendingScreen()),
                      ),
                      _buildTrendingList(controller),
                      _buildSectionHeader(
                        'st_nearby_stores'.tr,
                        'Store Map',
                        () => Get.to(
                          () => StoreMapScreen(
                            stores: [
                              for (final store in nearbyStores)
                                Map<String, dynamic>.from(store),
                            ],
                            onOpen: ExpressStores.open,
                          ),
                        ),
                        showMapIcon: true,
                      ),
                      _buildNearbyStoresList(controller),
                    ],
                    const SizedBox(height: 32),
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
                  color: const Color(0xFFFFF3EC),
                  child: _buildSearchBar(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Get.to(() => const SelectLocationScreen()),
              child: Row(
                children: [
                  Image.asset(
                    'lib/assets/images/Home.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.home_rounded,
                      color: Color(0xFFFF5216),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'st_deliver_to'.tr,
                          style: AppFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Obx(
                                () => Text(
                                  SelectLocationController.deliveryLabel.value,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.outfit(
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
          Container(
            height: 36,
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 6, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5216),
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
                  walletChipText(),
                  style: AppFonts.outfit(
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
    );
  }

  Widget _buildHeroBanner() {
    const slideCount = 4;
    const imagePath = 'lib/assets/images/Express_banner.png';

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 148,
          child: PageView.builder(
            itemCount: slideCount,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _bannerIndex = index),
            itemBuilder: (_, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 148,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFFF5216),
                    child: const Center(
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slideCount, (index) {
            final active = _bannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: active ? 18 : 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF5216)
                    : const Color(0xFFD8CEC6),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFA59A94),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppFonts.outfit(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'st_search_hint'.tr,
                  hintStyle: AppFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SearchCameraButton(
              controller: _searchController,
              child: Image.asset(
                'lib/assets/images/Camera.png',
                width: 18,
                height: 18,
                color: const Color(0xFFA59A94),
                errorBuilder: (_, _, _) => const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFFA59A94),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/images/Voice.png',
                  width: 14,
                  height: 14,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFFFF5216),
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Figma "Shop by category": one scrolling row, "All" first, then the
  /// store types express serves (from customer/expressHome). A tile filters
  /// the lists below. The row used to be eight made-up product categories
  /// (Fruits & Veg, Snacks…) that did nothing when tapped.
  Widget _buildShopByCategory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'st_shop_by_category'.tr,
              style: AppFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _categoryTile(
                  label: 'st_all'.tr,
                  selected: _selectedType == null,
                  onTap: () => setState(() => _selectedType = null),
                ),
                for (final category in _categories)
                  _categoryTile(
                    label: category['label'] ?? '',
                    image: ExpressStores.categoryImage(
                      category['vendorType'] ?? '',
                    ),
                    selected: _selectedType == category['vendorType'],
                    onTap: () =>
                        setState(() => _selectedType = category['vendorType']),
                  ),
              ],
            ),
          ),
          if (_selectedType != null && _shownStores.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'st_no_fast_delivery'.tr,
                style: AppFonts.outfit(
                  color: const Color(0xFF8C7D73),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// A Figma category tile: rounded square with the picture, name below;
  /// the picked one is orange ("All" has the four-dot mark).
  Widget _categoryTile({
    required String label,
    String? image,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: EdgeInsets.all(image == null ? 0 : 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF5216), Color(0xFFFF9A3D)],
                        )
                      : null,
                  color: selected ? null : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: image == null
                    ? Icon(
                        Icons.grid_view_rounded,
                        color: selected
                            ? Colors.white
                            : const Color(0xFFFF5216),
                        size: 28,
                      )
                    : Image.asset(
                        image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _categoryFallback(),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.outfit(
                  color: selected
                      ? const Color(0xFFFF5216)
                      : const Color(0xFF2C2520),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryFallback() {
    return Container(
      color: const Color(0xFFFFF0EA),
      child: const Icon(
        Icons.shopping_basket_outlined,
        color: Color(0xFFFF5216),
        size: 22,
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onTap, {
    bool showMapIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          showMapIcon
              ? StoreMapButton(onTap: onTap)
              : SeeAllButton(onTap: onTap),
        ],
      ),
    );
  }

  Widget _buildFastDeliveryList() {
    return SizedBox(
      height: 172,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fastDeliveryStores.length,
        itemBuilder: (context, index) {
          final store = fastDeliveryStores[index];
          return GestureDetector(
            onTap: () => ExpressStores.open(store),
            child: Container(
              width: 170,
              margin: const EdgeInsetsDirectional.only(end: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        store['image']!,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 110,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.store, color: Colors.grey),
                        ),
                      ),
                      PositionedDirectional(
                        start: 10,
                        bottom: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _pointsBadge(store['points']!),
                            const SizedBox(width: 6),
                            _timeBadge(store['time']!),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name']!,
                          style: AppFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFAE00),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              store['rating']!,
                              style: AppFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFFF5216),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              store['dist']!,
                              style: AppFonts.outfit(
                                color: const Color(0xFF4A453F),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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
        },
      ),
    );
  }

  Widget _buildTrendingList(HomeController controller) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trendingStores.length,
        itemBuilder: (context, index) {
          return _buildStoreCard(
            controller,
            trendingStores[index],
            width: 280,
            marginRight: 14,
          );
        },
      ),
    );
  }

  Widget _buildNearbyStoresList(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: nearbyStores.map((store) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildStoreCard(controller, store, fullWidth: true),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoreCard(
    HomeController controller,
    Map<String, dynamic> store, {
    double? width,
    double marginRight = 0,
    bool fullWidth = false,
  }) {
    final imageHeight = fullWidth ? 170.0 : 140.0;
    final imagePath = (store['image'] ?? '').toString();
    final isAsset = store['isAsset'] == true || imagePath.startsWith('lib/');

    return GestureDetector(
      onTap: () => ExpressStores.open(store),
      child: Container(
        width: fullWidth ? double.infinity : width,
        margin: EdgeInsetsDirectional.only(end: marginRight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: isAsset
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _storeImageFallback(imageHeight),
                          )
                        : Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _storeImageFallback(imageHeight),
                          ),
                  ),
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFAE00),
                            size: 11,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            store['rating']!.toString(),
                            style: AppFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Obx(() {
                      final liked = controller.isLiked(store['id']!.toString());
                      return GestureDetector(
                        onTap: () => controller.toggleLike(
                          store['id']!.toString(),
                          store,
                        ),
                        child: Container(
                          width: 30,
                          height: 30,
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
                            size: 16,
                          ),
                        ),
                      );
                    }),
                  ),
                  PositionedDirectional(
                    start: 10,
                    bottom: 8,
                    child: _pointsBadge(store['points']!.toString()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['name']!.toString(),
                    style: AppFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFFF5216),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store['time']!.toString(),
                        style: AppFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF5216),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store['dist']!.toString(),
                        style: AppFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
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

  Widget _storeImageFallback(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.store, size: 40, color: Colors.grey),
    );
  }

  Widget _pointsBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            errorBuilder: (_, _, _) => const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFAE00),
              size: 14,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppFonts.outfit(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(
            time,
            style: AppFonts.outfit(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
