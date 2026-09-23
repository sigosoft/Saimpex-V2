import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/select_location_controller.dart';
import '../select_location_screen.dart';
import '../rewards_referral_screen.dart';
import 'local_store_details_screen.dart';
import '../../widgets/app_back_button.dart';

class LocalStoreScreen extends StatefulWidget {
  const LocalStoreScreen({super.key});

  @override
  State<LocalStoreScreen> createState() => _LocalStoreScreenState();
}

class _LocalStoreScreenState extends State<LocalStoreScreen> {
  int _bannerIndex = 0;
  final PageController _bannerController = PageController();
  int _selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();
  bool _showStickySearch = false;

  /// search bar height (48) + small padding
  static const double _stickyExtent = 56;

  final List<String> banners = [
    'lib/assets/images/Local store banner.png',
    'lib/assets/images/Local store banner.png',
    'lib/assets/images/Local store banner.png',
  ];

  final List<Map<String, dynamic>> categories = [
    {
      'label': 'All',
      'icon': 'lib/assets/images/All.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'label': 'Bakery',
      'icon': 'lib/assets/images/croissant.png',
      'gradient': const LinearGradient(
        colors: [Color.fromARGB(255, 183, 180, 177), Color(0xFFFFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Spice Trade',
      'icon': 'lib/assets/images/Spices.png',
      'gradient': const LinearGradient(
        colors:[Color.fromARGB(255, 183, 180, 177), Color(0xFFFFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Florist',
      'icon': 'lib/assets/images/Flowers.png',
      'gradient': const LinearGradient(
        colors: [Color.fromARGB(255, 183, 180, 177), Color(0xFFFFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Fish Market',
      'icon': 'lib/assets/images/Fish.png',
      'gradient': const LinearGradient(
        colors:[Color.fromARGB(255, 183, 180, 177), Color(0xFFFFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Stationery',
      'icon': 'lib/assets/images/Stationery.png',
      'gradient': const LinearGradient(
        colors: [Color.fromARGB(255, 183, 180, 177), Color(0xFFFFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
  ];

  final List<Map<String, dynamic>> nearbyStores = [
    {
      'id': 'ls_1',
      'name': 'Golden Bakery',
      'subtitle': 'Bakery - Pastries',
      'rating': '4.6',
      'time': '35 min',
      'dist': '1.8 Km',
      'discount': '50% OFF',
      'points': '200 Points Available',
      'image': 'lib/assets/images/golden_bakery.png',
      'isFavorite': false,
    },
    {
      'id': 'ls_2',
      'name': 'Fresh Fish Market',
      'subtitle': 'Fish & Seafood',
      'rating': '4.5',
      'time': '20 min',
      'dist': '2.5 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'image': 'lib/assets/images/Fish.png',
      'isFavorite': false,
      'isClosed': true,
      'opensAt': '10 AM',
    },
  ];

  final List<Map<String, dynamic>> allStores = [
    {
      'id': 'ls_3',
      'name': 'City Florist',
      'subtitle': 'Flowers',
      'rating': '4.7',
      'time': '35 min',
      'dist': '1.8 Km',
      'discount': '30% OFF',
      'points': '250 Points Available',
      'image': 'lib/assets/images/city_florist.png',
      'isFavorite': false,
    },
    {
      'id': 'ls_4',
      'name': 'Nouakchott Stationery',
      'subtitle': 'Books',
      'rating': '4.7',
      'time': '35 min',
      'dist': '1.8 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'image': 'lib/assets/images/browse_stationery.png',
      'isFavorite': false,
    },
    {
      'id': 'ls_5',
      'name': 'Dessert Sweets',
      'subtitle': 'Sweets',
      'rating': '4.7',
      'time': '35 min',
      'dist': '1.8 Km',
      'discount': '30% OFF',
      'points': '250 Points Available',
      'image': 'lib/assets/images/dessert_sweet.png',
      'isFavorite': false,
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
    _bannerController.dispose();
    super.dispose();
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
              color: Color(0xFFA0938A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'What do you need today?',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFA0938A),
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFFA0938A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFDECE2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF7F2),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F2),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    key: _headerKey,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),

                      // Fixed header: back, location, wallet
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            AppBackButton(onTap: () => Navigator.pop(context)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    Get.to(() => const SelectLocationScreen()),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.home_outlined,
                                      color: Color(0xFFFF5E00),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Deliver To:',
                                                style: GoogleFonts.outfit(
                                                  color:
                                                      const Color(0xFF8C7D73),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  SelectLocationController
                                                      .selectedTitle,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(
                                                      0xFF2C2520,
                                                    ),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
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
                        GestureDetector(
                          onTap: () =>
                              Get.to(() => const RewardsReferralScreen()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5E00),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5E00,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🪙',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '200 MRU',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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

                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Title: Local Stores
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Local Stores',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Banner carousel
                          SizedBox(
                            height: 145,
                            child: PageView.builder(
                              controller: _bannerController,
                              itemCount: banners.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _bannerIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      banners[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: const Color(0xFFFEDDC7),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.storefront_rounded,
                                                    size: 50,
                                                    color: const Color(
                                                      0xFFFF5E00,
                                                    ).withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Banner indicator dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              banners.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: _bannerIndex == index ? 24 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _bannerIndex == index
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFE5D5C9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Pins when scrolled: search
                          KeyedSubtree(
                            key: _searchAnchorKey,
                            child: _showStickySearch
                                ? const SizedBox(height: _stickyExtent)
                                : _buildSearchBar(),
                          ),

                          const SizedBox(height: 20),

              // 5. Category Icons Grid matching Pharmacy screen design
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.30,
                  ),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategoryIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
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
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFE5102),
                                          Color(0xFFFFAE00),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : (cat['gradient'] as Gradient?),
                                borderRadius: BorderRadius.circular(20),
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
                                cat['label'] as String,
                                style: GoogleFonts.outfit(
                                  color: isSelected
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
                            top: (cat['label'] == 'All')
                                ? 12
                                : (cat['label'] == 'Stationery' ? -2 : 0),
                            left: (cat['label'] == 'All')
                                ? 0
                                : (cat['label'] == 'Stationery' ? 18 : 24),
                            right: (cat['label'] == 'All')
                                ? 0
                                : (cat['label'] == 'Stationery' ? 18 : 24),
                            bottom: (cat['label'] == 'All') ? 22 : 22,
                            child: (cat['label'] == 'All')
                                ? Center(
                                    child: Image.asset(
                                      cat['icon'] as String,
                                      width: 28,
                                      height: 28,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFFF5E00),
                                    ),
                                  )
                                : Image.asset(
                                    cat['icon'] as String,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.store_rounded,
                                      color: Color(0xFFFF5E00),
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 6. "Local Stores Nearby" Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Local Stores Nearby',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'See All',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFFF5E00),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Local Stores Nearby Horizontal List
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: nearbyStores.length,
                  itemBuilder: (context, index) {
                    final store = nearbyStores[index];
                    return _buildHorizontalStoreCard(store);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 7. "Browse All Stores" Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Browse All Stores',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Store Map',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CustomPaint(
                              painter: _StoreMapPinPainter(
                                color: Color(0xFFFF5E00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Browse All Stores Vertical List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allStores.length,
                  itemBuilder: (context, index) {
                    final store = allStores[index];
                    return _buildVerticalStoreCard(store);
                  },
                ),
              ),

              const SizedBox(height: 30),
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
                child: Material(
                  elevation: 2,
                  color: const Color(0xFFFFF7F2),
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

  // Horizontal Store Card
  Widget _buildHorizontalStoreCard(Map<String, dynamic> store) {
    final isClosed = store['isClosed'] == true;
    final opensAt = (store['opensAt'] ?? '10 AM').toString();

    return GestureDetector(
      onTap: () {
        Get.to(() => LocalStoreDetailsScreen(store: store));
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isClosed
              ? Colors.white.withValues(alpha: 0.72)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: isClosed
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
                              child: Image.asset(
                                store['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF3E7DC),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    size: 40,
                                    color: Color(0xFFFF5E00),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Image.asset(
                            store['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF3E7DC),
                              child: const Icon(
                                Icons.storefront_rounded,
                                size: 40,
                                color: Color(0xFFFF5E00),
                              ),
                            ),
                          ),
                  ),
                ),

                if (isClosed)
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

                // Top Left Badges (Discount + Rating)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          store['discount'],
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
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
                              store['rating'],
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Heart Button Top Right
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        store['isFavorite'] = !(store['isFavorite'] ?? false);
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        store['isFavorite'] == true
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: store['isFavorite'] == true
                            ? const Color(0xFFFF5E00)
                            : const Color(0xFF2C2520),
                        size: 16,
                      ),
                    ),
                  ),
                ),

                // Points Badge Bottom Left on Image
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          store['points'],
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
                  Positioned.fill(
                    child: _buildClosedOverlay(opensAt),
                  ),
              ],
            ),

            // Card Text Details
            ClipRect(
              child: BackdropFilter(
                filter: isClosed
                    ? ImageFilter.blur(sigmaX: 12, sigmaY: 12)
                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  width: double.infinity,
                  color: isClosed
                      ? const Color(0xFFE8E8E8).withValues(alpha: 0.78)
                      : Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        store['subtitle'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7D73),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFFFF5E00),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            store['time'],
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF6B635C),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFFF5E00),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            store['dist'],
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF6B635C),
                              fontSize: 10,
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

  // Vertical Store Card
  Widget _buildVerticalStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        Get.to(() => LocalStoreDetailsScreen(store: store));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.asset(
                      store['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF3E7DC),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 40,
                          color: Color(0xFFFF5E00),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Left Badges (Discount + Rating)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          store['discount'],
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFAE00),
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              store['rating'],
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite Heart Button Top Right
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        store['isFavorite'] = !(store['isFavorite'] ?? false);
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        store['isFavorite'] == true
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: store['isFavorite'] == true
                            ? const Color(0xFFFF5E00)
                            : const Color(0xFF2C2520),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // Points Badge Bottom Left on Image
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 5),
                        Text(
                          store['points'],
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Text Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['name'],
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    store['subtitle'],
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C7D73),
                      fontSize: 12,
                    ),
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
                        store['time'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6B635C),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF5E00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store['dist'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF6B635C),
                          fontSize: 11,
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
}

/// Outline pin-on-map icon matching the Store Map mock.
class _StoreMapPinPainter extends CustomPainter {
  const _StoreMapPinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Folded map base (rounded trapezoid)
    final mapTop = h * 0.64;
    final mapBottom = h * 0.94;
    final map = Path()
      ..moveTo(w * 0.12, mapBottom)
      ..lineTo(w * 0.26, mapTop)
      ..lineTo(w * 0.74, mapTop)
      ..lineTo(w * 0.88, mapBottom)
      ..close();
    canvas.drawPath(map, stroke);

    // Pin head
    final pinCy = h * 0.28;
    final pinR = w * 0.20;
    canvas.drawCircle(Offset(cx, pinCy), pinR, stroke);

    // Solid center dot
    canvas.drawCircle(Offset(cx, pinCy), pinR * 0.32, fill);

    // Pin tip down onto the map
    final stemTop = pinCy + pinR * 0.72;
    final stem = Path()
      ..moveTo(cx - pinR * 0.50, stemTop)
      ..lineTo(cx, mapTop)
      ..lineTo(cx + pinR * 0.50, stemTop);
    canvas.drawPath(stem, stroke);
  }

  @override
  bool shouldRepaint(covariant _StoreMapPinPainter oldDelegate) =>
      oldDelegate.color != color;
}
