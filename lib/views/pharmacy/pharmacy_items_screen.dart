import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/cart_repository.dart';
import '../../models/pharmacy_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../chat_screen.dart';
import '../cart_screen.dart';
import 'upload_prescription_screen.dart';
import 'widgets/attach_prescription_sheet.dart';
import 'widgets/pharmacy_background.dart';
import 'widgets/pharmacy_cart_bar.dart';
import 'widgets/pharmacy_customize_sheet.dart';
import 'widgets/pharmacy_product_card.dart';
import 'widgets/pharmacy_product_details_sheet.dart';
import 'widgets/pharmacy_subcategory_icon.dart';
import '../../widgets/app_back_button.dart';

class PharmacyItemsScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final int initialSubcategoryIndex;
  final int? initialCategoryId;

  const PharmacyItemsScreen({
    super.key,
    required this.store,
    this.initialSubcategoryIndex = 0,
    this.initialCategoryId,
  });

  @override
  State<PharmacyItemsScreen> createState() => _PharmacyItemsScreenState();
}

class _PharmacyItemsScreenState extends State<PharmacyItemsScreen> {
  late int activeSubcategoryIndex;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool showCartBar = false;
  bool _showStickySearch = false;
  bool _loadingStore = false;
  bool _loadingMore = false;
  int _page = 1;
  int _lastPage = 1;
  int _requestId = 0;
  int? _selectedCategoryId;
  Timer? _searchDebounce;
  Map<String, dynamic>? _pharmacyDetails;
  Map<String, dynamic>? lastAddedItem;
  String? lastAddedItemPortion;

  /// categories(~86) + gap(8) + search(40) + padding ≈ 144
  static const double _searchFiltersExtent = 144;

