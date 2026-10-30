import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/select_location_controller.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_store.dart';
import '../models/cart_repository.dart';
import '../models/food_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import '../widgets/filter_chip_style.dart';
import '../widgets/replace_cart_item_dialog.dart';
import 'widgets/auto_slide_network_images.dart';
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

  Map<String, dynamic>? _restaurantDetails;
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoadingItems = false;
  String _searchQuery = "";
  bool _vegOnly = false;
  bool _offersOnly = false;
  bool _ratingFourPlus = false;

  // Search and filters run on the server, so the list shows what came back
  List<Map<String, dynamic>> get _visibleItems => _menuItems;

  bool get _isSearching =>
      _searchQuery.trim().isNotEmpty ||
      _vegOnly ||
      _offersOnly ||
      _ratingFourPlus;

  Timer? _searchDebounce;

  int _itemsRequestId = 0;

  /// search(46) + gap(12) + filters(32) + bottom gap(12)
  static const double _searchFiltersExtent = 102;

  FoodRepository _getFoodRepo() {
    if (Get.isRegistered<FoodRepository>()) {
      return Get.find<FoodRepository>();
    }
    final session = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>()
        : SessionStore();
    final dio = Get.isRegistered<DioClient>()
        ? Get.find<DioClient>()
        : Get.put(DioClient(session), permanent: true);
    return Get.put(FoodRepository(dio), permanent: true);
  }

  Map<String, dynamic> get _restaurantData =>
      _restaurantDetails ?? widget.restaurant;

  int get _parsedRestaurantId {
    final rawId =
        _restaurantDetails?['restaurant_id'] ??
        _restaurantDetails?['id'] ??
        widget.restaurant['restaurant_id'] ??
        widget.restaurant['id'] ??
        widget.restaurant['vendor_id'] ??
        (widget.restaurant['raw'] is Map
            ? (widget.restaurant['raw']['restaurant_id'] ??
                  widget.restaurant['raw']['id'] ??
                  widget.restaurant['raw']['vendor_id'])
            : null);
    return int.tryParse('$rawId') ?? 0;
  }

  String get _restaurantName {
    final name =
        _restaurantDetails?['name'] ??
        _restaurantDetails?['title'] ??
        widget.restaurant['title'] ??
        widget.restaurant['name'];
    return (name != null && name.toString().trim().isNotEmpty)
        ? name.toString().trim()
        : '';
  }

  String get _restaurantRating {
    final r = _restaurantDetails?['rating'] ?? widget.restaurant['rating'];
    return (r != null && r.toString().trim().isNotEmpty)
        ? r.toString().trim()
        : '';
  }

  String get _restaurantSubtitle {
    final s =
        _restaurantDetails?['subtitle'] ??
        _restaurantDetails?['address'] ??
        widget.restaurant['subtitle'] ??
        widget.restaurant['address'];
    return (s != null && s.toString().trim().isNotEmpty)
        ? s.toString().trim()
        : '';
  }

  String get _restaurantTime {
    final t = _restaurantDetails?['time'] ?? widget.restaurant['time'];
    return (t != null && t.toString().trim().isNotEmpty)
        ? t.toString().trim()
        : '';
  }

  String get _restaurantDistance {
    final d = _restaurantDetails?['dist'] ?? widget.restaurant['dist'];
    return (d != null && d.toString().trim().isNotEmpty)
        ? d.toString().trim()
        : '';
  }

  String get _restaurantDiscount {
    final d = _restaurantDetails?['discount'] ?? widget.restaurant['discount'];
    return (d != null && d.toString().trim().isNotEmpty)
        ? d.toString().trim()
        : '';
  }

  String? get _restaurantImage {
    final img = _restaurantDetails?['image'] ?? widget.restaurant['image'];
    if (img != null && img.toString().trim().isNotEmpty) {
      return img.toString().trim();
    }
    return null;
  }

  Future<void> _loadRestaurantDetails() async {
    final restaurantId = _parsedRestaurantId;
    if (restaurantId <= 0) return;

    try {
      final repo = _getFoodRepo();
      final lang = currentApiLanguage();
      final lat = SelectLocationController.selectedLatitude;
      final lng = SelectLocationController.selectedLongitude;

      final details = await repo.fetchRestaurantDetails(
        restaurantId: restaurantId,
        latitude: lat,
        longitude: lng,
        language: lang,
      );

      if (!mounted) return;
      setState(() {
        _restaurantDetails = details;
      });
    } catch (_) {}
  }

  Future<void> _loadSubcategories() async {
    try {
      // Only the categories this restaurant sells
      final categories = await _getFoodRepo().fetchRestaurantCategories(
        restaurantId: _parsedRestaurantId,
        language: currentApiLanguage(),
      );
      if (!mounted || categories.isEmpty) return;
      setState(() {
        subcategories = [
          if (!categories.any((c) => c['isAll'] == true))
            {'label': 'All', 'isAll': true, 'id': 0, 'category_ids': <int>[]},
          ...categories,
        ];
      });
      // Categories arrive after the first render, so "All" loads once they exist
      if (activeSubcategoryIndex == 0) {
        _loadRestaurantItems(_categoryIdsFor(subcategories[0]));
      }
    } catch (_) {}
  }

  /// Real category ids for a chip; "All" expands to every category's ids.
  List<int> _categoryIdsFor(Map<String, dynamic> sub) {
    if (sub['isAll'] != true) {
      final ids = sub['category_ids'];
      if (ids is List && ids.isNotEmpty) {
        return ids
            .map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      final id = int.tryParse('${sub['id']}') ?? 0;
      return id > 0 ? [id] : [];
    }
    final all = <int>{};
    for (final other in subcategories) {
      if (other['isAll'] != true) all.addAll(_categoryIdsFor(other));
    }
    return all.toList();
  }

  Future<void> _loadRestaurantItems(List<int> categoryIds) async {
    final restaurantId = _parsedRestaurantId;
    if (restaurantId <= 0) return;

    // Latest request wins, so a slow earlier category response can't overwrite the current one
    final requestId = ++_itemsRequestId;
    setState(() {
      _isLoadingItems = true;
      _menuItems = [];
    });
    try {
      final repo = _getFoodRepo();
      final lang = currentApiLanguage();

      final List<List<Map<String, dynamic>>> results;
      if (_isSearching) {
        // Search and filters: one server search per category, or across the menu for "All"
        final isAll =
            subcategories.isNotEmpty &&
            subcategories[activeSubcategoryIndex]['isAll'] == true;
        final scopes = isAll ? <int?>[null] : categoryIds.map<int?>((id) => id);
        results = await Future.wait(
          scopes.map(
            (id) => repo
                .searchRestaurantItems(
                  restaurantId: restaurantId,
                  categoryId: id,
                  keyword: _searchQuery,
                  veg: _vegOnly ? '1' : '',
                  offers: _offersOnly ? '1' : '',
                  rating: _ratingFourPlus ? '4' : '',
                  language: lang,
                )
                .catchError((_) => <Map<String, dynamic>>[]),
          ),
        );
      } else {
        // One request per category; a failing category shouldn't hide the rest
        results = await Future.wait(
          categoryIds.map(
            (id) => repo
                .fetchRestaurantItems(
                  restaurantId: restaurantId,
                  categoryId: id,
                  language: lang,
                )
                .catchError((_) => <Map<String, dynamic>>[]),
          ),
        );
      }

      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final list in results) {
        for (final item in list) {
          if (seen.add('${item['id']}')) merged.add(item);
        }
      }

      if (!mounted || requestId != _itemsRequestId) return;
      setState(() {
        _menuItems = merged;
        _isLoadingItems = false;
      });
    } catch (_) {
      if (!mounted || requestId != _itemsRequestId) return;
      setState(() => _isLoadingItems = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadRestaurantDetails();
    _loadSubcategories();
    _refreshCartTotals();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
                onChanged: _onSearchChanged,
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

  bool _isFilterOn(String label) => switch (label) {
    'Veg' => _vegOnly,
    'Offers' => _offersOnly,
    'Ratings 4.0+' => _ratingFourPlus,
    _ => false,
  };

  String _chipLabel(String label) => _isFilterOn(label) ? '✓ $label' : label;

  void _toggleFilter(String label) {
    setState(() {
      switch (label) {
        case 'Veg':
          _vegOnly = !_vegOnly;
        case 'Offers':
          _offersOnly = !_offersOnly;
        case 'Ratings 4.0+':
          _ratingFourPlus = !_ratingFourPlus;
      }
    });
    _reloadActiveItems();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      _reloadActiveItems,
    );
  }

  /// Reloads the items for the selected category, with the current search and filters.
  void _reloadActiveItems() {
    if (activeSubcategoryIndex >= subcategories.length) return;
    _loadRestaurantItems(
      _categoryIdsFor(subcategories[activeSubcategoryIndex]),
    );
  }

  /// Adds the item's portions and add-on groups, which the sheet needs.
  Future<Map<String, dynamic>> _withMenuVariants(
    Map<String, dynamic> food,
  ) async {
    final raw = food['raw'] is Map
        ? Map<String, dynamic>.from(food['raw'] as Map)
        : <String, dynamic>{};
    final menuId = int.tryParse('${raw['menu_id'] ?? ''}') ?? 0;
    final restaurantId = _parsedRestaurantId;
    if (menuId < 1 || restaurantId < 1) return food;
    try {
      final menu = await _getFoodRepo().fetchRestaurantMenuVariants(
        menuId: menuId,
        restaurantId: restaurantId,
      );
      if (menu.variants.isEmpty &&
          menu.optionGroups.isEmpty &&
          menu.extras.isEmpty) {
        return food;
      }
      return {
        ...food,
        'raw': {
          ...raw,
          'items': menu.variants,
          'option_groups': menu.optionGroups,
          'extras': menu.extras,
        },
      };
    } catch (_) {
      return food;
    }
  }

  Widget _buildFiltersRow() {
    return AppFilterChipsRow(
      children: [
        for (final filter in filters)
          AppFilterChip(
            label: _chipLabel(filter['label'] as String),
            onTap: () => _toggleFilter(filter['label'] as String),
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
    if (_restaurantName.isNotEmpty) {
      return _restaurantName;
    }
    return (widget.restaurant['title'] ?? widget.restaurant['name'] ?? '')
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

    // Ask the server which store holds items; the local memory is empty after a restart.
    String existingStore = '';
    try {
      final totals = await Get.find<CartRepository>().fetchCartTotals(
        apiLanguageCode(),
      );
      existingStore = totals.cartName.trim();
    } catch (_) {
      existingStore = controller.lastCartItem?['storeName']?.toString() ?? '';
    }

    if (existingStore.isEmpty ||
        !_isDifferentRestaurant(existingStore, newRestaurant)) {
      return true;
    }

    final replace = await ReplaceCartItemDialog.show(
      context: context,
      currentCartRestaurant: existingStore,
      newRestaurant: newRestaurant,
    );
    if (replace == true && Get.isRegistered<CartRepository>()) {
      try {
        final repo = Get.find<CartRepository>();
        final message = await repo.replaceCart(apiLanguageCode());
        // The replace call doesn't clear restaurant lines, so the previous
        // restaurant's items would stay in the cart without this.
        await repo.clearCatalogCart(language: apiLanguageCode());
        final text = message.trim();
        if (text.isNotEmpty) {
          showAppToast(text, backgroundColor: const Color(0xFFFF5E00));
        }
      } on ApiException catch (error) {
        showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
        return false;
      }
      controller.clearCart();
    }
    return replace == true;
  }

  /// Sets the cart bar's count and amount from the server's restaurant cart.
  /// If the cart can't be read, the locally tracked values stay as they are.
  Future<void> _refreshCartTotals() async {
    if (!Get.isRegistered<CartRepository>() ||
        !Get.isRegistered<HomeController>()) {
      return;
    }
    try {
      final totals = await Get.find<CartRepository>().fetchCartTotals(
        apiLanguageCode(),
      );
      if (!mounted) return;
      final controller = _homeController();
      controller.cartItemCount.value = totals.count;
      controller.cartAmount.value = totals.amount;
    } catch (_) {}
  }

  Future<void> _addFoodToCart(
    BuildContext context,
    Map<String, dynamic> food, {
    bool fromBottomSheet = false,
    String portion = 'Full portion',
    int? price,
    int quantity = 1,
    int? variantId,
    List<int> optionIds = const [],
    List<int> extraIds = const [],
  }) async {
    final canAdd = await _confirmReplaceCartIfNeeded(context);
    if (!canAdd || !context.mounted) return;

    final restaurantId = _parsedRestaurantId;
    if (variantId == null || variantId < 1 || restaurantId < 1) {
      showAppToast('Unable to add this item');
      return;
    }
    try {
      final message = await Get.find<CartRepository>().addCatalogItem(
        restaurantId: restaurantId,
        variantId: variantId,
        optionIds: optionIds,
        extraIds: extraIds,
        quantity: quantity,
        language: apiLanguageCode(),
      );
      if (message.trim().isNotEmpty) {
        showAppToast(message.trim(), backgroundColor: const Color(0xFFFF5E00));
      }
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return;
    }

    if (!context.mounted) return;
    Navigator.pop(context);
    if (fromBottomSheet && context.mounted) {
      Navigator.pop(context);
    }
    if (!mounted) return;

    final controller = _homeController();
    if (controller.cartItemCount.value > 0) {
      final existingStore = controller.lastCartItem?['storeName']
          ?.toString()
          .trim();
      if (existingStore != null &&
          _isDifferentRestaurant(existingStore, _currentRestaurantName())) {
        controller.clearCart();
      }
    }

    final unitPrice = price ?? _parsePrice(food['price']?.toString());
    controller.setCartItem(
      storeName: _currentRestaurantName(),
      itemName: food['title']?.toString(),
      itemPortion: portion,
      basePrice: unitPrice,
      itemImage: food['image']?.toString(),
      quantity: quantity,
    );
    // Shows the added amount at once; the server total replaces it below.
    controller.cartAmount.value += (unitPrice * quantity).toDouble();
    _refreshCartTotals();

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
    if (priceStr == null) return 0;
    final digits = priceStr.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// "All" is always present; API categories are appended once loaded.
  List<Map<String, dynamic>> subcategories = [
    {'label': 'All', 'isAll': true, 'id': 0},
  ];

  final List<Map<String, dynamic>> filters = [
    {'label': 'Filter', 'asset': 'lib/assets/images/Filter.png'},
    {'label': 'Veg', 'isVeg': true},
    {'label': 'Offers', 'asset': 'lib/assets/images/Offer.png'},
    {'label': 'Ratings 4.0+', 'icon': Icons.star_rounded},
  ];

  Widget _buildNoDataPlaceholder() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
              'No items available',
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

  @override
  Widget build(BuildContext context) {
    final controller = _homeController();
    final restaurantId =
        _restaurantData['id']?.toString() ??
        widget.restaurant['id']?.toString() ??
        'r1';
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
                          child:
                              (_restaurantImage != null &&
                                  _restaurantImage!.isNotEmpty)
                              ? Image.network(
                                  _restaurantImage!,
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
                                )
                              : Container(
                                  color: const Color(0xFFF3EFEA),
                                  child: const Icon(
                                    Icons.restaurant_outlined,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: topInset + 56),

                            // Floating Info Card
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                          _restaurantName.isNotEmpty
                                              ? _restaurantName
                                              : (widget.restaurant['title'] ??
                                                    widget.restaurant['name'] ??
                                                    ''),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (_restaurantRating.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00B25C),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                                _restaurantRating,
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
                                  if (_restaurantSubtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _restaurantSubtitle,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF7A6A60),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (_restaurantTime.isNotEmpty ||
                                      _restaurantDistance.isNotEmpty ||
                                      _restaurantDiscount.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (_restaurantTime.isNotEmpty) ...[
                                          const Icon(
                                            Icons.access_time_rounded,
                                            color: Color(0xFFFF5E00),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _restaurantTime,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF7A6A60),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        if (_restaurantTime.isNotEmpty &&
                                            _restaurantDistance.isNotEmpty)
                                          const SizedBox(width: 14),
                                        if (_restaurantDistance.isNotEmpty) ...[
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: Color(0xFFFF5E00),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _restaurantDistance,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF7A6A60),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        if ((_restaurantTime.isNotEmpty ||
                                                _restaurantDistance
                                                    .isNotEmpty) &&
                                            _restaurantDiscount.isNotEmpty)
                                          const SizedBox(width: 14),
                                        if (_restaurantDiscount.isNotEmpty)
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
                                              _restaurantDiscount,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Get.to(
                                              () => ChatScreen(
                                                restaurant: _restaurantData,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
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
                                                  color: const Color(
                                                    0xFFFF5E00,
                                                  ).withOpacity(0.3),
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
                                            _restaurantData,
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
                                borderRadius: BorderRadius.all(
                                  Radius.circular(22),
                                ),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    4,
                                    14,
                                    0,
                                  ),
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
                                        _loadRestaurantItems(
                                          _categoryIdsFor(sub),
                                        );
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
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
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
                                                            child: Image.network(
                                                              (sub['image'] ??
                                                                      '')
                                                                  .toString(),
                                                              width: 46,
                                                              height: 46,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) => Container(
                                                                    width: 46,
                                                                    height: 46,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade300,
                                                                    child: const Icon(
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
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    style: GoogleFonts.outfit(
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFFFF5E00,
                                                            )
                                                          : const Color(
                                                              0xFF3A312C,
                                                            ),
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
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  12,
                                                                ),
                                                            topRight:
                                                                Radius.circular(
                                                                  12,
                                                                ),
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
                      child: _isLoadingItems && _menuItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF5E00),
                                ),
                              ),
                            )
                          : _visibleItems.isEmpty
                          ? _buildNoDataPlaceholder()
                          : Column(
                              children: _visibleItems.map((food) {
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
                      storeName: _restaurantName.isNotEmpty
                          ? _restaurantName
                          : (widget.restaurant['name']?.toString() ??
                                widget.restaurant['title']?.toString() ??
                                ''),
                      itemName:
                          controller.lastCartItem?['itemName']?.toString() ??
                          lastAddedFood?['title']?.toString() ??
                          'Chicken Tagine',
                      itemPortion:
                          controller.lastCartItem?['itemPortion']?.toString() ??
                          'Full portion',
                      basePrice: () {
                        final saved = controller.lastCartItem?['basePrice'];
                        if (saved is num) return saved.toInt();
                        return _parsePrice(lastAddedFood?['price']?.toString());
                      }(),
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
                      Text(
                        '${_cartAmountText(controller.cartAmount.value)} MRU',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
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

  /// Whole amounts show without decimals; others show two.
  String _cartAmountText(double value) {
    return value == value.roundToDouble()
        ? '${value.toInt()}'
        : value.toStringAsFixed(2);
  }

  Widget _buildFoodCard(BuildContext context, Map<String, dynamic> food) {
    final isVeg =
        food['isVeg'] == true ||
        food['is_veg'] == 1 ||
        food['is_veg'] == true ||
        food['is_veg'] == '1' ||
        food['veg'] == 1 ||
        food['veg'] == true;
    final discount = (food['discount'] ?? '').toString().trim();
    final tag = (food['tag'] ?? '').toString().trim();
    final title = (food['title'] ?? food['name'] ?? '').toString().trim();
    final rating = (food['rating'] ?? '').toString().trim();
    final reviews = (food['reviews'] ?? '').toString().trim();
    final price = (food['price'] ?? '').toString().trim();
    final originalPrice = (food['originalPrice'] ?? '').toString().trim();

    return GestureDetector(
      onTap: () =>
          _showCustomizeBottomSheet(context, food, fromBottomSheet: false),
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
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: AutoSlideNetworkImages(
                          images: foodGalleryImages(food),
                        ),
                      ),
                    ),
                  ),
                  if (discount.isNotEmpty)
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
                            discount,
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
                        if (tag.isNotEmpty)
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
                              tag,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        _buildVegIndicator(isVeg),
                      ],
                    ),
                    Text(
                      title.isNotEmpty ? title : 'Item',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (rating.isNotEmpty || reviews.isNotEmpty)
                      Row(
                        children: [
                          if (rating.isNotEmpty) ...[
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFAE00),
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (reviews.isNotEmpty)
                            Text(
                              rating.isNotEmpty ? ' ($reviews)' : reviews,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 9,
                              ),
                            ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (price.isNotEmpty)
                              Text(
                                price,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (originalPrice.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                originalPrice,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFA59A94),
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: const Color(0xFFA59A94),
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                        GestureDetector(
                          // ADD goes straight to the customize sheet; card tap still opens details
                          onTap: () {
                            if (food['inStock'] == false) {
                              showAppToast('This item is out of stock');
                              return;
                            }
                            _showCustomizeBottomSheet(
                              context,
                              food,
                              fromBottomSheet: false,
                            );
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
                                  food['inStock'] == false ? 'SOLD OUT' : 'ADD',
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

  Future<void> _showCustomizeBottomSheet(
    BuildContext context,
    Map<String, dynamic> food, {
    required bool fromBottomSheet,
  }) async {
    final detailed = await _withMenuVariants(food);
    if (!mounted) return;
    return showFoodItemCustomizeSheet(
      context: context,
      food: detailed,
      onAddToCart:
          (
            sheetContext, {
            required variantId,
            required optionIds,
            required extraIds,
            required portion,
            required price,
            required quantity,
          }) => _addFoodToCart(
            sheetContext,
            food,
            fromBottomSheet: fromBottomSheet,
            variantId: variantId,
            optionIds: optionIds,
            extraIds: extraIds,
            portion: portion,
            price: price,
            quantity: quantity,
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
