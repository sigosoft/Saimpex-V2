import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/session_store.dart';
import '../../models/grocery_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../../widgets/filter_chip_style.dart';
import '../messages_screen.dart';
import '../cart_screen.dart';
import '../../widgets/app_back_button.dart';
import '../widgets/auto_slide_network_images.dart';

class GroceryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const GroceryDetailsScreen({Key? key, required this.store}) : super(key: key);

  @override
  State<GroceryDetailsScreen> createState() => _GroceryDetailsScreenState();
}

class _GroceryDetailsScreenState extends State<GroceryDetailsScreen> {
  int activeSubcategoryIndex = 0;
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
    await _loadGroceryDetails();
    await _loadGroceryItems();
  }

  Future<void> _loadGroceryDetails() async {
    setState(() => _isLoading = true);
    try {
      final repo = _getGroceryRepo();
      final lang = currentApiLanguage();
      final lat = SelectLocationController.selectedLatitude ?? 18.0735;
      final lng = SelectLocationController.selectedLongitude ?? -15.9582;

      final rawId =
          widget.store['grocery_id'] ??
          widget.store['id'] ??
          widget.store['vendor_id'] ??
          widget.store['restaurant_id'] ??
          (widget.store['raw'] is Map
              ? (widget.store['raw']['grocery_id'] ??
                    widget.store['raw']['id'] ??
                    widget.store['raw']['vendor_id'])
              : null);

      final groceryId = int.tryParse('$rawId') ?? 0;

      final details = await repo.fetchGroceryDetails(
        groceryId: groceryId,
        latitude: lat,
        longitude: lng,
        language: lang,
      );

      if (!mounted) return;
      setState(() {
        _storeDetails = details;
        subcategories =
            (details['categories'] as List<Map<String, dynamic>>?) ?? [];
        smartBundle = details['smartBundle'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        subcategories = [];
        smartBundle = null;
        _isLoading = false;
      });
      if (e is ApiException) {
        ToastHelper.showError(e.message);
      }
    }
  }

  Future<void> _loadGroceryItems() async {
    if (!mounted) return;
    setState(() => _isLoadingItems = true);
    try {
      final repo = _getGroceryRepo();
      final lang = currentApiLanguage();

      final rawId =
          widget.store['grocery_id'] ??
          widget.store['id'] ??
          widget.store['vendor_id'] ??
          widget.store['restaurant_id'] ??
          (_storeDetails != null
              ? (_storeDetails!['grocery_id'] ?? _storeDetails!['id'])
              : null) ??
          (widget.store['raw'] is Map
              ? (widget.store['raw']['grocery_id'] ??
                    widget.store['raw']['id'] ??
                    widget.store['raw']['vendor_id'])
              : null);

      final groceryId = int.tryParse('$rawId') ?? 0;

      dynamic categoryId;
      dynamic subCategoryId;

      if (activeSubcategoryIndex >= 0 &&
          activeSubcategoryIndex < subcategories.length) {
        final selected = subcategories[activeSubcategoryIndex];
        if (selected['isAll'] != true) {
          categoryId =
              selected['category_id'] ??
              selected['id'] ??
              (selected['raw'] is Map
                  ? (selected['raw']['category_id'] ?? selected['raw']['id'])
                  : null);
          subCategoryId =
              selected['sub_category_id'] ??
              (selected['raw'] is Map
                  ? (selected['raw']['sub_category_id'] ??
                        selected['raw']['subcategory_id'])
                  : null);
        }
      }

      categoryId ??=
          widget.store['category_id'] ??
          widget.store['cat_id'] ??
          (subcategories.isNotEmpty
              ? (subcategories.first['category_id'] ??
                    subcategories.first['id'])
              : null) ??
          '1';

      subCategoryId ??=
          widget.store['sub_category_id'] ??
          (subcategories.isNotEmpty
              ? subcategories.first['sub_category_id']
              : null) ??
          categoryId;

      final items = await repo.fetchGroceryItems(
        groceryId: groceryId,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        limit: 20,
        language: lang,
      );

      if (!mounted) return;
      setState(() {
        menuItems = items;
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

  Widget _buildNoDataPlaceholder(String title) {
    String message;
    final lower = title.toLowerCase();
    if (lower.contains('item') || lower.contains('product')) {
      message = 'No items available from this store';
    } else if (lower.contains('bundle')) {
      message = 'No smart bundles available';
    } else if (lower.contains('categor')) {
      message = 'No categories available';
    } else {
      message = 'No data available';
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
                  hintText: 'Find something from this Store',
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
    return AppFilterChipsRow(
      children: [
        for (final filter in filters)
          AppFilterChip(
            label: filter['label'] as String,
            onTap: filter['label'] == 'Filter' ? _showFilterBottomSheet : null,
            leading: filter['isMru'] == true
                ? AppFilterChip.mruLeading()
                : filter['icon'] is IconData
                ? AppFilterChip.iconLeading(
                    filter['icon'] as IconData,
                    color: filter['label'] == 'Rating'
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

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  List<Map<String, dynamic>> subcategories = [];

  final List<Map<String, dynamic>> filters = [
    {'label': 'Filter', 'icon': Image.asset("lib/assets/images/Filter.png")},
    {'label': 'Under 200 MRU', 'isMru': true},
    {'label': 'Offers', 'icon': Image.asset("lib/assets/images/Offer.png")},
    {'label': 'Rating', 'icon': Icons.star_rounded},
  ];

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
        (currentStore['category'] ?? widget.store['category'] ?? 'Grocery')
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
                                                  ? 'Temporarily not accepting orders'
                                                  : 'Currently Closed',
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
                                                  'Chat with Store',
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
                                          if (activeSubcategoryIndex != index) {
                                            setState(() {
                                              activeSubcategoryIndex = index;
                                            });
                                            _loadGroceryItems();
                                          }
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right:
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
                                                                      .withOpacity(
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
                                                      (sub['label'] ?? '')
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
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Smart Bundles',
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
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'All Items from This Store',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
            Positioned(
              top: topInset + 12,
              left: 16,
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
                          '1',
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
                              'View Cart • 1 items',
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
                            lastAddedItem?['price'] ?? '65 MRU',
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
    final price = (bundle['price'] ?? '750 MRU').toString();
    final originalPrice = (bundle['originalPrice'] ?? '1500 MRU').toString();
    final bundlePrice = parsePrice(price);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                          'Store is currently closed or temporarily not accepting orders.',
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
                    isNotAccepting ? 'CLOSED' : 'ADD',
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
              color: Colors.black.withOpacity(0.03),
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
                  Positioned(
                    top: 8,
                    left: 8,
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
                                    'Store is currently closed or temporarily not accepting orders.',
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
                              isNotAccepting ? 'CLOSED' : 'ADD',
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
                                'Premium quality fresh product sourced directly from local producers, ensuring high nutritional value and clean packaging.',
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
                                                    'Store is currently closed or temporarily not accepting orders.',
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
                                            const Icon(
                                              Icons.shopping_cart_outlined,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isNotAccepting
                                                  ? 'CLOSED'
                                                  : 'ADD TO CART',
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
                                            color: Colors.black.withOpacity(
                                              0.04,
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

  void _showCustomizeBottomSheet(
    BuildContext context,
    Map<String, dynamic> food, {
    required bool fromBottomSheet,
  }) {
    int selectedQuantityIndex = 0; // Default to first (1 Kg)
    int quantity = 1;
    final TextEditingController notesController = TextEditingController();

    // Determine quantity text and price options based on clicked item
    String qtyText1 = '1 Kg';
    String qtyPrice1 = food['price'] ?? '50 MRU';
    String qtyText2 = '5 Kg';
    String qtyPrice2 = '550 MRU';

    final title = (food['title'] ?? '').toString();
    if (title.contains('Milk')) {
      qtyText1 = '1 L';
      qtyPrice1 = '65 MRU';
      qtyText2 = '5 L';
      qtyPrice2 = '300 MRU';
    } else if (title.contains('Egg')) {
      qtyText1 = '1 Pack';
      qtyPrice1 = '65 MRU';
      qtyText2 = '3 Packs';
      qtyPrice2 = '180 MRU';
    } else if (title.contains('Broccoli')) {
      qtyText1 = '500 g';
      qtyPrice1 = '80 MRU';
      qtyText2 = '2.5 Kg';
      qtyPrice2 = '360 MRU';
    } else if (title.contains('Onion')) {
      qtyText1 = '1 Kg';
      qtyPrice1 = '45 MRU';
      qtyText2 = '5 Kg';
      qtyPrice2 = '200 MRU';
    } else if (title.contains('Rice')) {
      qtyText1 = '1 Kg';
      qtyPrice1 = '90 MRU';
      qtyText2 = '5 Kg';
      qtyPrice2 = '400 MRU';
    } else if (title.contains('Masala')) {
      qtyText1 = '100 g';
      qtyPrice1 = '55 MRU';
      qtyText2 = '500 g';
      qtyPrice2 = '250 MRU';
    } else if (title == 'Potato') {
      qtyText1 = '1 Kg';
      qtyPrice1 = '50 MRU';
      qtyText2 = '5 Kg';
      qtyPrice2 = '550 MRU';
    }

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
                                'Quantity',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  // Option 1
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedQuantityIndex = 0;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selectedQuantityIndex == 0
                                              ? const Color(0xFFFFF0EA)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: selectedQuantityIndex == 0
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAD8C9),
                                            width: selectedQuantityIndex == 0
                                                ? 1.5
                                                : 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Radio dot
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      selectedQuantityIndex == 0
                                                      ? const Color(0xFFFF5E00)
                                                      : const Color(0xFFA59A94),
                                                  width: 1.5,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(3),
                                              child: selectedQuantityIndex == 0
                                                  ? Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Color(
                                                              0xFFFF5E00,
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  qtyText1,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(
                                                      0xFF2C2520,
                                                    ),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  qtyPrice1,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(
                                                      0xFFFF5E00,
                                                    ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Option 2
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedQuantityIndex = 1;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selectedQuantityIndex == 1
                                              ? const Color(0xFFFFF0EA)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: selectedQuantityIndex == 1
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAD8C9),
                                            width: selectedQuantityIndex == 1
                                                ? 1.5
                                                : 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Radio dot
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      selectedQuantityIndex == 1
                                                      ? const Color(0xFFFF5E00)
                                                      : const Color(0xFFA59A94),
                                                  width: 1.5,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(3),
                                              child: selectedQuantityIndex == 1
                                                  ? Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Color(
                                                              0xFFFF5E00,
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  qtyText2,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(
                                                      0xFF2C2520,
                                                    ),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  qtyPrice2,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(
                                                      0xFFFF5E00,
                                                    ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
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
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF2C2520),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Customize  your quantity here',
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
                                'Add Order Notes',
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
                                padding: const EdgeInsets.fromLTRB(
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
                                          hintText:
                                              'Add notes (e.g, fresh ${title.toLowerCase().replaceAll(RegExp(r'\s*\d+\s*[kKgGlL]+'), '')} only...)',
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
                                onTap: () {
                                  Navigator.pop(context);
                                  if (fromBottomSheet) {
                                    Navigator.pop(context);
                                  }

                                  setState(() {
                                    lastAddedItem = Map<String, dynamic>.from(
                                      food,
                                    );
                                    lastAddedItem!['price'] =
                                        (selectedQuantityIndex == 0)
                                        ? qtyPrice1
                                        : qtyPrice2;
                                    lastAddedItemPortion =
                                        (selectedQuantityIndex == 0)
                                        ? qtyText1
                                        : qtyText2;
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
                                        '${food['title']} added to cart!',
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
                                        ).withOpacity(0.3),
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
                                        'ADD',
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GroceryFilterBottomSheet(),
    );
  }
}

class _GroceryFilterBottomSheet extends StatefulWidget {
  const _GroceryFilterBottomSheet();

  @override
  State<_GroceryFilterBottomSheet> createState() =>
      _GroceryFilterBottomSheetState();
}

class _GroceryFilterBottomSheetState extends State<_GroceryFilterBottomSheet> {
  final List<String> selectedTags = [];
  RangeValues priceRange = const RangeValues(65, 1500);
  String selectedSortBy = 'Relevance';

  final List<String> filterTags = [
    'Offers',
    'Ratings 4.5+',
    'Ratings 4.0+',
    'Ratings 3.0+',
  ];
  final List<String> sortOptions = [
    'Relevance',
    'Delivery Time',
    'Cost: Low to High',
    'Cost: High to Low',
  ];

  void _clearAll() {
    setState(() {
      selectedTags.clear();
      priceRange = const RangeValues(65, 1500);
      selectedSortBy = 'Relevance';
    });
  }

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
                        'Filters',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearAll,
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
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: filterTags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildChip(tag, isSelected, () {
                          setState(() {
                            if (selectedTags.contains(tag)) {
                              selectedTags.remove(tag);
                            } else {
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFFF5E00),
                      inactiveTrackColor: const Color(0xFFF3EFEA),
                      overlayColor: const Color(0xFFFF5E00).withOpacity(0.12),
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
                const SizedBox(height: 22),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: sortOptions.map((option) {
                      final isSelected = selectedSortBy == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
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
                            'Clear All',
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
                          onTap: () => Navigator.pop(context),
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
                                  ).withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Apply',
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
      ..color = Colors.black.withOpacity(0.15)
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
