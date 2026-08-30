import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';
import 'coupons_screen.dart';
import 'restaurant_details_screen.dart';
import 'store_map_screen.dart';
import 'under_30_min_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final bool showUnder30Minutes;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    this.showUnder30Minutes = true,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  bool _showStickySearch = false;

  /// search(48) + gap(16) + filters(34) + bottom gap(12)
  static const double _searchFiltersExtent = 110;

  final subcategories = [
    {'label': 'All', 'isAll': true},
    {
      'label': 'Meals',
      'image':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Breakfast',
      'image':
          'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Drinks',
      'image':
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Desserts',
      'image':
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Cafes',
      'image':
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=100&auto=format&fit=crop',
    },
  ];

  final List<Map<String, dynamic>> items = [
    {
      'id': 'c1',
      'title': 'Al Fantasia',
      'subtitle': 'Moroccan • Traditional',
      'rating': '4.6',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '50% OFF',
      'points': '200 Points Available',
      'isClosed': true,
      'opensAt': '10 AM',
      'isTemporarilyClosed': false,
      'image':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=350&auto=format&fit=crop',
    },
    {
      'id': 'c2',
      'title': 'Tarif Restaurant',
      'subtitle': 'Lebanese • Grill',
      'rating': '4.7',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'isClosed': false,
      'isTemporarilyClosed': true,
      'image':
          'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=350&auto=format&fit=crop',
    },
    {
      'id': 'c3',
      'title': 'Portuguese restaurant',
      'subtitle': 'Lebanese • Grill',
      'rating': '4.7',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'isClosed': false,
      'isTemporarilyClosed': false,
      'image':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=350&auto=format&fit=crop',
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
    final topInset = MediaQuery.paddingOf(context).top;
    final shouldShow = top <= topInset + 2;
    if (shouldShow != _showStickySearch) {
      setState(() => _showStickySearch = shouldShow);
    }
  }

  List<Map<String, dynamic>> get _filters => [
    {'label': 'Filter', 'icon': Image.asset("lib/assets/images/Filter.png")},
    {'label': 'Veg', 'isVeg': true},
    {'label': 'Offers', 'icon': Image.asset("lib/assets/images/Offer.png")},
    {'label': 'Ratings 4.0+', 'icon': Icons.star_rounded},
  ];

  Widget _buildSearchFiltersSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildFiltersRow(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'What do you need today?',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Image.asset(
              "lib/assets/images/Camera.png",
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 12),
            Image.asset(
              "lib/assets/images/Voice.png",
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    final filters = _filters;
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isVeg = filter['isVeg'] == true;
          return GestureDetector(
            onTap: () {
              if (filter['label'] == 'Filter') {
                _showFilterBottomSheet(context);
              } else if (filter['label'] == 'Offers') {
                Get.to(() => const CouponsScreen());
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEAD8C9),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isVeg) ...[
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ] else if (filter['icon'] != null) ...[
                    if (filter['icon'] is IconData)
                      Icon(
                        filter['icon'] as IconData,
                        color: filter['label'] == 'Ratings 4.0+'
                            ? const Color(0xFFFFAE00)
                            : const Color(0xFF7A6A60),
                        size: 14,
                      )
                    else if (filter['icon'] is Widget)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: filter['icon'] as Widget,
                      ),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCollapsingHeader(
    HomeController controller,
    String displayTitle,
  ) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFFF5E00),
                        size: 16,
                      ),
                    ),
                  ),
                  Text(
                    displayTitle,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            SizedBox(
              height: 86,
              child: Obx(() {
                final selectedIndex =
                    controller.selectedSubcategoryIndex.value;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subcategories.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  itemBuilder: (context, index) {
                    final sub = subcategories[index];
                    final isAll = sub['isAll'] == true;
                    final isSelected = selectedIndex == index;
                    return GestureDetector(
                      onTap: () => controller.selectSubcategory(index),
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == subcategories.length - 1 ? 0 : 10,
                        ),
                        child: SizedBox(
                          width: 62,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Column(
                                children: [
                                  isAll
                                      ? Container(
                                          width: 46,
                                          height: 46,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              'lib/assets/images/All.png',
                                              width: 22,
                                              height: 22,
                                              color: const Color(0xFFFF5E00),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.10),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Image.network(
                                              sub['image'] as String,
                                              width: 46,
                                              height: 46,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) =>
                                                  Container(
                                                width: 46,
                                                height: 46,
                                                color: const Color(0xFFEAD8C9),
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  color: Colors.grey,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sub['label'] as String,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: GoogleFonts.outfit(
                                      color: isSelected
                                          ? const Color(0xFFFF5E00)
                                          : const Color(0xFF3A312C),
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  child: Container(
                                    height: 10,
                                    width: 56,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFF5E00),
                                          Color(0xFFFFAE00),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final displayTitle =
        widget.categoryName == 'Trending' ? 'Food' : widget.categoryName;
    final topInset = MediaQuery.paddingOf(context).top;

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
            Positioned.fill(
              child: Obx(() {
                final selectedSubIndex =
                    controller.selectedSubcategoryIndex.value;
                final filteredItems = selectedSubIndex == 0
                    ? items
                    : (selectedSubIndex == 1
                          ? [items[0]]
                          : (selectedSubIndex == 2
                                ? [items[1]]
                                : (selectedSubIndex == 3
                                      ? [items[2]]
                                      : items)));

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCollapsingHeader(controller, displayTitle),
                      const SizedBox(height: 8),
                      KeyedSubtree(
                        key: _searchAnchorKey,
                        child: _showStickySearch
                            ? const SizedBox(height: _searchFiltersExtent)
                            : _buildSearchFiltersSection(),
                      ),
                      if (!widget.showUnder30Minutes) ...[
                        const SizedBox(height: 12),
                        _buildTrendingSectionHeader(showSeeAll: false),
                        const SizedBox(height: 12),
                        ...filteredItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildTrendingRestaurantCard(
                              controller,
                              item,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        _buildUnder30MinSection(controller),
                        const SizedBox(height: 20),
                        _buildTrendingSectionHeader(
                          showSeeAll: true,
                          onSeeAll: () {
                            Get.to(
                              () => CategoryScreen(
                                categoryName: displayTitle,
                                showUnder30Minutes: false,
                              ),
                              preventDuplicates: false,
                              routeName: '/trending-see-all',
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        ...filteredItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildTrendingRestaurantCard(
                              controller,
                              item,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
            if (_showStickySearch)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 2,
                  color: const Color(0xFFFAF6F0),
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset, bottom: 0),
                    child: _buildSearchFiltersSection(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSectionHeader({
    required bool showSeeAll,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Trending in Nouakchott',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFFFF5E00),
                size: 18,
              ),
            ],
          ),
          if (showSeeAll)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSeeAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => Get.to(() => const StoreMapScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF5E00),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Store Map',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFFF5E00),
                      size: 11,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingRestaurantCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final isClosed =
        item['isClosed'] == true || item['isClosed'] == 'true';
    final isTemporarilyClosed = item['isTemporarilyClosed'] == true ||
        item['isTemporarilyClosed'] == 'true';
    return GestureDetector(
      onTap: () {
        Get.to(() => RestaurantDetailsScreen(restaurant: item));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFEAD8C9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF3EFEA),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
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
                        item['discount']!,
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
                    left: 70,
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
                            item['rating']!,
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
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Obx(() {
                      final liked = controller.isLiked(item['id']!);
                      return GestureDetector(
                        onTap: () =>
                            controller.toggleLike(item['id']!, item),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: const Color(0xFFE03A3A),
                            size: 16,
                          ),
                        ),
                      );
                    }),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "lib/assets/images/Coin.png",
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['points']!,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isClosed) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                    Positioned.fill(
                      child: _buildClosedOverlay(
                        (item['opensAt'] ?? '10 AM').toString(),
                      ),
                    ),
                  ] else if (isTemporarilyClosed) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                    Positioned.fill(
                      child: _buildTemporarilyClosedOverlay(),
                    ),
                  ],
                ],
              ),
            ),
            ColoredBox(
              color: (isClosed || isTemporarilyClosed)
                  ? const Color(0xFFC4BBB3)
                  : Colors.white,
              child: Opacity(
                opacity: (isClosed || isTemporarilyClosed) ? 0.85 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle']!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 11,
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
                            item['time']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 11,
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
                            item['dist']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 11,
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


  Widget _buildUnder30MinSection(HomeController controller) {
    final under30Items = [
      {
        'id': 'u1',
        'title': 'Al Fantasia',
        'subtitle': 'Moroccan • Traditional',
        'rating': '4.6',
        'time': '30m',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'isTemporarilyClosed': false,
        'image':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=350&auto=format&fit=crop',
      },
      {
        'id': 'u2',
        'title': 'Tarif Restaurant',
        'subtitle': 'Lebanese • Grill',
        'rating': '4.6',
        'time': '30m',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'isTemporarilyClosed': false,
        'image':
            'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=350&auto=format&fit=crop',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Under 30 Minutes',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Get.to(() => const Under30MinScreen()),
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: under30Items.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildUnder30MinCard(controller, under30Items[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnder30MinCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final isClosed = item['isClosed'] == true || item['isClosed'] == 'true';
    final isTemporarilyClosed = item['isTemporarilyClosed'] == true ||
        item['isTemporarilyClosed'] == 'true';
    return GestureDetector(
      onTap: () {
        Get.to(() => RestaurantDetailsScreen(restaurant: item));
      },
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      (item['image'] ?? '').toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF3EFEA),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
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
                        (item['discount'] ?? '').toString(),
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
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
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
                            (item['rating'] ?? '').toString(),
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
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "lib/assets/images/Coin.png",
                                width: 12,
                                height: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (item['points'] ?? '').toString(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                (item['time'] ?? '').toString(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isClosed) ...[
                    Positioned.fill(
                      child: Container(color: Colors.black.withOpacity(0.35)),
                    ),
                    Positioned.fill(
                      child: _buildClosedOverlay(
                        (item['opensAt'] ?? '10 AM').toString(),
                      ),
                    ),
                  ] else if (isTemporarilyClosed) ...[
                    Positioned.fill(
                      child: Container(color: Colors.black.withOpacity(0.35)),
                    ),
                    Positioned.fill(child: _buildTemporarilyClosedOverlay()),
                  ],
                ],
              ),
            ),
            Opacity(
              opacity: (isClosed || isTemporarilyClosed) ? 0.65 : 1.0,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['title'] ?? '').toString(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (item['subtitle'] ?? '').toString(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 10,
                      ),
                    ),
                  ],
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _FilterBottomSheetContent();
      },
    );
  }
}

class _FilterBottomSheetContent extends StatefulWidget {
  const _FilterBottomSheetContent({Key? key}) : super(key: key);

  @override
  State<_FilterBottomSheetContent> createState() =>
      _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  final List<String> selectedFoodTags = [];
  RangeValues priceRange = const RangeValues(65, 1500);
  String selectedSortBy = 'Relevance';

  final List<String> foodTags1 = [
    'Spicy',
    'Non Spicy',
    'Sugar Free',
    'Mild Sugar',
  ];
  final List<String> foodTags2 = [
    'Offers',
    'Ratings: 4.5+',
    'Ratings: 4.0+',
    'Ratings: 3.5+',
  ];
  final List<String> sortOptions = [
    'Relevance',
    'Delivery Time',
    'Cost: Low to High',
    'Cost: High to Low',
  ];

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF6F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEAD8C9),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFF2C2520),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalChips(
    List<String> tags,
    List<String> selectedList,
    Function(String) onSelected,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tags.map((tag) {
          final isSelected = selectedList.contains(tag);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildChip(tag, isSelected, () => onSelected(tag)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortChips(
    List<String> options,
    String selectedOption,
    Function(String) onSelected,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: options.map((option) {
          final isSelected = selectedOption == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildChip(option, isSelected, () => onSelected(option)),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 56),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                24,
                0,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 60),
                        Text(
                          'Filters',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFoodTags.clear();
                              priceRange = const RangeValues(65, 1500);
                              selectedSortBy = 'Relevance';
                            });
                          },
                          child: Text(
                            'Clear all',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chips Row 1
                  _buildHorizontalChips(foodTags1, selectedFoodTags, (tag) {
                    setState(() {
                      if (selectedFoodTags.contains(tag)) {
                        selectedFoodTags.remove(tag);
                      } else {
                        selectedFoodTags.add(tag);
                      }
                    });
                  }),
                  const SizedBox(height: 10),

                  // Chips Row 2
                  _buildHorizontalChips(foodTags2, selectedFoodTags, (tag) {
                    setState(() {
                      if (selectedFoodTags.contains(tag)) {
                        selectedFoodTags.remove(tag);
                      } else {
                        selectedFoodTags.add(tag);
                      }
                    });
                  }),
                  const SizedBox(height: 24),

                  // Price Range Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price Range',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${priceRange.start.round()} MRU - ${priceRange.end.round()} MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Range Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF5E00),
                        inactiveTrackColor: const Color(0xFFF3EFEA),
                        activeTickMarkColor: Colors.transparent,
                        inactiveTickMarkColor: Colors.transparent,
                        overlayColor: const Color(0xFFFF5E00).withOpacity(0.12),
                        valueIndicatorColor: const Color(0xFFFF5E00),
                        rangeValueIndicatorShape:
                            const RectangularRangeSliderValueIndicatorShape(),
                        rangeThumbShape: const CustomRangeThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: RangeSlider(
                        values: priceRange,
                        min: 0,
                        max: 3000,
                        divisions: 60,
                        onChanged: (values) {
                          setState(() {
                            priceRange = values;
                          });
                        },
                      ),
                    ),
                  ),

                  // Range Bounds Labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0 MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '3000 MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sort by Header
                  Center(
                    child: Text(
                      'Sort by',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sort by Chips
                  _buildSortChips(sortOptions, selectedSortBy, (option) {
                    setState(() {
                      selectedSortBy = option;
                    });
                  }),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFoodTags.clear();
                                priceRange = const RangeValues(65, 1500);
                                selectedSortBy = 'Relevance';
                              });
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6F1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'Clear All',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF5E00),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5E00),
                                    Color(0xFFFFAE00),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF5E00,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Apply',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating close button
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFFF5E00),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomRangeThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;

  const CustomRangeThumbShape({this.enabledThumbRadius = 10.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isPressed) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb thumb = Thumb.start,
  }) {
    final Canvas canvas = context.canvas;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, enabledThumbRadius, shadowPaint);

    // Draw white background
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    // Draw orange border
    final borderPaint = Paint()
      ..color = const Color(0xFFFF5E00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, enabledThumbRadius - 1.25, borderPaint);
  }
}
