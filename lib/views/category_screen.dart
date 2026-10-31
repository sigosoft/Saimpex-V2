import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';
import '../controllers/select_location_controller.dart';
import '../core/network/api_exception.dart';
import '../models/food_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import '../widgets/store_map_button.dart';
import '../widgets/see_all_button.dart';
import 'widgets/search_camera_button.dart';
import '../widgets/filter_chip_style.dart';
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

  bool _foodCategoriesLoading = false;
  List<Map<String, dynamic>> subcategories = const [];

  bool _restaurantsLoading = false;
  List<Map<String, dynamic>> items = const [];
  List<Map<String, dynamic>> under30Restaurants = const [];
  List<Map<String, dynamic>> mapStores = const [];
  String trendingTitle = '';
  int? _activeCategoryId;

  /// Quick filters for the restaurant search (veg, offers, rating), keyed by API param.
  final Map<String, String> _searchFilters = {};

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse('$value') ?? fallback;
  }

  bool get _isFoodCategory {
    final name = widget.categoryName.trim().toLowerCase();
    return name == 'food' || name == 'trending' || name == 'all';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    if (_isFoodCategory) {
      subcategories = const [];
      _foodCategoriesLoading = true;
      _loadFoodCategories();
      _loadRestaurantHome();
    }
  }

  /// Search results and the home feed both render in this screen's list.
  Future<void> _loadRestaurantHome({
    int? categoryId,
    String keyword = '',
    Map<String, String> filters = const {},
  }) async {
    if (!Get.isRegistered<FoodRepository>()) return;
    if (!mounted) return;
    setState(() => _restaurantsLoading = true);

    // A keyword or quick filter goes through the search API; otherwise the home feed loads
    final searching = keyword.trim().isNotEmpty || filters.isNotEmpty;
    if (searching) {
      try {
        final found = await Get.find<FoodRepository>().searchRestaurants(
          latitude: SelectLocationController.selectedLatitude,
          longitude: SelectLocationController.selectedLongitude,
          language: apiLanguageCode(),
          keyword: keyword,
          filters: filters,
          categoryId: categoryId,
        );
        if (!mounted) return;
        setState(() {
          _restaurantsLoading = false;
          items = found.restaurants;
        });
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() => _restaurantsLoading = false);
        showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      }
      return;
    }

    try {
      final result = await Get.find<FoodRepository>().fetchRestaurantHomeV2(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
        categoryId: categoryId,
      );

      if (!mounted) return;
      setState(() {
        _restaurantsLoading = false;
        items = result.restaurants.isNotEmpty
            ? result.restaurants
            : result.trending;
        under30Restaurants = result.under30Minutes;
        mapStores = result.mapStores;
        if (result.trendingTitle.isNotEmpty) {
          trendingTitle = result.trendingTitle;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _restaurantsLoading = false);
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } catch (_) {
      if (!mounted) return;
      setState(() => _restaurantsLoading = false);
    }
  }

  Future<void> _loadFoodCategories() async {
    if (!Get.isRegistered<FoodRepository>()) {
      if (!mounted) return;
      setState(() {
        _foodCategoriesLoading = false;
        subcategories = const [];
      });
      return;
    }
    try {
      final categories = await Get.find<FoodRepository>().fetchVendorCategories(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _foodCategoriesLoading = false;
        subcategories = categories;
      });
      if (categories.isNotEmpty && Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().selectSubcategory(0);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _foodCategoriesLoading = false;
        subcategories = const [];
      });
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _categoryImage(String image) {
    if (!image.startsWith('http')) {
      return Container(
        width: 46,
        height: 46,
        color: const Color(0xFFEAD8C9),
        child: const Icon(Icons.fastfood, color: Colors.grey, size: 18),
      );
    }
    return Image.network(
      image,
      width: 46,
      height: 46,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: 46,
        height: 46,
        color: const Color(0xFFEAD8C9),
        child: const Icon(Icons.fastfood, color: Colors.grey, size: 18),
      ),
    );
  }

  /// Category names the app passes in English; translated only for display.
  String _titleLabel(String title) {
    switch (title.trim().toLowerCase()) {
      case 'food':
        return 'core_category_food'.tr;
      case 'all':
        return 'core_category_all'.tr;
      default:
        return title;
    }
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

  /// Filter chips. Chips with a param toggle that search filter in place.
  List<Map<String, dynamic>> get _filters => [
    {
      'label': 'Filter',
      'labelKey': 'core_category_filter',
      'icon': Image.asset("lib/assets/images/Filter.png"),
    },
    {
      'label': 'Veg',
      'labelKey': 'core_category_veg',
      'param': 'veg',
      'value': '1',
      'isVeg': true,
    },
    {
      'label': 'Offers',
      'labelKey': 'core_category_offers',
      'param': 'offers',
      'value': '1',
      'icon': Image.asset("lib/assets/images/Offer.png"),
    },
    {
      'label': 'Ratings 4.0+',
      'labelKey': 'core_category_ratings_4',
      'param': 'rating',
      'value': '4',
      'icon': Icons.star_rounded,
    },
  ];

  /// Reloads the list with the current keyword, category and quick filters.
  void _reloadRestaurants() {
    _loadRestaurantHome(
      categoryId: _activeCategoryId,
      keyword: _searchController.text,
      filters: Map<String, String>.from(_searchFilters),
    );
  }

  void _toggleSearchFilter(String param, String value) {
    setState(() {
      if (_searchFilters[param] == value) {
        _searchFilters.remove(param);
      } else {
        _searchFilters[param] = value;
      }
    });
    _reloadRestaurants();
  }

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
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _reloadRestaurants(),
                decoration: InputDecoration(
                  hintText: 'core_category_search_hint'.tr,
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            SearchCameraButton(
              controller: _searchController,
              child: Image.asset(
                "lib/assets/images/Camera.png",
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                "lib/assets/images/Voice.png",
                width: 16,
                height: 16,
                color: const Color(0xFFFF5E00),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    final filters = _filters;
    return AppFilterChipsRow(
      children: [
        for (final filter in filters)
          AppFilterChip(
            label: (filter['labelKey'] as String).tr,
            selected:
                filter['param'] != null &&
                _searchFilters[filter['param']] == filter['value'],
            onTap: () {
              if (filter['param'] == null) {
                _showFilterBottomSheet(context);
              } else {
                _toggleSearchFilter(
                  filter['param'] as String,
                  filter['value'] as String,
                );
              }
            },
            leading: filter['isVeg'] == true
                ? AppFilterChip.vegLeading()
                : filter['icon'] is IconData
                ? AppFilterChip.iconLeading(
                    filter['icon'] as IconData,
                    color: (filter['label'] as String).contains('Rating')
                        ? const Color(0xFFFFAE00)
                        : const Color(0xFF2C2520),
                  )
                : filter['icon'] is Widget
                ? AppFilterChip.widgetLeading(filter['icon'] as Widget)
                : null,
          ),
      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(onTap: () => Get.back()),
                  Text(
                    _titleLabel(displayTitle),
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
              child: _foodCategoriesLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF5E00),
                        ),
                      ),
                    )
                  : Obx(() {
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
                            onTap: () {
                              controller.selectSubcategory(index);
                              final sub = subcategories[index];
                              final catId = sub['isAll'] == true
                                  ? null
                                  : _asInt(sub['id']);
                              _activeCategoryId = catId;
                              _reloadRestaurants();
                            },
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: index == subcategories.length - 1 ? 0 : 10,
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
                                                    color: const Color(
                                                      0xFFFF5E00,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.10),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child: _categoryImage(
                                                    sub['image']?.toString() ??
                                                        '',
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
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    final displayTitle = widget.categoryName == 'Trending'
        ? 'Food'
        : widget.categoryName;
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
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
            Positioned.fill(
              child: SingleChildScrollView(
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
                    if (_restaurantsLoading &&
                        items.isEmpty &&
                        under30Restaurants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFFF5E00),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (!widget.showUnder30Minutes) ...[
                        const SizedBox(height: 12),
                        _buildTrendingSectionHeader(showSeeAll: false),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          _buildNoDataPlaceholder(
                            trendingTitle.isNotEmpty
                                ? trendingTitle
                                : displayTitle,
                          )
                        else
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                        if (items.isEmpty)
                          _buildNoDataPlaceholder(
                            trendingTitle.isNotEmpty
                                ? trendingTitle
                                : displayTitle,
                          )
                        else
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildTrendingRestaurantCard(
                                controller,
                                item,
                              ),
                            ),
                          ),
                      ],
                    ],
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
                trendingTitle.isNotEmpty
                    ? trendingTitle
                    : 'core_category_trending_in_city'.tr,
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
            SeeAllButton(onTap: onSeeAll)
          else
            StoreMapButton(
              // The home's map pins, else the restaurants listed here.
              onTap: () => Get.to(
                () => StoreMapScreen(
                  stores: mapStores.isNotEmpty ? mapStores : items,
                  onOpen: (store) =>
                      Get.to(() => RestaurantDetailsScreen(restaurant: store)),
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
    final isClosed = item['isClosed'] == true || item['isClosed'] == 'true';
    final isTemporarilyClosed =
        item['isTemporarilyClosed'] == true ||
        item['isTemporarilyClosed'] == 'true';
    final itemId = (item['id'] ?? '').toString();
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
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                    child: (item['image'] ?? '').toString().isNotEmpty
                        ? Image.network(
                            (item['image'] ?? '').toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFFF3EFEA),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                        : Container(
                            color: const Color(0xFFF3EFEA),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if ((item['discount'] ?? '').toString().trim().isNotEmpty)
                    PositionedDirectional(
                      top: 10,
                      start: 10,
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
                  PositionedDirectional(
                    top: 10,
                    start: (item['discount'] ?? '').toString().trim().isNotEmpty
                        ? 70
                        : 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
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
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: Obx(() {
                      final liked = controller.isLiked(itemId);
                      return GestureDetector(
                        onTap: () => controller.toggleLike(itemId, item),
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
                  PositionedDirectional(
                    bottom: 8,
                    start: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
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
                  ),
                  if (isClosed) ...[
                    Positioned.fill(
                      child: Container(color: Colors.black.withValues(alpha: 0.35)),
                    ),
                    Positioned.fill(
                      child: _buildClosedOverlay(
                        (item['opensAt'] ?? '10 AM').toString(),
                      ),
                    ),
                  ] else if (isTemporarilyClosed) ...[
                    Positioned.fill(
                      child: Container(color: Colors.black.withValues(alpha: 0.35)),
                    ),
                    Positioned.fill(child: _buildTemporarilyClosedOverlay()),
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
                        (item['title'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (item['subtitle'] ?? '').toString(),
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
                            (item['time'] ?? '').toString(),
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
                            (item['dist'] ?? '').toString(),
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

  Widget _buildNoDataPlaceholder(String title) {
    String message;
    final lower = title.toLowerCase();
    if (lower.contains('under 30')) {
      message = 'core_category_empty_under_30'.tr;
    } else if (lower.contains('trending')) {
      message = 'core_category_empty_trending'.tr;
    } else {
      message = 'core_category_empty_restaurants'.tr;
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/Nodata.png',
              width: 86,
              height: 86,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.outfit(
                color: const Color(0xFF7A6A60),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnder30MinSection(HomeController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'core_category_under_30'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (under30Restaurants.isNotEmpty)
                SeeAllButton(
                  onTap: () => Get.to(() => const Under30MinScreen()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (under30Restaurants.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: under30Restaurants.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return _buildUnder30MinCard(
                  controller,
                  under30Restaurants[index],
                );
              },
            ),
          )
        else
          _buildNoDataPlaceholder('Under 30 Minutes'),
      ],
    );
  }

  Widget _buildUnder30MinCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final isClosed = item['isClosed'] == true || item['isClosed'] == 'true';
    final isTemporarilyClosed =
        item['isTemporarilyClosed'] == true ||
        item['isTemporarilyClosed'] == 'true';
    return GestureDetector(
      onTap: () {
        Get.to(() => RestaurantDetailsScreen(restaurant: item));
      },
      child: Container(
        width: 190,
        margin: const EdgeInsetsDirectional.only(end: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                    child: (item['image'] ?? '').toString().isNotEmpty
                        ? Image.network(
                            (item['image'] ?? '').toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFFF3EFEA),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                        : Container(
                            color: const Color(0xFFF3EFEA),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  if ((item['discount'] ?? '').toString().trim().isNotEmpty)
                    PositionedDirectional(
                      top: 10,
                      start: 10,
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
                  PositionedDirectional(
                    top: 10,
                    end: 10,
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
                  PositionedDirectional(
                    bottom: 8,
                    start: 8,
                    end: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
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
                            color: Colors.black.withValues(alpha: 0.6),
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
                      child: Container(color: Colors.black.withValues(alpha: 0.35)),
                    ),
                    Positioned.fill(
                      child: _buildClosedOverlay(
                        (item['opensAt'] ?? '10 AM').toString(),
                      ),
                    ),
                  ] else if (isTemporarilyClosed) ...[
                    Positioned.fill(
                      child: Container(color: Colors.black.withValues(alpha: 0.35)),
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
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'core_category_closed'.tr,
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
                      'core_category_opens_at'.trParams({'time': opensAt}),
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
                  color: Colors.black.withValues(alpha: 0.15),
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
                      'core_category_temp_closed_line1'.tr,
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
                  'core_category_temp_closed_line2'.tr,
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
  const _FilterBottomSheetContent();

  @override
  State<_FilterBottomSheetContent> createState() =>
      _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  final List<String> selectedFoodTags = [];
  RangeValues priceRange = const RangeValues(65, 1500);
  String selectedSortBy = 'core_category_sort_relevance';

  final List<String> foodTags1 = [
    'core_category_tag_spicy',
    'core_category_tag_non_spicy',
    'core_category_tag_sugar_free',
    'core_category_tag_mild_sugar',
  ];
  final List<String> foodTags2 = [
    'core_category_offers',
    'core_category_tag_rating_45',
    'core_category_tag_rating_40',
    'core_category_tag_rating_35',
  ];
  final List<String> sortOptions = [
    'core_category_sort_relevance',
    'core_category_sort_delivery_time',
    'core_category_sort_cost_low_high',
    'core_category_sort_cost_high_low',
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
          label.tr,
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
            padding: const EdgeInsetsDirectional.only(end: 8),
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
            padding: const EdgeInsetsDirectional.only(end: 8),
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
                          'core_category_filters'.tr,
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
                              selectedSortBy = 'core_category_sort_relevance';
                            });
                          },
                          child: Text(
                            'core_category_clear_all'.tr,
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
                          'core_category_price_range'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'core_category_price_between'.trParams({
                            'min': '${priceRange.start.round()}',
                            'max': '${priceRange.end.round()}',
                          }),
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
                        overlayColor: Colors.transparent,
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
                          'mru'.trParams({'amount': '0'}),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'mru'.trParams({'amount': '3000'}),
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
                      'core_category_sort_by'.tr,
                      style: GoogleFonts.instrumentSans(
                        color: const Color(0xFF2C2520),
                        fontSize: 18,
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
                                selectedSortBy = 'core_category_sort_relevance';
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
                                  'core_category_clear_all'.tr,
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
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'core_category_apply'.tr,
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
                    color: Colors.black.withValues(alpha: 0.1),
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
