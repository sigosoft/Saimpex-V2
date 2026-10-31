import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/session_store.dart';
import '../../models/cart_repository.dart';
import '../../models/grocery_repository.dart';
import '../../widgets/replace_cart_item_dialog.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/filter_chip_style.dart';
import '../messages_screen.dart';
import '../cart_screen.dart';
import '../../widgets/app_back_button.dart';
import '../widgets/auto_slide_network_images.dart';

class GroceryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const GroceryDetailsScreen({super.key, required this.store});

  @override
  State<GroceryDetailsScreen> createState() => _GroceryDetailsScreenState();
}

class _GroceryDetailsScreenState extends State<GroceryDetailsScreen> {
  int activeSubcategoryIndex = 0;
  List<Map<String, dynamic>> _subcategories = [];
  int? _activeSubCategoryId;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool showCartBar = false;
  bool _showStickySearch = false;
  Map<String, dynamic>? lastAddedItem;
  String? lastAddedItemPortion;

  bool _isLoading = true;
  bool _isLoadingItems = true;
  Map<String, dynamic>? _storeDetails;

  /// search(42) + gap(12) + filters(32) + bottom gap(12)
  static const double _searchFiltersExtent = 98;

  GroceryRepository _getGroceryRepo() {
    // Local stores reuse this screen against the local store API.
    if (widget.store['isLocalStore'] == true &&
        Get.isRegistered<GroceryRepository>(
          tag: GroceryRepository.localStoreTag,
        )) {
      return Get.find<GroceryRepository>(tag: GroceryRepository.localStoreTag);
    }
    if (Get.isRegistered<GroceryRepository>()) {
      return Get.find<GroceryRepository>();
    }
    final session = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>()
        : SessionStore();
    final dio = Get.isRegistered<DioClient>()
        ? Get.find<DioClient>()
        : Get.put(DioClient(session), permanent: true);
    return Get.put(GroceryRepository(dio), permanent: true);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadTagOptions();
    await _loadGroceryDetails();
    await _loadGroceryItems();
    _refreshCartCount();
  }

  /// If the cart holds items from another store, asks before replacing them.
  /// On yes, the server cart is cleared and the local cart bar is reset.
  Future<bool> _confirmReplaceCartIfNeeded(BuildContext context) async {
    final controller = Get.find<HomeController>();
    final storeName =
        (_storeDetails?['name'] ?? widget.store['name'] ?? 'Grocery Store')
            .toString()
            .trim();

    // Ask the server which restaurant holds items; the local count can be stale.
    String existingStore = '';
    try {
      final totals = await Get.find<CartRepository>().fetchCartTotals(
        currentApiLanguage(),
      );
      existingStore = totals.cartName.trim();
    } catch (_) {
      existingStore = controller.lastCartItem?['storeName']?.toString() ?? '';
    }

    if (existingStore.isEmpty ||
        existingStore.toLowerCase() == storeName.toLowerCase()) {
      return true;
    }

    if (!context.mounted) return false;
    final replace = await ReplaceCartItemDialog.show(
      context: context,
      currentCartRestaurant: existingStore,
      newRestaurant: storeName,
    );
    if (replace != true) return false;

    try {
      final repo = Get.find<CartRepository>();
      await repo.replaceCart(currentApiLanguage());
      // The replace call doesn't clear restaurant lines, so remove them here.
      await repo.clearCatalogCart(language: currentApiLanguage());
    } on ApiException catch (error) {
      ToastHelper.showError(error.message);
      return false;
    }
    controller.clearCart();
    return true;
  }

  /// Sets the cart bar count to the server cart's total quantity.
  Future<void> _refreshCartCount() async {
    if (!Get.isRegistered<HomeController>() ||
        !Get.isRegistered<CartRepository>()) {
      return;
    }
    try {
      final totals = await Get.find<CartRepository>().fetchCartTotals(
        currentApiLanguage(),
      );
      final home = Get.find<HomeController>();
      home.cartItemCount.value = totals.count;
      home.cartAmount.value = totals.amount;
    } catch (_) {}
  }

