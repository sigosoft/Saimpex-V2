import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import 'express_fifteen_min_delivery_screen.dart';
import 'express_trending_screen.dart';
import 'express_store_detail_screen.dart';
import 'express_store_map_screen.dart';

class ExpressScreen extends StatefulWidget {
  const ExpressScreen({super.key});

  @override
  State<ExpressScreen> createState() => _ExpressScreenState();
}

class _ExpressScreenState extends State<ExpressScreen> {
  int _bannerIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool _showStickySearch = false;

  /// search bar (46) + padding (14 top, 8 bottom)
  static const double _stickyExtent = 68;

  final categories = [
    {
      'label': 'Fruits & Veg',
      'image': 'lib/assets/images/Fruits & Veg.png',
      'isAsset': true,
    },
    {
      'label': 'Snacks',
      'image': 'lib/assets/images/Snacks.png',
      'isAsset': true,
    },
    {
      'label': 'Beverages',
      'image':
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=120&auto=format&fit=crop',
    },
    {
      'label': 'Dairy & Eggs',
      'image':
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=120&auto=format&fit=crop',
    },
    {
      'label': 'Bakery',
      'image': 'lib/assets/images/Bakery.png',
      'isAsset': true,
    },
    {
      'label': 'Household',
      'image': 'lib/assets/images/household.png',
      'isAsset': true,
    },
    {
      'label': 'Personal Care',
      'image': 'lib/assets/images/PersonalCare.png',
      'isAsset': true,
    },
    {
      'label': 'Baby Care',
      'image': 'lib/assets/images/BabyCare.png',
      'isAsset': true,
    },
  ];

  final fastDeliveryStores = [
    {
      'id': 'e_fast1',
      'name': 'Freshmart',
      'rating': '4.6',
      'dist': '1.2 Km',
      'time': '15m',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=350&auto=format&fit=crop',
    },
    {
      'id': 'e_fast2',
      'name': 'Express Hub',
      'rating': '4.5',
      'dist': '1.5 Km',
      'time': '15m',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=350&auto=format&fit=crop',
    },
    {
      'id': 'e_fast3',
      'name': 'Quick Pick',
      'rating': '4.7',
      'dist': '0.8 Km',
      'time': '15m',
      'points': '180 Points Available',
      'image':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=350&auto=format&fit=crop',
    },
  ];

  final trendingStores = [
    {
      'id': 'e_t1',
      'name': 'Quick Mart',
      'rating': '4.6',
      'time': '15-20 min',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=500&auto=format&fit=crop',
    },
    {
      'id': 'e_t2',
      'name': 'City Express',
      'rating': '4.5',
      'time': '15-20 min',
      'dist': '8 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&auto=format&fit=crop',
    },
  ];

  final nearbyStores = [
    {
      'id': 'e_n1',
      'name': 'Fresh Bites',
      'rating': '4.6',
      'time': '15-20 min',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=600&auto=format&fit=crop',
    },
    {
      'id': 'e_n2',
      'name': 'Sante Pharmacy',
      'rating': '4.6',
      'time': '15-20 min',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image': 'lib/assets/images/Pharmacy.png',
      'isAsset': true,
    },
    {
      'id': 'e_n3',
      'name': 'Pure Care Store',
      'rating': '4.6',
      'time': '15-20 min',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=600&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    final ctx = _searchAnchorKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final topInset = MediaQuery.paddingOf(context).top;
    // Pin once search reaches under the fixed location header (~56px)
    final shouldShow = top <= topInset + 56;
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
          colors: [
            Color(0xFFFFDDCF),
            Color(0xFFFFEEE5),
            Color(0xFFFAF6F0),
          ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Text(
                              'Express',
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
                            '15-Min Delivery',
                            'See All',
                            () => Get.to(
                              () => const ExpressFifteenMinDeliveryScreen(),
                            ),
                          ),
                          _buildFastDeliveryList(),
                          _buildSectionHeader(
                            'Trending in express',
                            'See All',
                            () => Get.to(() => const ExpressTrendingScreen()),
                          ),
                          _buildTrendingList(controller),
                          _buildSectionHeader(
                            'Nearby Stores',
                            'Store Map',
                            () => Get.to(() => const ExpressStoreMapScreen()),
                            showMapIcon: true,
                          ),
                          _buildNearbyStoresList(controller),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sticky search (below fixed location header)
            if (_showStickySearch)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 56,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 2,
                  color: const Color(0xFFFFEEE5),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/images/Home.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const Icon(
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
                        'Deliver To',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              SelectLocationController.selectedTitle,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/assets/images/Coin.png',
                  width: 16,
                  height: 16,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '300 MRU',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
            itemBuilder: (_, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 148,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
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
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'What do you need today?',
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
            Image.asset(
              'lib/assets/images/Camera.png',
              width: 18,
              height: 18,
              color: const Color(0xFFA59A94),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFA59A94),
                size: 18,
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
                  errorBuilder: (_, __, ___) => const Icon(
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
                'Shop by category',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  Text(
                    'See All',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFF5E00),
                    size: 9,
                  ),
                ],
              ),
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
              childAspectRatio: 0.78,
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
                              errorBuilder: (_, __, ___) => _categoryFallback(),
                            )
                          : Image.network(
                              cat['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _categoryFallback(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['label'] as String,
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
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                if (showMapIcon) ...[
                  const Icon(
                    Icons.map_outlined,
                    color: Color(0xFFFF5E00),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  actionText,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!showMapIcon) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFF5E00),
                    size: 9,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastDeliveryList() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fastDeliveryStores.length,
        itemBuilder: (context, index) {
          final store = fastDeliveryStores[index];
          return GestureDetector(
            onTap: () => Get.to(() => ExpressStoreDetailScreen(store: store)),
            child: Container(
            width: 170,
            margin: const EdgeInsets.only(right: 12),
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
                      errorBuilder: (_, __, ___) => Container(
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
      height: 230,
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
      onTap: () => Get.to(() => ExpressStoreDetailScreen(store: store)),
      child: Container(
      width: fullWidth ? double.infinity : width,
      margin: EdgeInsets.only(right: marginRight),
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
                          errorBuilder: (_, __, ___) =>
                              _storeImageFallback(imageHeight),
                        )
                      : Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
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
            errorBuilder: (_, __, ___) => const Icon(
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
          const Icon(
            Icons.access_time_rounded,
            color: Colors.white,
            size: 11,
          ),
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
