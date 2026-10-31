import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final categories = [
    {
      'label': 'st_cat_fruits_veg',
      'image': 'lib/assets/images/Fruits & Veg.png',
      'isAsset': true,
    },
    {
      'label': 'st_cat_snacks',
      'image': 'lib/assets/images/Snacks.png',
      'isAsset': true,
    },
    {
      'label': 'st_cat_beverages',
      'image':
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=120&auto=format&fit=crop',
    },
    {
      'label': 'st_cat_dairy_eggs',
      'image':
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=120&auto=format&fit=crop',
    },
    {
      'label': 'st_cat_bakery',
      'image': 'lib/assets/images/Bakery.png',
      'isAsset': true,
    },
    {
      'label': 'st_cat_household',
      'image': 'lib/assets/images/household.png',
      'isAsset': true,
    },
    {
      'label': 'st_cat_personal_care',
      'image': 'lib/assets/images/PersonalCare.png',
      'isAsset': true,
    },
    {
      'label': 'st_cat_baby_care',
      'image': 'lib/assets/images/BabyCare.png',
      'isAsset': true,
    },
  ];

  List<Map<String, String>> _stores = ExpressStores.stores;

  // Nearest first from the API; the fast list is the closest few and
  // trending is the best rated.
  List<Map<String, String>> get fastDeliveryStores => _stores.take(6).toList();

  List<Map<String, String>> get trendingStores {
    final sorted = [..._stores]
      ..sort(
        (a, b) => (double.tryParse(b['rating']!) ?? 0).compareTo(
          double.tryParse(a['rating']!) ?? 0,
        ),
      );
    return sorted.take(6).toList();
  }

  List<Map<String, String>> get nearbyStores => _stores;

  Future<void> _loadStores() async {
    try {
      final stores = await ExpressStores.load();
      if (!mounted) return;
      setState(() => _stores = stores);
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
                        style: GoogleFonts.outfit(
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
                    _buildSectionHeader(
                      'st_15_min_delivery'.tr,
                      'See All',
                      () =>
                          Get.to(() => const ExpressFifteenMinDeliveryScreen()),
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
                      color: Color(0xFFFF5E00),
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
                          style: GoogleFonts.outfit(
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
                    color: const Color(0xFFFF5E00),
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
                    ? const Color(0xFFFF5E00)
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
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'st_search_hint'.tr,
                  hintStyle: GoogleFonts.outfit(
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
                    color: Color(0xFFFF5E00),
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

  Widget _buildShopByCategory() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'st_shop_by_category'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SeeAllButton(),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isAsset = cat['isAsset'] == true;
              return Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: isAsset
                          ? Image.asset(
                              cat['image'] as String,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => _categoryFallback(),
                            )
                          : Image.network(
                              cat['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _categoryFallback(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (cat['label'] as String).tr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _categoryFallback() {
    return Container(
      color: const Color(0xFFFFF0EA),
      child: const Icon(
        Icons.shopping_basket_outlined,
        color: Color(0xFFFF5E00),
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
            style: GoogleFonts.outfit(
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
                      Positioned(
                        left: 10,
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
                          style: GoogleFonts.outfit(
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
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFFF5E00),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              store['dist']!,
                              style: GoogleFonts.outfit(
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
                  Positioned(
                    top: 10,
                    left: 10,
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
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
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
                  Positioned(
                    left: 10,
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
                    style: GoogleFonts.outfit(
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
                        color: Color(0xFFFF5E00),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store['time']!.toString(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF4A453F),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
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
                        store['dist']!.toString(),
                        style: GoogleFonts.outfit(
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
            style: GoogleFonts.outfit(
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
            style: GoogleFonts.outfit(
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
