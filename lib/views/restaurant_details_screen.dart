import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../widgets/app_back_button.dart';
import '../widgets/filter_chip_style.dart';
import '../widgets/replace_cart_item_dialog.dart';
import 'widgets/food_item_sheets.dart';
import 'chat_screen.dart';
import 'cart_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantDetailsScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  int activeSubcategoryIndex = 0;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool showCartBar = false;
  bool _showStickySearch = false;
  Map<String, dynamic>? lastAddedFood;

  /// search(46) + gap(12) + filters(32) + bottom gap(12)
  static const double _searchFiltersExtent = 102;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    searchController.dispose();
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
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
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Find something from this restaurant',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                color: Color(0xFFFF5E00),
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return AppFilterChipsRow(
      children: [
        for (final filter in filters)
          AppFilterChip(
            label: filter['label'] as String,
            leading: filter['isVeg'] == true
                ? AppFilterChip.vegLeading()
                : filter['icon'] is IconData
                    ? AppFilterChip.iconLeading(
                        filter['icon'] as IconData,
                        color: (filter['label'] as String).contains('Rating')
                            ? const Color(0xFFFFAE00)
                            : const Color(0xFF2C2520),
                      )
                    : filter['asset'] is String
                        ? AppFilterChip.assetLeading(filter['asset'] as String)
                        : null,
          ),
      ],
    );
  }

  Widget _buildSearchFiltersSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildFiltersRow(),
        const SizedBox(height: 12),
      ],
    );
  }

  HomeController _homeController() {
    return Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);
  }

  String _currentRestaurantName() {
    return (widget.restaurant['title'] ??
            widget.restaurant['name'] ??
            'Restaurant')
        .toString()
        .trim();
  }

  String _normalizeRestaurantName(String name) {
    var normalized = name.trim().toLowerCase();
    if (normalized.endsWith(' restaurant')) {
      normalized = normalized.substring(0, normalized.length - 11).trim();
    }
    return normalized;
  }

  bool _isDifferentRestaurant(String existing, String incoming) {
    return _normalizeRestaurantName(existing) !=
        _normalizeRestaurantName(incoming);
  }

  Future<bool> _confirmReplaceCartIfNeeded(BuildContext context) async {
    final controller = _homeController();
    final newRestaurant = _currentRestaurantName();
    final existingStore =
        controller.lastCartItem?['storeName']?.toString().trim();

    if (controller.cartItemCount.value <= 0 ||
        existingStore == null ||
        existingStore.isEmpty ||
        !_isDifferentRestaurant(existingStore, newRestaurant)) {
      return true;
    }

    final replace = await ReplaceCartItemDialog.show(
      context: context,
      currentCartRestaurant: existingStore,
      newRestaurant: newRestaurant,
    );
    return replace == true;
  }

  Future<void> _addFoodToCart(
    BuildContext context,
    Map<String, dynamic> food, {
    bool fromBottomSheet = false,
  }) async {
    final canAdd = await _confirmReplaceCartIfNeeded(context);
    if (!canAdd || !context.mounted) return;

    Navigator.pop(context);
    if (fromBottomSheet && context.mounted) {
      Navigator.pop(context);
    }
    if (!mounted) return;

    final controller = _homeController();
    if (controller.cartItemCount.value > 0) {
      final existingStore =
          controller.lastCartItem?['storeName']?.toString().trim();
      if (existingStore != null &&
          _isDifferentRestaurant(existingStore, _currentRestaurantName())) {
        controller.clearCart();
      }
    }

    controller.setCartItem(
      storeName: _currentRestaurantName(),
      itemName: food['title']?.toString(),
      itemPortion: '1 Portion',
      basePrice: _parsePrice(food['price']?.toString()),
      itemImage: food['image']?.toString(),
    );

    setState(() {
      showCartBar = true;
      lastAddedFood = food;
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${food['title']} added to cart!',
          style: GoogleFonts.outfit(),
        ),
        backgroundColor: const Color(0xFFFF5E00),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _parsePrice(String? priceStr) {
    if (priceStr == null) return 750;
    final digits = priceStr.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 750;
  }

  final List<Map<String, dynamic>> subcategories = [
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

  final List<Map<String, dynamic>> filters = [
    {'label': 'Filter', 'asset': 'lib/assets/images/Filter.png'},
    {'label': 'Veg', 'isVeg': true},
    {'label': 'Offers', 'asset': 'lib/assets/images/Offer.png'},
    {'label': 'Ratings 4.0+', 'icon': Icons.star_rounded},
  ];

  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Chiken Pasta',
      'image':
          'https://quickhomemaderecipes.com/wp-content/uploads/2024/04/Cajun-Chicken-Pasta-Recipe-1.jpg',
      'isVeg': false,
      'tag': 'Spicy',
      'rating': '4.6',
      'reviews': '10k+ reviews',
      'price': '750 MRU',
      'originalPrice': '1,500 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Chiken Tagine',
      'image':
          'https://www.thechickenrecipes.co.uk/wp-content/uploads/2024/05/chicken-tagine-recipe-UK.jpg',
      'isVeg': false,
      'tag': 'Spicy',
      'rating': '4.6',
      'reviews': '10k+ reviews',
      'price': '750 MRU',
      'originalPrice': '1,500 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Milk Dessert',
      'image':
          'https://myminichefs.com/wp-content/uploads/2022/09/vanilla-almond-milk-pudding-image.jpg',
      'isVeg': true,
      'tag': 'Pure Dairy',
      'rating': '4.6',
      'reviews': '10k+ reviews',
      'price': '750 MRU',
      'originalPrice': '1,500 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Thieboudienne',
      'image':
          'https://img.cuisineaz.com/660x660/2016/07/17/i19848-thieboudienne.jpeg',
      'isVeg': false,
      'tag': 'Spicy',
      'rating': '4.6',
      'reviews': '10k+ reviews',
      'price': '750 MRU',
      'originalPrice': '1,500 MRU',
      'discount': '50% OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _homeController();
    final restaurantId = widget.restaurant['id']?.toString() ?? 'r1';
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              final hasItems = controller.cartItemCount.value > 0;
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: hasItems ? bottomInset + 88 : bottomInset + 24,
                ),
                child: Column(
                  children: [
                    // Collapses: banner + info + categories
                    Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: topInset + 132,
                          child: Image.network(
                            widget.restaurant['image'] ??
                                'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: const Color(0xFFF3EFEA),
                              child: const Icon(
                                Icons.restaurant_outlined,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: topInset + 56),

                            // Floating Info Card
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.restaurant['title'] ??
                                              'Restaurant',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00B25C),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              widget.restaurant['rating'] ??
                                                  '4.6',
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
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.restaurant['subtitle'] ??
                                        'Moroccan • Traditional',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF7A6A60),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        color: Color(0xFFFF5E00),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.restaurant['time'] ??
                                            '30-35 min',
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
                                        widget.restaurant['dist'] ?? '10 Km',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5E00),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          widget.restaurant['discount'] ??
                                              '50% OFF',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Get.to(
                                              () => ChatScreen(
                                                restaurant: widget.restaurant,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  const LinearGradient(
                                                colors: [
                                                  Color(0xFFFF5E00),
                                                  Color(0xFFFFAE00),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF5E00)
                                                      .withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  "lib/assets/images/Chat Details.png",
                                                  height: 18,
                                                  width: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Chat with Restaurant',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Obx(() {
                                        final liked = controller.isLiked(
                                          restaurantId,
                                        );
                                        return GestureDetector(
                                          onTap: () => controller.toggleLike(
                                            restaurantId,
                                            widget.restaurant,
                                          ),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFEAD8C9),
                                                width: 0.8,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              liked
                                                  ? Icons.favorite_rounded
                                                  : Icons
                                                      .favorite_border_rounded,
                                              color: const Color(0xFFFF5E00),
                                              size: 18,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Horizontal Category Row
                            Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                              padding: const EdgeInsets.only(top: 4),
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFFCF8),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(22)),
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
                                  itemCount: subcategories.length,
                                  physics: const BouncingScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 4, 14, 0),
                                  itemBuilder: (context, index) {
                                    final sub = subcategories[index];
                                    final isAll = sub['isAll'] == true;
                                    final isSelected =
                                        activeSubcategoryIndex == index;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          activeSubcategoryIndex = index;
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right:
                                              index == subcategories.length - 1
                                                  ? 0
                                                  : 10,
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
                                                          decoration:
                                                              const BoxDecoration(
                                                            shape: BoxShape
                                                                .circle,
                                                          ),
                                                          child: Center(
                                                            child: Image.asset(
                                                              'lib/assets/images/All.png',
                                                              width: 22,
                                                              height: 22,
                                                              color:
                                                                  const Color(
                                                                0xFFFF5E00,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            shape: BoxShape
                                                                .circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                  0.10,
                                                                ),
                                                                blurRadius: 10,
                                                                offset:
                                                                    const Offset(
                                                                  0,
                                                                  4,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: ClipOval(
                                                            child:
                                                                Image.network(
                                                              sub['image']
                                                                  as String,
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
                                                                color: Colors
                                                                    .grey
                                                                    .shade300,
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .fastfood,
                                                                  size: 18,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    sub['label'] as String,
                                                    textAlign:
                                                        TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    style: GoogleFonts.outfit(
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFFFF5E00)
                                                          : const Color(
                                                              0xFF3A312C),
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
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(0xFFFF5E00),
                                                          Color(0xFFFFAE00),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(12),
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
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Search + filters — pins when scrolled
                    KeyedSubtree(
                      key: _searchAnchorKey,
                      child: _showStickySearch
                          ? const SizedBox(height: _searchFiltersExtent)
                          : _buildSearchFiltersSection(),
                    ),

                    // Menu Title Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'All Items from This Restaurant',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Vertical Menu List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: menuItems.map((food) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildFoodCard(context, food),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
          ),

          // Sticky search + filters overlay
          if (_showStickySearch)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 2,
                color: const Color(0xFFFFFDF9),
                child: Padding(
                  padding: EdgeInsets.only(top: topInset, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFiltersRow(),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Back Button (hidden while sticky search is pinned)
          if (!_showStickySearch)
            Positioned(
              top: topInset + 10,
              left: 16,
              child: const AppBackButton(),
            ),

          // Floating Cart Summary Bar
          Positioned(
            bottom: bottomInset + 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final hasItems = controller.cartItemCount.value > 0;
              if (!hasItems) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  Get.to(
                    () => CartScreen(
                      isFoodOrGrocery: true,
                      storeName:
                          widget.restaurant['name']?.toString() ??
                          'Golden Bakery',
                      itemName:
                          lastAddedFood?['title']?.toString() ??
                          'Chicken Tagine',
                      itemPortion: '1 Portion',
                      basePrice: _parsePrice(
                        lastAddedFood?['price']?.toString(),
                      ),
                      itemImage: lastAddedFood?['image']?.toString(),
                    ),
                  );
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5E00),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          controller.cartItemCount.value.toString(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Cart • ${controller.cartItemCount.value} items',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ready in 15-20 min',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFFF5E00),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, Map<String, dynamic> food) {
    final isVeg = food['isVeg'] as bool;
    return GestureDetector(
      onTap: () => _showFoodDetailsBottomSheet(context, food),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Food Thumbnail with discount badge overlay sitting top-center half-inside and half-outside
            SizedBox(
              width: 104,
              height: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        food['image']!,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E00),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          food['discount']!,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Food Info details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            food['tag']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildVegIndicator(isVeg),
                      ],
                    ),
                    Text(
                      food['title']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          food['rating']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${food['reviews']})',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              food['price']!,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              food['originalPrice']!,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: const Color(0xFFA59A94),
                                decorationThickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            _showFoodDetailsBottomSheet(context, food);
                          },
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5E00,
                                  ).withOpacity(0.2),
                                  blurRadius: 6,
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
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ADD',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetailsBottomSheet(
    BuildContext context,
    Map<String, dynamic> food,
  ) {
    showFoodItemDetailSheet(
      context: context,
      food: food,
      onOpenCustomize: () {
        // Opens on top of detail — swipe down returns to detail
        return _showCustomizeBottomSheet(
          context,
          food,
          fromBottomSheet: true,
        );
      },
    );
  }

  Future<void> _showCustomizeBottomSheet(
    BuildContext context,
    Map<String, dynamic> food, {
    required bool fromBottomSheet,
  }) {
    return showFoodItemCustomizeSheet(
      context: context,
      food: food,
      onAddToCart: (sheetContext) => _addFoodToCart(
        sheetContext,
        food,
        fromBottomSheet: fromBottomSheet,
      ),
    );
  }

  Widget _buildVegIndicator(bool isVeg) {
    final color = isVeg ? const Color(0xFF00B25C) : const Color(0xFFFF3E3E);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