  @override
  void initState() {
    super.initState();
    activeSubcategoryIndex = widget.initialSubcategoryIndex;
    final initialCategory = widget.initialCategoryId;
    if (initialCategory != null && initialCategory != 0) {
      _selectedCategoryId = initialCategory;
    }
    _scrollController.addListener(_handleScroll);
    if (_pharmacyId != null) {
      subcategories = [];
      menuItems = [];
      _loadingStore = true;
      searchController.addListener(_onSearchChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadStore(reset: true);
      });
    }
  }

  int? get _pharmacyId => int.tryParse('${widget.store['id']}');

  Map<String, dynamic> get _store => {...widget.store, ...?_pharmacyDetails};

  bool get _usesApi => _pharmacyId != null;

  Future<bool> _addPharmacyItem(
    Map<String, dynamic> item, {
    String? portion,
    int quantity = 1,
  }) async {
    final pharmacyId = _pharmacyId;
    final productId = int.tryParse('${item['productId'] ?? ''}');
    if (pharmacyId == null || productId == null || productId < 1) {
      showAppToast('pw_unable_to_add_item'.tr);
      return false;
    }
    try {
      final added = await Get.find<CartRepository>().addPharmacyItem(
        pharmacyId: pharmacyId,
        productId: productId,
        quantity: quantity,
        language: apiLanguageCode(),
      );
      if (!mounted) return false;
      setState(() {
        lastAddedItem = item;
        lastAddedItemPortion = portion;
        showCartBar = true;
      });
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().setCartItem(
          storeName: _storeText('title', ''),
          itemName: item['title']?.toString(),
          itemPortion: portion ?? item['tag']?.toString() ?? '10 Tablets',
          basePrice: parsePrice(item['price']?.toString() ?? '50'),
          itemImage: item['image']?.toString(),
          quantity: quantity,
        );
      }
      showAppToast(added.message, backgroundColor: const Color(0xFFFF5E00));
      if (added.needsPrescription) {
        await _attachPrescription(pharmacyId);
      }
      return true;
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
      return false;
    }
  }

  Future<void> _attachPrescription(int pharmacyId) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachPrescriptionSheet(pharmacyId: pharmacyId),
    );
  }

  String _storeText(String key, String fallback) {
    final value = _store[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
    return _usesApi ? '' : fallback;
  }

  void _onSearchChanged() {
    if (_pharmacyId == null) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadStore(reset: true);
    });
  }

  Future<void> _loadStore({required bool reset}) async {
    final pharmacyId = _pharmacyId;
    if (pharmacyId == null || !Get.isRegistered<PharmacyRepository>()) return;
    if (!reset) {
      if (_loadingStore || _loadingMore || _page >= _lastPage) return;
    }

    final requestId = ++_requestId;
    final nextPage = reset ? 1 : _page + 1;
    setState(() {
      if (reset) {
        menuItems = [];
        _loadingStore = true;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final result = await Get.find<PharmacyRepository>().fetchStore(
        pharmacyId: pharmacyId,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
        categoryId: _selectedCategoryId,
        keyword: searchController.text,
        page: nextPage,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        if (reset) {
          _pharmacyDetails = result.pharmacy;
          _applyCategories(result.categories, result.selectedCategoryId);
        }
        menuItems = reset ? result.items : [...menuItems, ...result.items];
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _loadingStore = false;
        _loadingMore = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadingStore = false;
        _loadingMore = false;
      });
      showAppToast(error.message);
    }
  }

  void _applyCategories(
    List<Map<String, dynamic>> categoriesFromApi,
    int selectedCategoryId,
  ) {
    final categories = [
      if (!categoriesFromApi.any((category) => category['id'] == 0))
        {
          'id': 0,
          'label': switch (apiLanguageCode()) {
            'ar' => 'الكل',
            'fr' => 'Tous',
            _ => 'All',
          },
          'isAll': true,
        },
      ...categoriesFromApi,
    ];
    final selectedId = _selectedCategoryId ?? selectedCategoryId;
    final selectedIndex = categories.indexWhere(
      (category) => category['id'] == selectedId,
    );
    subcategories = categories;
    activeSubcategoryIndex = selectedIndex < 0 ? 0 : selectedIndex;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.removeListener(_onSearchChanged);
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
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadStore(reset: false);
    }
  }

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  Widget _buildSubcategoriesRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      padding: const EdgeInsets.only(top: 4),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF8),
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
          itemCount: subcategories.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          itemBuilder: (context, index) {
            final sub = subcategories[index];
            final isAll = sub['isAll'] == true;
            final isSelected = activeSubcategoryIndex == index;
            final iconPath = sub['icon'] as String?;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  activeSubcategoryIndex = index;
                });
                if (_pharmacyId == null) return;
                final raw = sub['id'];
                final id = raw is int ? raw : int.tryParse('$raw');
                _selectedCategoryId = id == null || id == 0 ? null : id;
                _loadStore(reset: true);
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
                                      color: const Color(0xFFFF5E00),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      width: 46,
                                      height: 46,
                                      color: Colors.white,
                                      child: _categoryIcon(sub, iconPath),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  hintText: 'pw_search_items'.tr,
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/images/Voice.png',
                  width: 12,
                  height: 12,
                  color: const Color(0xFFFF5E00),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickySection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: _buildSubcategoriesRow(),
        ),
        const SizedBox(height: 10),
        _buildSearchBar(),
      ],
    );
  }

  Widget _categoryIcon(Map<String, dynamic> sub, String? iconPath) {
    final image = sub['image']?.toString() ?? '';
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
          pharmacySubcategoryIcon(sub['label']?.toString() ?? ''),
          color: const Color(0xFF00ACC1),
          size: 22,
        ),
      );
    }
    if (iconPath != null) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(iconPath, fit: BoxFit.contain),
      );
    }
    return Icon(
      pharmacySubcategoryIcon(sub['label']?.toString() ?? ''),
      color: const Color(0xFF00ACC1),
      size: 22,
    );
  }

  // Subcategories and products come only from the store API.
  List<Map<String, dynamic>> subcategories = [];
  List<Map<String, dynamic>> menuItems = [];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final storeId = _storeText('id', 'p1');
    final storeTitle = _storeText('title', '');
    final storeImage = _storeText('image', '');
    final storeTime = _storeText('time', '30-35 min');
    final storeDistance = _storeText('dist', '10 Km');
    final storeDiscount = _storeText('discount', '50% OFF');
    final isClosed = widget.store['isClosed'] == true;
    final isTemporarilyClosed = widget.store['isTemporarilyClosed'] == true;
    final isNotAccepting = isClosed || isTemporarilyClosed;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Single scroll + sticky subcategories/search
            Positioned.fill(
              child: Obx(() {
                final hasItems = controller.cartItemCount.value > 0;
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: hasItems ? bottomInset + 88 : 24,
                  ),
                  child: Column(
                    children: [
                      // Collapses: banner + info + upload
                      Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: topInset + 96,
                            child: storeImage.isEmpty
                                ? Container(
                                    color: const Color(0xFFF3EFEA),
                                    child: const Icon(
                                      Icons.storefront_outlined,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  )
                                : Image.network(
                                    storeImage,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
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
                            children: [
                              SizedBox(height: topInset + 52),
                              // Floating Info Card
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
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
                                            storeTitle,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF2C2520),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E),
                                            borderRadius: BorderRadius.circular(
                                              12,
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
                                                _storeText('rating', '4.6'),
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
                                    const SizedBox(height: 2),
                                    Text(
                                      _storeText('subtitle', 'Trusted'),
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF7A6A60),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (storeTime.isNotEmpty) ...[
                                          const Icon(
                                            Icons.access_time_rounded,
                                            color: Color(0xFFFF5E00),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            storeTime,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF7A6A60),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (storeDistance.isNotEmpty) ...[
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: Color(0xFFFF5E00),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            storeDistance,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF7A6A60),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        if (storeDiscount.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF5E00),
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                    if (isNotAccepting) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Color(0xFFEF4444),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                isTemporarilyClosed
                                                    ? 'pw_temporarily_not_accepting_orders'
                                                          .tr
                                                    : 'pw_currently_closed'.tr,
                                                style: GoogleFonts.outfit(
                                                  color: const Color(
                                                    0xFFEF4444,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              Get.to(
                                                () => ChatScreen(
                                                  restaurant: {
                                                    'title': storeTitle,
                                                    'image': storeImage,
                                                  },
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
                                                    BorderRadius.circular(19),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    "lib/assets/images/Chat Details.png",
                                                    height: 16,
                                                    width: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'pw_chat_with_pharmacy'.tr,
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () => controller.toggleLike(
                                            storeId,
                                            _store,
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
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFEAD8C9,
                                                  ),
                                                  width: 0.8,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                liked
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                          .favorite_border_rounded,
                                                color: liked
                                                    ? const Color(0xFFFF5E00)
                                                    : const Color(0xFFA59A94),
                                                size: 16,
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Upload Your Prescription
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Get.to(
                                      () => UploadPrescriptionScreen(
                                        initialPharmacy: storeTitle,
                                        initialPharmacyId: _pharmacyId,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCBEFF4),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFA2E0E8),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF0097A7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.description_outlined,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'pw_upload_your_prescription'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF3A312C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ),

                      // Sticky anchor: categories + search
                      KeyedSubtree(
                        key: _searchAnchorKey,
                        child: _showStickySearch
                            ? const SizedBox(height: _searchFiltersExtent)
                            : _buildStickySection(),
                      ),

                      const SizedBox(height: 8),

                      // All Items title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            'pw_all_items_from_pharmacy'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      // Products grid
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
                                mainAxisExtent: 248,
                              ),
                          itemBuilder: (context, index) {
                            final food = menuItems[index];
                            return PharmacyProductCard(
                              food: food,
                              isNotAccepting: isNotAccepting,
                              onTap: () => showPharmacyProductDetailsSheet(
                                context,
                                food: food,
                                menuId: int.tryParse('${food['id']}'),
                                pharmacyId: _pharmacyId,
                                isNotAccepting: isNotAccepting,
                                onAdd: () => _addPharmacyItem(
                                  food,
                                  portion: food['tag']?.toString(),
                                ),
                              ),
                              onAdd: () => showPharmacyCustomizeSheet(
                                context,
                                food: food,
                                fromBottomSheet: false,
                                onAdded: (item, portion, quantity) =>
                                    _addPharmacyItem(
                                      item,
                                      portion: portion,
                                      quantity: quantity,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_loadingStore && menuItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 28),
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5E00),
                          ),
                        ),
                      if (!_loadingStore && menuItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Text(
                            'pw_no_items'.tr,
                            style: GoogleFonts.outfit(
                              color: Color(0xFF7A6A60),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Color(0xFFFF5E00),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),

            // Sticky subcategories + search overlay
            if (_showStickySearch)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 2,
                  color: PharmacyBackground.top,
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset, bottom: 8),
                    child: _buildStickySection(),
                  ),
                ),
              ),
            // Floating Back Button (hidden while sticky is pinned)
            if (!_showStickySearch)
              PositionedDirectional(
                top: topInset + 10,
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
                return PharmacyCartBar(
                  price: lastAddedItem?['price'] ?? '0 MRU',
                  onTap: () {
                    Get.to(
                      () => CartScreen(
                        showBottomNav: false,
                        storeName: storeTitle,
                        itemName: lastAddedItem?['title'],
                        itemPortion: lastAddedItemPortion,
                        basePrice: parsePrice(lastAddedItem?['price'] ?? '50'),
                        itemImage: lastAddedItem?['image'],
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
}
