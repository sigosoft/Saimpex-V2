import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saimpex_v2/controllers/home_controller.dart';
import '../chat_screen.dart';
import '../cart_screen.dart';
import '../../widgets/bottom_chat_icon.dart';
import 'local_store_cart_screen.dart';

class LocalStoreDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const LocalStoreDetailsScreen({super.key, required this.store});

  @override
  State<LocalStoreDetailsScreen> createState() =>
      _LocalStoreDetailsScreenState();
}

class _LocalStoreDetailsScreenState extends State<LocalStoreDetailsScreen> {
  int _selectedCategoryIndex = 0;
  bool _isFavorite = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool _showStickySearch = false;

  /// categories(~112) + gap(16) + search(48)
  static const double _stickyExtent = 176;

  final List<Map<String, String>> categoryTabs = [
    {'label': 'All', 'icon': 'lib/assets/images/All.png'},
    {'label': 'Breads', 'icon': 'lib/assets/images/Cookies.png'},
    {'label': 'Pastries', 'icon': 'lib/assets/images/Cookies.png'},
    {'label': 'Cakes', 'icon': 'lib/assets/images/Cookies.png'},
    {'label': 'Savory', 'icon': 'lib/assets/images/Cookies.png'},
    {'label': 'Cookie', 'icon': 'lib/assets/images/Cookies.png'},
  ];

  final List<Map<String, dynamic>> products = [
    {
      'id': 'ls_prod1',
      'title': 'Butter Croissant',
      'image': 'lib/assets/images/Bakery.png',
      'rating': '4.6',
      'reviews': '(10k + reviews)',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
    {
      'id': 'ls_prod2',
      'title': 'Artisan Bread Loaf',
      'image': 'lib/assets/images/Cookies.png',
      'rating': '4.6',
      'reviews': '(10k + reviews)',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
    {
      'id': 'ls_prod3',
      'title': 'Pain Au Chocolat',
      'image': 'lib/assets/images/Bakery.png',
      'rating': '4.6',
      'reviews': '(10k + reviews)',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
    {
      'id': 'ls_prod4',
      'title': 'Citrus Lemon Tart',
      'image': 'lib/assets/images/Cookies.png',
      'rating': '4.6',
      'reviews': '(10k + reviews)',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
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

  Widget _buildStickySection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCategoriesRow(),
        const SizedBox(height: 16),
        _buildSearchBar(),
      ],
    );
  }

  Widget _buildCategoriesRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.only(top: 4),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: 86,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categoryTabs.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          itemBuilder: (context, index) {
            final cat = categoryTabs[index];
            final isAll = index == 0;
            final isSelected = _selectedCategoryIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == categoryTabs.length - 1 ? 0 : 10,
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
                                  width: 46,
                                  height: 46,
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
                                    child: Image.asset(
                                      cat['icon']!,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 46,
                                        height: 46,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.storefront_rounded,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label']!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
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
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Find something from this bakery',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA0938A),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
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
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final storeName = widget.store['name'] ?? 'Golden Bakery';
    final subtitle = widget.store['subtitle'] ?? 'Bakery - Pastries';
    final rating = widget.store['rating'] ?? '4.6';
    final time = widget.store['time'] ?? '35 min';
    final dist = widget.store['dist'] ?? '1.8 Km';
    final discount = widget.store['discount'] ?? '50% OFF';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFF7F2),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F2),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image + floating store info card
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: 210,
                        width: double.infinity,
                        child: Image.asset(
                          'lib/assets/images/Localstore slider.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFFEDDC7),
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 60,
                              color: Color(0xFFFF5E00),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 135,
                          left: 16,
                          right: 16,
                        ),
                        child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line 1: Store Name & Rating Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  storeName,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00875A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 3),

                          // Line 2: Subtitle / Category
                          Text(
                            subtitle,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8C7D73),
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Line 3: Info Row (Time, Distance, Discount Tag)
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFFFF5E00),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
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
                                dist,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF6B635C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5E00),
                                  borderRadius: BorderRadius.circular(8),
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
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Line 4: Action Buttons Row ("Chat with Shop" & Favorite Heart)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () =>
                                          ChatScreen(restaurant: widget.store),
                                    );
                                  },
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5E00),
                                          Color(0xFFFFAE00),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(23),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const BottomChatIcon(
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Chat with Shop',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isFavorite = !_isFavorite;
                                  });
                                },
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFEAD8C9),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: _isFavorite
                                        ? const Color(0xFFFF5E00)
                                        : const Color(0xFF2C2520),
                                    size: 20,
                                  ),
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

              const SizedBox(height: 20),

              // Pins when scrolled: subcategories + search
              KeyedSubtree(
                key: _searchAnchorKey,
                child: _showStickySearch
                    ? const SizedBox(height: _stickyExtent)
                    : _buildStickySection(),
              ),

              const SizedBox(height: 14),

              // Horizontal filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('⚙️  Filter'),
                    _buildFilterChip('🍿  Under 200 MRU'),
                    _buildFilterChip('🏷️  Offers'),
                    _buildFilterChip('⭐  Rating'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. "Smart Bundles" Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Smart Bundles',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Smart Bundle Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Bundle',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Butter Cr... • Artisan Bre... • Citrus...',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF8C7D73),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '135 MRU',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF5E00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '1200 MRU',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFA59A94),
                                    fontSize: 9,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ADD',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 6. "All Items from This Store" Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'All Items from This Store',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2-Column Product Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return _buildProductCard(item);
                  },
                ),
              ),

              const SizedBox(height: 30),
                ],
              ),
            ),

            // Sticky subcategories + search overlay
            if (_showStickySearch)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 2,
                  color: const Color(0xFFFFF7F2),
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset, bottom: 8),
                    child: _buildStickySection(),
                  ),
                ),
              ),

            // Floating back button
            Positioned(
              top: topInset + 10,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
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
          ],
        ),
      ),
    );
  }

  // Filter Chip Helper Widget
  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: const Color(0xFF2C2520),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Product Card Helper Widget
  Widget _buildProductCard(Map<String, dynamic> item) {
    return Container(
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
          // Image Area with Discount Tag
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.asset(
                    item['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF3E7DC),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        size: 40,
                        color: Color(0xFFFF5E00),
                      ),
                    ),
                  ),
                ),
              ),

              // Discount Tag Top Left
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5E00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['discount'],
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFAE00),
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item['rating'],
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['reviews'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7D73),
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['originalPrice'],
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 9,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          item['price'],
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (Get.isRegistered<HomeController>()) {
                          Get.find<HomeController>().setCartItem(
                            storeName: widget.store['name']?.toString() ?? widget.store['title']?.toString() ?? 'Local Store',
                            itemName: (item['name'] ?? item['title'])?.toString(),
                            itemPortion: item['portion']?.toString() ?? '1 Portion',
                            basePrice: item['price'],
                            itemImage: item['image']?.toString(),
                          );
                        }
                        Get.to(
                          () => LocalStoreCartScreen(
                            store: widget.store,
                            product: item,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'ADD',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
}