  /// "350" for whole amounts, otherwise two decimals.
  String _cartAmountText(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  Future<void> _loadGroceryDetails() async {
    setState(() => _isLoading = true);
    try {
      final repo = _getGroceryRepo();
      final lang = currentApiLanguage();
      final lat = SelectLocationController.selectedLatitude;
      final lng = SelectLocationController.selectedLongitude;
      final groceryId = _groceryId();

      final details = await repo.fetchGroceryDetails(
        groceryId: groceryId,
        latitude: lat,
        longitude: lng,
        language: lang,
      );
      // The details payload has no image; keep the one from the store card.
      if ((details['image'] ?? '').toString().isEmpty) {
        details['image'] = widget.store['image'] ?? '';
      }
      final categories = await _loadStoreCategories(repo, groceryId, lang);

      if (!mounted) return;
      setState(() {
        _storeDetails = details;
        subcategories = [
          {'id': 0, 'label': 'All', 'isAll': true},
          ...categories,
        ];
        activeSubcategoryIndex = 0;
        _subcategories = [];
        _activeSubCategoryId = null;
        smartBundle = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        subcategories = [];
        _subcategories = [];
        _activeSubCategoryId = null;
        smartBundle = null;
        _isLoading = false;
      });
      if (e is ApiException) {
        ToastHelper.showError(e.message);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadStoreCategories(
    GroceryRepository repo,
    int groceryId,
    String language,
  ) async {
    try {
      return await repo.fetchGroceryStoreCategories(
        groceryId: groceryId,
        language: language,
      );
    } catch (_) {
      return const [];
    }
  }

  int _groceryId() {
    final raw =
        widget.store['grocery_id'] ??
        widget.store['id'] ??
        _storeDetails?['grocery_id'] ??
        widget.store['vendor_id'];
    return int.tryParse('$raw') ?? 0;
  }

  /// Category picked in the top row; null for "All".
  int? _selectedCategoryId() {
    if (activeSubcategoryIndex < 0 ||
        activeSubcategoryIndex >= subcategories.length) {
      return null;
    }
    final selected = subcategories[activeSubcategoryIndex];
    if (selected['isAll'] == true) return null;
    final id = int.tryParse('${selected['id']}') ?? 0;
    return id > 0 ? id : null;
  }

  /// Picks a top-row category, loads its subcategories, then its items.
  Future<void> _selectCategory(int index) async {
    if (activeSubcategoryIndex == index) return;
    setState(() {
      activeSubcategoryIndex = index;
      _subcategories = [];
      _activeSubCategoryId = null;
    });

    final categoryId = _selectedCategoryId();
    if (categoryId != null) {
      try {
        final subs = await _getGroceryRepo().fetchGrocerySubCategories(
          groceryId: _groceryId(),
          categoryId: categoryId,
          language: currentApiLanguage(),
        );
        if (mounted) setState(() => _subcategories = subs);
      } catch (_) {}
    }
    await _loadGroceryItems();
  }

  void _selectSubCategory(int? subCategoryId) {
    if (_activeSubCategoryId == subCategoryId) return;
    setState(() => _activeSubCategoryId = subCategoryId);
    _loadGroceryItems();
  }

  /// Items for the selected category, subcategory and search text.
  Future<void> _loadGroceryItems() async {
    if (!mounted) return;
    setState(() => _isLoadingItems = true);
    try {
      final items = await _getGroceryRepo().fetchGroceryItems(
        groceryId: _groceryId(),
        categoryId: _selectedCategoryId(),
        subCategoryId: _activeSubCategoryId,
        keyword: searchController.text,
        limit: 20,
        sortBy: _itemFilters.sortBy,
        priceRange: _itemFilters.priceRange,
        rating: _itemFilters.rating,
        tagIds: _itemFilters.tagIds.toList(),
        language: currentApiLanguage(),
      );

      if (!mounted) return;
      setState(() {
        menuItems = _applyLocalFilters(items);
        _isLoadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        menuItems = [];
        _isLoadingItems = false;
      });
      if (e is ApiException) {
        ToastHelper.showError(e.message);
      }
    }
  }

  Widget _buildSubcategoryChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _subcategories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sub = index == 0 ? null : _subcategories[index - 1];
          final subId = sub == null
              ? null
              : int.tryParse('${sub['sub_category_id'] ?? sub['id']}');
          final selected = _activeSubCategoryId == subId;
          final label = sub == null
              ? 'st_all'.tr
              : (sub['label'] ?? '').toString();

          return GestureDetector(
            onTap: () => _selectSubCategory(subId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF5E00) : Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFEAD8C9),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: selected ? Colors.white : const Color(0xFF2C2520),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoDataPlaceholder(String title) {
    String message;
    final lower = title.toLowerCase();
    if (lower.contains('item') || lower.contains('product')) {
      message = 'st_no_store_items'.tr;
    } else if (lower.contains('bundle')) {
      message = 'st_no_smart_bundles'.tr;
    } else if (lower.contains('categor')) {
      message = 'st_no_categories'.tr;
    } else {
      message = 'st_no_data'.tr;
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

  Widget _buildSearchFiltersSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildFiltersRow(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 42,
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
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadGroceryItems(),
                decoration: InputDecoration(
                  hintText: 'st_find_in_store'.tr,
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

  Widget _buildFiltersRow() {
    final filters = _itemFilters;
    return AppFilterChipsRow(
      children: [
        AppFilterChip(
          label: 'st_filter'.tr,
          onTap: () => _showFilterBottomSheet(),
          leading: AppFilterChip.widgetLeading(
            Image.asset("lib/assets/images/Filter.png"),
          ),
        ),
        AppFilterChip(
          label: 'st_under_200'.tr,
          selected: filters.priceRange == 'under_200',
          onTap: () => _changeFilters(
            filters.priceRange == 'under_200'
                ? filters.copyWith(clearPriceRange: true)
                : filters.copyWith(priceRange: 'under_200'),
          ),
          leading: AppFilterChip.mruLeading(),
        ),
        AppFilterChip(
          label: 'st_offers'.tr,
          selected: filters.offersOnly,
          onTap: () =>
              _changeFilters(filters.copyWith(offersOnly: !filters.offersOnly)),
          leading: AppFilterChip.widgetLeading(
            Image.asset("lib/assets/images/Offer.png"),
          ),
        ),
        AppFilterChip(
          label: 'st_rating'.tr,
          selected: filters.rating == 4.0,
          onTap: () => _changeFilters(
            filters.rating == 4.0
                ? filters.copyWith(clearRating: true)
                : filters.copyWith(rating: 4.0),
          ),
          leading: AppFilterChip.iconLeading(
            Icons.star_rounded,
            color: const Color(0xFFFFAE00),
          ),
        ),
      ],
    );
  }

  /// Stores the new filters and reloads the items with them.
  void _changeFilters(GroceryItemFilters next) {
    setState(() => _itemFilters = next);
    _loadGroceryItems();
  }

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<GroceryItemFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _GroceryFilterBottomSheet(initial: _itemFilters, tags: _tagOptions),
    );
    if (result == null || !mounted) return;
    _changeFilters(result);
  }

  /// Filters the device can apply: the offers flag and the slider's price bounds.
  List<Map<String, dynamic>> _applyLocalFilters(
    List<Map<String, dynamic>> items,
  ) {
    final bounds = _itemFilters.priceBounds;
    return items.where((item) {
      if (_itemFilters.offersOnly &&
          (item['discount'] ?? '').toString().isEmpty) {
        return false;
      }
      if (bounds != null) {
        final price = (item['sellingPrice'] as num?)?.toDouble() ?? 0;
        if (price < bounds.start || price > bounds.end) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _loadTagOptions() async {
    try {
      final tags = await _getGroceryRepo().fetchGroceryTagChoices(
        language: currentApiLanguage(),
      );
      if (mounted) setState(() => _tagOptions = tags);
    } catch (_) {}
  }

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  List<Map<String, dynamic>> subcategories = [];

  GroceryItemFilters _itemFilters = const GroceryItemFilters();
  List<({int id, String label})> _tagOptions = const [];

  List<Map<String, dynamic>> menuItems = [];
  Map<String, dynamic>? smartBundle;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final currentStore = _storeDetails ?? widget.store;
    final storeId =
        (currentStore['grocery_id'] ??
                currentStore['id'] ??
                widget.store['id'] ??
                'g1')
            .toString();
    final storeName =
        (currentStore['name'] ??
                currentStore['title'] ??
                widget.store['name'] ??
                'Store')
            .toString();
    final storeImage =
        (currentStore['image'] != null &&
            currentStore['image'].toString().isNotEmpty)
        ? currentStore['image'].toString()
        : (widget.store['image']?.toString() ??
              'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop');
    final storeRating =
        (currentStore['rating'] ?? widget.store['rating'] ?? '4.6').toString();
    final storeCategory =
        (currentStore['category'] ??
                widget.store['category'] ??
                'st_grocery'.tr)
            .toString();
    final storeTime =
        (currentStore['time'] ?? widget.store['time'] ?? '30-35 min')
            .toString();
    final storeDist = (currentStore['dist'] ?? widget.store['dist'] ?? '10 Km')
        .toString();
    final storeDiscount =
        (currentStore['discount'] ?? widget.store['discount'] ?? '').toString();

    final isClosed =
        currentStore['isClosed'] == true ||
        currentStore['isClosed'] == 'true' ||
        widget.store['isClosed'] == true ||
        widget.store['isClosed'] == 'true';
    final isTemporarilyClosed =
        currentStore['isTemporarilyClosed'] == true ||
        currentStore['isTemporarilyClosed'] == 'true' ||
        widget.store['isTemporarilyClosed'] == true ||
        widget.store['isTemporarilyClosed'] == 'true';
    final isNotAccepting = isClosed || isTemporarilyClosed;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEADF),
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
                            storeImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFFF3EFEA),
                                  child: const Icon(
                                    Icons.storefront_outlined,
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
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
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
                                          storeName,
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
                                              storeRating,
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
                                    storeCategory,
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
                                        storeTime,
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
                                        storeDist,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (storeDiscount.isNotEmpty) ...[
                                        const SizedBox(width: 14),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5E00),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            storeDiscount,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Closed / Temporarily closed message banner
                                  if (isNotAccepting) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: Color(0xFFEF4444),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isTemporarilyClosed
                                                  ? 'st_temporarily_closed'.tr
                                                  : 'st_currently_closed'.tr,
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFFEF4444),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 10),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            Get.to(
                                              () => MessagesScreen(
                                                restaurant: currentStore,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            height: 38,
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
                                                  ).withValues(alpha: 0.3),
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
                                                  'st_chat_with_store'.tr,
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
                                      GestureDetector(
                                        onTap: () => controller.toggleLike(
                                          storeId,
                                          currentStore,
                                        ),
                                        child: Obx(() {
                                          final liked = controller.isLiked(
                                            storeId,
                                          );
                                          return Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFEAD8C9),
                                                width: 0.8,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.04),
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
                                              color: liked
                                                  ? const Color(0xFFE03A3A)
                                                  : const Color(0xFF2C2520),
                                              size: 18,
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Categories row (scrolls away with banner/info)
                            if (subcategories.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                                padding: const EdgeInsets.only(top: 4),
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
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
                                          _selectCategory(index);
                                        },
                                        child: Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            end:
                                                index ==
                                                    subcategories.length - 1
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
                                                              shape: BoxShape
                                                                  .circle,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withValues(
                                                                        alpha:
                                                                            0.10,
                                                                      ),
                                                                  blurRadius:
                                                                      10,
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
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) => Container(
                                                                      width: 46,
                                                                      height:
                                                                          46,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade300,
                                                                      child: const Icon(
                                                                        Icons
                                                                            .fastfood,
                                                                        size:
                                                                            18,
                                                                        color: Colors
                                                                            .grey,
                                                                      ),
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      isAll
                                                          ? 'st_all'.tr
                                                          : (sub['label'] ?? '')
                                                                .toString(),
                                                      textAlign:
                                                          TextAlign.center,
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
                                                                Color(
                                                                  0xFFFF5E00,
                                                                ),
                                                                Color(
                                                                  0xFFFFAE00,
                                                                ),
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

                    // Products: Smart Bundles + All Items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'st_smart_bundles'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (smartBundle != null)
                      _buildSmartBundleCard(
                        context,
                        isNotAccepting,
                        smartBundle!,
                      )
                    else if (!_isLoading)
                      _buildNoDataPlaceholder('Smart Bundles')
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5E00),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'st_all_store_items'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_subcategories.isNotEmpty) ...[
                      _buildSubcategoryChips(),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    if (_isLoadingItems || _isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5E00),
                          ),
                        ),
                      )
                    else if (menuItems.isEmpty)
                      _buildNoDataPlaceholder('All Items from This Store')
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: menuItems.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 268,
                              ),
                          itemBuilder: (context, index) {
                            return _buildFoodCard(
                              context,
                              menuItems[index],
                              isNotAccepting,
                            );
                          },
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
                color: const Color(0xFFFFEADF),
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

          // 3. Floating Back Button (hidden while sticky search is pinned)
          if (!_showStickySearch)
            PositionedDirectional(
              top: topInset + 12,
              start: 16,
              child: AppBackButton(onTap: () => Navigator.pop(context)),
            ),

          // 4. Floating Cart Summary Bar
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
                      storeName: widget.store['name'],
                      itemName: lastAddedItem?['title'],
                      itemPortion: lastAddedItemPortion,
                      basePrice: parsePrice(lastAddedItem?['price'] ?? '65'),
                      itemImage: lastAddedItem?['image'],
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
                        color: Colors.black.withValues(alpha: 0.3),
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
                          '${controller.cartItemCount.value}',
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
                              controller.cartItemCount.value == 1
                                  ? 'st_view_cart_one'.tr
                                  : 'st_view_cart_many'.trParams({
                                      'count':
                                          '${controller.cartItemCount.value}',
                                    }),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'st_ready_in'.trParams({'time': '30-35'}),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'mru'.trParams({
                              'amount': _cartAmountText(
                                controller.cartAmount.value,
                              ),
                            }),
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

  Widget _buildSmartBundleCard(
    BuildContext context,
    bool isNotAccepting,
    Map<String, dynamic> bundle,
  ) {
    final title = (bundle['title'] ?? 'Special Bundle').toString();
    final itemsDesc = (bundle['items'] ?? 'Bundle').toString();
    final price = (bundle['price'] ?? '— MRU').toString();
    final originalPrice = (bundle['originalPrice'] ?? '').toString();
    final bundlePrice = parsePrice(price);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  itemsDesc,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A6A60),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
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
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isNotAccepting
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'st_store_not_accepting'.tr,
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                : () {
                    setState(() {
                      showCartBar = true;
                      lastAddedItem = {
                        'title': title,
                        'price': price,
                        'image':
                            (_storeDetails?['image'] ?? widget.store['image']),
                      };
                      lastAddedItemPortion = 'Bundle';
                    });
                    if (Get.isRegistered<HomeController>()) {
                      Get.find<HomeController>().setCartItem(
                        storeName:
                            (_storeDetails?['name'] ?? widget.store['name'])
                                ?.toString() ??
                            'Grocery Store',
                        itemName: title,
                        itemPortion: 'Bundle',
                        basePrice: bundlePrice > 0 ? bundlePrice : 750,
                        itemImage:
                            (_storeDetails?['image'] ?? widget.store['image'])
                                ?.toString(),
                      );
                    }
                  },
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: isNotAccepting
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: isNotAccepting ? const Color(0xFFA59A94) : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isNotAccepting
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFFFF5E00,
                          ).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isNotAccepting ? 'st_closed_caps'.tr : 'st_add_caps'.tr,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One size tile in the customize sheet. Same look as the two-option layout.
  Widget _variantTile({
    required List<Map<String, dynamic>> variants,
    required int index,
    required int selected,
    required ValueChanged<int> onSelect,
  }) {
    final variant = variants[index];
    final isSelected = selected == index;
    final inStock = variant['inStock'] == true;

    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0EA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFEAD8C9),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFA59A94),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5E00),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${variant['label']}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inStock ? '${variant['price']}' : 'st_out_of_stock'.tr,
                    style: GoogleFonts.outfit(
                      color: inStock
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFF7A6A60),
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
    );
  }

  Widget _buildFoodCard(
    BuildContext context,
    Map<String, dynamic> food,
    bool isNotAccepting,
  ) {
    return GestureDetector(
      onTap: () => _showFoodDetailsBottomSheet(context, food, isNotAccepting),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AutoSlideNetworkImages(
                      images: foodGalleryImages(food),
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5E00),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (food['discount'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (food['title'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (food['rating'] ?? '4.5').toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '(${food['reviews'] ?? ''})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (food['originalPrice'] ?? '').toString(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFFA59A94),
                      ),
                    ),
                    Text(
                      (food['price'] ?? '').toString(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: isNotAccepting
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'st_store_not_accepting'.tr,
                                    style: GoogleFonts.outfit(),
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          : () {
                              _showCustomizeBottomSheet(
                                context,
                                food,
                                fromBottomSheet: false,
                              );
                            },
                      child: Container(
                        width: double.infinity,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: isNotAccepting
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5E00),
                                    Color(0xFFFFAE00),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: isNotAccepting
                              ? const Color(0xFFA59A94)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isNotAccepting
                                  ? 'st_closed_caps'.tr
                                  : (food['inStock'] == false
                                        ? 'st_sold_out_caps'.tr
                                        : 'st_add_caps'.tr),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetailsBottomSheet(
    BuildContext context,
    Map<String, dynamic> food,
    bool isNotAccepting,
  ) {
    bool isLiked = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFDF9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          child: SizedBox(
                            height: 240,
                            width: double.infinity,
                            child: AutoSlideNetworkImages(
                              images: foodGalleryImages(food),
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            24 + bottomInset,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (food['title'] ?? '').toString(),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5E00),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  (food['tag'] ?? 'Grocery').toString(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    (food['price'] ?? '').toString(),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5E00),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (food['originalPrice'] ?? '').toString(),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: const Color(0xFFA59A94),
                                      decorationThickness: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFAE00),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${food['rating'] ?? '4.5'} (${food['reviews'] ?? ''})',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Text(
                                'st_product_description'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 12,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: isNotAccepting
                                          ? () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'st_store_not_accepting'.tr,
                                                    style: GoogleFonts.outfit(),
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFEF4444,
                                                  ),
                                                ),
                                              );
                                            }
                                          : () {
                                              _showCustomizeBottomSheet(
                                                context,
                                                food,
                                                fromBottomSheet: true,
                                              );
                                            },
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: isNotAccepting
                                              ? null
                                              : const LinearGradient(
                                                  colors: [
                                                    Color(0xFFFF5E00),
                                                    Color(0xFFFFAE00),
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                          color: isNotAccepting
                                              ? const Color(0xFFA59A94)
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            23,
                                          ),
                                          boxShadow: isNotAccepting
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFFF5E00,
                                                    ).withValues(alpha: 0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.shopping_cart_outlined,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isNotAccepting
                                                  ? 'st_closed_caps'.tr
                                                  : 'st_add_to_cart_caps'.tr,
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
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        isLiked = !isLiked;
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
                                          width: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: const Color(0xFFFF5E00),
                                        size: 20,
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
                  ),
                ),

                Positioned(
                  top: -56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFFF5E00,
                            ).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
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
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Variants from the item detail; falls back to the variants already on the row.
  Future<List<Map<String, dynamic>>> _loadVariants(
    Map<String, dynamic> food,
  ) async {
    final menuId = int.tryParse('${food['menuId']}') ?? 0;
    try {
      final detail = await _getGroceryRepo().fetchGroceryItemDetail(
        menuId: menuId,
        groceryId: _groceryId(),
        language: currentApiLanguage(),
      );
      final variants = (detail['variants'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      if (variants.isNotEmpty) return variants;
    } catch (_) {}
    try {
      final menuVariants = await _getGroceryRepo().fetchGroceryMenuVariants(
        menuId: menuId,
        groceryId: _groceryId(),
        language: currentApiLanguage(),
      );
      if (menuVariants.isNotEmpty) return menuVariants;
    } catch (_) {}
    return (food['variants'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _showCustomizeBottomSheet(
    BuildContext context,
    Map<String, dynamic> food, {
    required bool fromBottomSheet,
  }) async {
    final variants = await _loadVariants(food);
    if (!mounted || !context.mounted) return;
    if (variants.isEmpty) {
      ToastHelper.showError('st_no_sizes'.tr);
      return;
    }

    int selectedQuantityIndex = 0;
    int quantity = 1;
    final TextEditingController notesController = TextEditingController();

    final title = (food['title'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFDF9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFEAD8C9), height: 1),

                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity Section
                              Text(
                                'st_quantity'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              for (var i = 0; i < variants.length; i += 2) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _variantTile(
                                        variants: variants,
                                        index: i,
                                        selected: selectedQuantityIndex,
                                        onSelect: (value) => setModalState(
                                          () => selectedQuantityIndex = value,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: i + 1 < variants.length
                                          ? _variantTile(
                                              variants: variants,
                                              index: i + 1,
                                              selected: selectedQuantityIndex,
                                              onSelect: (value) =>
                                                  setModalState(
                                                    () =>
                                                        selectedQuantityIndex =
                                                            value,
                                                  ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                                if (i + 2 < variants.length)
                                  const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 16),

                              // Customize quantity field
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFEAD8C9),
                                    width: 0.8,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                alignment: AlignmentDirectional.centerStart,
                                child: TextField(
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF2C2520),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'st_customize_quantity'.tr,
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Add Order Notes Section
                              Text(
                                'st_add_order_notes'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEAD8C9),
                                    width: 0.8,
                                  ),
                                ),
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  12,
                                  10,
                                  10,
                                  10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: notesController,
                                        maxLines: 2,
                                        minLines: 1,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF2C2520),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'st_add_notes_hint'
                                              .trParams({
                                                'item': title
                                                    .toLowerCase()
                                                    .replaceAll(
                                                      RegExp(
                                                        r'\s*\d+\s*[kKgGlL]+',
                                                      ),
                                                      '',
                                                    ),
                                              }),
                                          hintStyle: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 12,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF0EA),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        'lib/assets/images/Voice.png',
                                        width: 16,
                                        height: 16,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.mic_none_rounded,
                                          color: Color(0xFFFF5E00),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Bottom actions bar
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          12,
                          20,
                          24 + MediaQuery.of(context).padding.bottom,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFEAD8C9),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Quantity Counter
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0EA),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (quantity > 1) {
                                        setModalState(() {
                                          quantity--;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove,
                                        color: Color(0xFFFF5E00),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    quantity.toString(),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        quantity++;
                                      });
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF5E00),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final variant =
                                      variants[selectedQuantityIndex];
                                  if (variant['inStock'] != true) {
                                    ToastHelper.showError(
                                      'st_size_out_of_stock'.tr,
                                    );
                                    return;
                                  }
                                  if (!await _confirmReplaceCartIfNeeded(
                                    context,
                                  )) {
                                    return;
                                  }
                                  try {
                                    await _getGroceryRepo().addGroceryCartItem(
                                      groceryId: _groceryId(),
                                      productId: variant['productId'] as int,
                                      attributeId:
                                          variant['attributeId'] as int?,
                                      unitPrice:
                                          variant['sellingPrice'] as double,
                                      quantity: quantity,
                                      language: currentApiLanguage(),
                                    );
                                  } on ApiException catch (error) {
                                    ToastHelper.showError(error.message);
                                    return;
                                  }
                                  // Shows the added amount at once; the server total replaces it below.
                                  if (Get.isRegistered<HomeController>()) {
                                    Get.find<HomeController>()
                                            .cartAmount
                                            .value +=
                                        (variant['sellingPrice'] as double) *
                                        quantity;
                                  }
                                  _refreshCartCount();
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  if (fromBottomSheet) {
                                    Navigator.pop(context);
                                  }

                                  setState(() {
                                    lastAddedItem = Map<String, dynamic>.from(
                                      food,
                                    );
                                    lastAddedItem!['price'] = variant['price'];
                                    lastAddedItemPortion =
                                        '${variant['label']}';
                                    showCartBar = true;
                                  });
                                  if (Get.isRegistered<HomeController>()) {
                                    Get.find<HomeController>().setCartItem(
                                      storeName:
                                          widget.store['name']?.toString() ??
                                          'Grocery Store',
                                      itemName: lastAddedItem?['title']
                                          ?.toString(),
                                      itemPortion: lastAddedItemPortion,
                                      basePrice: parsePrice(
                                        lastAddedItem?['price']?.toString() ??
                                            '65',
                                      ),
                                      itemImage: lastAddedItem?['image']
                                          ?.toString(),
                                    );
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'st_added_to_cart'.trParams({
                                          'item': '${food['title']}',
                                        }),
                                        style: GoogleFonts.outfit(),
                                      ),
                                      backgroundColor: const Color(0xFFFF5E00),
                                      duration: const Duration(seconds: 2),
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
                                    borderRadius: BorderRadius.circular(22),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'st_add_caps'.tr,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFFF5E00,
                            ).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
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
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Filters applied to the store's items. Empty values mean "no filter".
class GroceryItemFilters {
  const GroceryItemFilters({
    this.sortBy = 'relevance',
    this.priceRange,
    this.priceBounds,
    this.rating,
    this.offersOnly = false,
    this.tagIds = const {},
  });

  /// Sort value sent as sort_by.
  final String sortBy;

  /// Server price bucket (price_range), set by the "Under 200 MRU" chip.
  final String? priceRange;

  /// Slider bounds in MRU, filtered on the device. Null means no bounds.
  final RangeValues? priceBounds;
  final double? rating;
  final bool offersOnly;
  final Set<int> tagIds;

  GroceryItemFilters copyWith({
    String? sortBy,
    String? priceRange,
    bool clearPriceRange = false,
    double? rating,
    bool clearRating = false,
    bool? offersOnly,
    Set<int>? tagIds,
  }) {
    return GroceryItemFilters(
      sortBy: sortBy ?? this.sortBy,
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      priceBounds: priceBounds,
      rating: clearRating ? null : (rating ?? this.rating),
      offersOnly: offersOnly ?? this.offersOnly,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}

class _GroceryFilterBottomSheet extends StatefulWidget {
  const _GroceryFilterBottomSheet({required this.initial, required this.tags});

  final GroceryItemFilters initial;
  final List<({int id, String label})> tags;

  @override
  State<_GroceryFilterBottomSheet> createState() =>
      _GroceryFilterBottomSheetState();
}

class _GroceryFilterBottomSheetState extends State<_GroceryFilterBottomSheet> {
  static const RangeValues _fullRange = RangeValues(0, 3000);
  static const Map<String, double> _ratingChips = {
    'Ratings 4.5+': 4.5,
    'Ratings 4.0+': 4.0,
    'Ratings 3.0+': 3.0,
  };
  static const Map<String, String> _sortChips = {
    'Relevance': 'relevance',
    'Delivery Time': 'delivery_time',
    'Cost: Low to High': 'price_low_to_high',
    'Cost: High to Low': 'price_high_to_low',
  };

  late final Set<String> selectedTags = {
    if (widget.initial.offersOnly) 'Offers',
    for (final entry in _ratingChips.entries)
      if (widget.initial.rating == entry.value) entry.key,
    for (final tag in widget.tags)
      if (widget.initial.tagIds.contains(tag.id)) tag.label,
  };
  late RangeValues priceRange = widget.initial.priceBounds ?? _fullRange;
  late String selectedSortBy = _sortChips.entries
      .firstWhere(
        (entry) => entry.value == widget.initial.sortBy,
        orElse: () => _sortChips.entries.first,
      )
      .key;

  List<String> get filterTags => [
    'Offers',
    ..._ratingChips.keys,
    for (final tag in widget.tags) tag.label,
  ];
  List<String> get sortOptions => _sortChips.keys.toList();

  void _clearAll() {
    setState(() {
      selectedTags.clear();
      priceRange = _fullRange;
      selectedSortBy = 'Relevance';
    });
  }

  /// Turns the chosen labels into the filters the screen applies.
  GroceryItemFilters _result() {
    final rating = _ratingChips.entries
        .where((entry) => selectedTags.contains(entry.key))
        .map((entry) => entry.value)
        .firstOrNull;
    return GroceryItemFilters(
      sortBy: _sortChips[selectedSortBy] ?? 'relevance',
      priceRange: widget.initial.priceRange,
      priceBounds: priceRange == _fullRange ? null : priceRange,
      rating: rating,
      offersOnly: selectedTags.contains('Offers'),
      tagIds: {
        for (final tag in widget.tags)
          if (selectedTags.contains(tag.label)) tag.id,
      },
    );
  }

  // Chip values stay in English (they drive the filters); only the text
  // shown is translated. Store tags come from the server as they are.
  static const _chipKeys = {
    'Offers': 'st_offers',
    'Ratings 4.5+': 'st_ratings_45',
    'Ratings 4.0+': 'st_ratings_40',
    'Ratings 3.0+': 'st_ratings_30',
    'Relevance': 'st_sort_relevance',
    'Delivery Time': 'st_sort_delivery_time',
    'Cost: Low to High': 'st_sort_cost_low_high',
    'Cost: High to Low': 'st_sort_cost_high_low',
  };

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
          _chipKeys[label]?.tr ?? label,
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

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 60),
                      Text(
                        'st_filters'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearAll,
                        child: Text(
                          'st_clear_all'.tr,
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
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: filterTags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: _buildChip(tag, isSelected, () {
                          setState(() {
                            if (selectedTags.contains(tag)) {
                              selectedTags.remove(tag);
                            } else {
                              // Only one rating can be chosen at a time.
                              if (_ratingChips.containsKey(tag)) {
                                selectedTags.removeWhere(
                                  _ratingChips.containsKey,
                                );
                              }
                              selectedTags.add(tag);
                            }
                          });
                        }),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'st_price_range'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'st_price_range_value'.trParams({
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFF5E00),
                      inactiveTrackColor: const Color(0xFFF3EFEA),
                      overlayColor: const Color(
                        0xFFFF5E00,
                      ).withValues(alpha: 0.12),
                      rangeThumbShape: const _GroceryRangeThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: RangeSlider(
                      values: priceRange,
                      min: 0,
                      max: 3000,
                      divisions: 60,
                      onChanged: (values) {
                        setState(() => priceRange = values);
                      },
                    ),
                  ),
                ),
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
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    'st_sort_by'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: sortOptions.map((option) {
                      final isSelected = selectedSortBy == option;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: _buildChip(option, isSelected, () {
                          setState(() => selectedSortBy = option);
                        }),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 12 + bottomPad),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _clearAll,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EA),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            'st_clear_all'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, _result()),
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF5E00,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'st_apply'.tr,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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

class _GroceryRangeThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;

  const _GroceryRangeThumbShape({this.enabledThumbRadius = 10.0});

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
    final canvas = context.canvas;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, enabledThumbRadius, shadowPaint);

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFF5E00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, enabledThumbRadius - 1.25, borderPaint);
  }
}
