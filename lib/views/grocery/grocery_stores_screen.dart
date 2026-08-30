import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import 'grocery_details_screen.dart';

class GroceryStoresScreen extends StatefulWidget {
  const GroceryStoresScreen({super.key});

  @override
  State<GroceryStoresScreen> createState() => _GroceryStoresScreenState();
}

class _GroceryStoresScreenState extends State<GroceryStoresScreen> {
  int selectedSubcategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  bool _showStickySearch = false;

  /// search(62) + filters(34) + bottom gap(8)
  static const double _searchFiltersExtent = 104;

  final subcategories = [
    {'label': 'All', 'isAll': true},
    {
      'label': 'Fruits',
      'image':
          'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Vegetables',
      'image':
          'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Meat',
      'image':
          'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Masalas',
      'image':
          'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Rice',
      'image':
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=100&auto=format&fit=crop',
    },
  ];

  final List<Map<String, dynamic>> filters = [
    {'label': 'Filter', 'icon': Image.asset("lib/assets/images/Filter.png")},
    {'label': 'Under 200 MRU', 'isMru': true},
    {'label': 'Offers', 'icon': Image.asset("lib/assets/images/Offer.png")},
    {'label': 'Ratings 4.0+', 'icon': Icons.star_rounded},
  ];

  final List<Map<String, dynamic>> groceryStores = [
    {
      'id': 'gs_all1',
      'name': 'Salam Supermarket',
      'category': 'Hypermarket',
      'rating': '4.6',
      'time': '35 min',
      'dist': '10 Km',
      'discount': '50% OFF',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&auto=format&fit=crop',
      'isClosed': true,
      'opensAt': '10 AM',
    },
    {
      'id': 'gs_all2',
      'name': 'Good Choice Store',
      'category': 'Fruits & Veg',
      'rating': '4.7',
      'time': '35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&auto=format&fit=crop',
      'isTemporarilyClosed': true,
    },
    {
      'id': 'gs_all3',
      'name': 'Jawda Stores',
      'category': 'Essentials',
      'rating': '4.7',
      'time': '35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=500&auto=format&fit=crop',
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

  Widget _buildSearchFiltersSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchBar(),
        _buildFiltersRow(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    final isClosed = store['isClosed'] == true;
    final isTemporarilyClosed = store['isTemporarilyClosed'] == true;

    return GestureDetector(
      onTap: () {
        Get.to(() => GroceryDetailsScreen(store: store));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(20),
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
                      store['image']!,
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
                        store['discount']!,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFFFCF8),
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
                            store['rating']!,
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
                      final isLiked = homeController.isLiked(
                        (store['id'] ?? '').toString(),
                      );
                      return GestureDetector(
                        onTap: () => homeController.toggleLike(
                          (store['id'] ?? '').toString(),
                          store,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFCF8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked
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
                            "lib/assets/images/Points.png",
                            width: 12,
                            height: 12,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              "lib/assets/images/Coin.png",
                              width: 12,
                              height: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store['points']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFFFCF8),
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
                        (store['opensAt'] ?? '10 AM').toString(),
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
            Opacity(
              opacity: (isClosed || isTemporarilyClosed) ? 0.65 : 1.0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store['name']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store['category']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFFFF5E00),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          store['time']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFF5E00),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          store['dist']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 11,
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
  }

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
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
                            _buildHeader(context),
                            _buildSubcategoriesRow(),
                          ],
                        ),
                      ),
                    ),
                    KeyedSubtree(
                      key: _searchAnchorKey,
                      child: _showStickySearch
                          ? const SizedBox(height: _searchFiltersExtent)
                          : _buildSearchFiltersSection(),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionHeader(),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: groceryStores
                            .map((store) => _buildStoreCard(store))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
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
                    padding: EdgeInsets.only(top: topInset),
                    child: _buildSearchFiltersSection(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Header App Bar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:Colors.white,
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
            "Grocery",
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 32), // Spacer to balance back button
        ],
      ),
    );
  }

  // Subcategories (inside the white top sheet)
  Widget _buildSubcategoriesRow() {
    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final sub = subcategories[index];
          final isSelected = selectedSubcategoryIndex == index;
          final isAll = sub['isAll'] == true;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedSubcategoryIndex = index;
              });
            },
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
                                      color: Colors.black.withOpacity(0.10),
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
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 46,
                                              height: 46,
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.fastfood,
                                                size: 18,
                                                color: Colors.grey,
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
                              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
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
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(23),
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
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
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
              "lib/assets/images/Camera.png",
              width: 18,
              height: 18,
              color: const Color(0xFFA59A94),
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
                  "lib/assets/images/Voice.png",
                  width: 14,
                  height: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filters Scroll Row
  Widget _buildFiltersRow() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isMru = filter['isMru'] == true;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xFFFFFCF8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMru) ...[
                  Image.asset(
                    "lib/assets/images/Points.png",
                    width: 12,
                    height: 12,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      "lib/assets/images/Coin.png",
                      width: 12,
                      height: 12,
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
          );
        },
      ),
    );
  }

  // Section Title + Store Map Button
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Top Stores Near You',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Store Map button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFFFFCF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF5E00), width: 1),
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
                  Icons.map_outlined,
                  color: Color(0xFFFF5E00),
                  size: 11,
                ),
              ],
            ),
          ),
        ],
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
                    color: Color(0xFFFFFCF8),
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
                        color: Color(0xFFFFFCF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Opens $opensAt',
                      style: GoogleFonts.outfit(
                        color: Color(0xFFFFFCF8),
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
                        color: Color(0xFFFFFCF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Temporarily not accepting',
                      style: GoogleFonts.outfit(
                        color: Color(0xFFFFFCF8),
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
                    color: Color(0xFFFFFCF8),
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

