import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/water_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../chat_screen.dart';
import '../cart_screen.dart';
import '../../widgets/bottom_chat_icon.dart';
import 'widgets/water_product_details_sheet.dart';
import 'water_subscription_screen.dart';
import '../../widgets/app_back_button.dart';
import '../widgets/auto_slide_network_images.dart';

class WaterSupplierDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;

  const WaterSupplierDetailsScreen({super.key, required this.supplier});

  @override
  State<WaterSupplierDetailsScreen> createState() =>
      _WaterSupplierDetailsScreenState();
}

class _WaterSupplierDetailsScreenState
    extends State<WaterSupplierDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool _isFavorite = false;
  bool _showStickySearch = false;
  bool showCartBar = false;
  Map<String, dynamic>? lastAddedItem;

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  /// search bar height (48) + small padding
  static const double _stickyExtent = 56;

  List<Map<String, dynamic>> products = const [];
  bool _productsLoading = true;

  /// Loads this supplier's products from the API (water/categories, then water/items).
  Future<void> _loadProducts() async {
    final vendorId = (widget.supplier['vendorId'] as int?) ?? 0;
    if (vendorId == 0 || !Get.isRegistered<WaterRepository>()) {
      setState(() => _productsLoading = false);
      return;
    }
    try {
      final result = await Get.find<WaterRepository>().fetchSupplierProducts(
        waterVendorId: vendorId,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        products = result;
        _productsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _productsLoading = false);
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadProducts();
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFA59A94),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'pw_find_from_supplier'.tr,
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/images/Voice.png',
                  width: 14,
                  height: 14,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mic_rounded,
                    color: Color(0xFFFF5E00),
                    size: 16,
                  ),
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
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    final supplierName =
        widget.supplier['name'] ??
        widget.supplier['title'] ??
        'PureLife Water Co.';
    final subtitle =
        widget.supplier['subtitle'] ?? 'pw_premium_purified_water'.tr;
    final rating = widget.supplier['rating'] ?? '4.6';
    final time = widget.supplier['time'] ?? '30-35 min';
    final dist = widget.supplier['dist'] ?? '10 Km';
    final discount = widget.supplier['discount'] ?? '50% OFF';
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Stack(
          children: [
            Obx(() {
              final hasItems =
                  controller.cartItemCount.value > 0 || showCartBar;
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: hasItems ? bottomInset + 88 : 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Stack with Banner Image and Overlapping Details Card
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Hero Banner Graphic
                        Container(
                          height: 180,
                          width: double.infinity,
                          color: const Color(0xFF007BFF),
                          child: Image.asset(
                            'lib/assets/images/water Details banner.png',
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF007BFF),
                                    Color(0xFF00C6FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Floating Supplier Details Card
                        Container(
                          margin: const EdgeInsets.only(
                            top: 130,
                            left: 16,
                            right: 16,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title & Green Rating Pill
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      supplierName,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF1A1A1A),
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
                                      color: const Color(0xFF0A8A00),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.white,
                                          size: 13,
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
                              const SizedBox(height: 4),

                              // Subtitle
                              Text(
                                subtitle,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Info Tags Row
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFFFF5E00),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFFFF5E00),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dist,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5E00),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      discount,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Chat with Supplier & Favorite Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => ChatScreen(
                                            restaurant: widget.supplier,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            23,
                                          ),
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
                                              'pw_chat_with_supplier'.tr,
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
                                        color: const Color(0xFFFAF6F0),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFEAD8C9),
                                          width: 1.0,
                                        ),
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
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pins when scrolled: search
                    KeyedSubtree(
                      key: _searchAnchorKey,
                      child: _showStickySearch
                          ? const SizedBox(height: _stickyExtent)
                          : _buildSearchBar(),
                    ),

                    const SizedBox(height: 24),

                    // Products Title Heading
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'pw_products'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2-Column Products Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _productsLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF5E00),
                              ),
                            )
                          : products.isEmpty
                          ? Center(
                              child: Text(
                                'pw_no_products_available'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF6B6B6B),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.68,
                                  ),
                              itemBuilder: (context, index) {
                                final item = products[index];
                                return _buildProductCard(item);
                              },
                            ),
                    ),
                  ],
                ),
              );
            }),

            // Sticky search overlay
            if (_showStickySearch)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 2,
                  color: const Color(0xFFFAF6F0),
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset, bottom: 8),
                    child: _buildSearchBar(),
                  ),
                ),
              ),

            // Floating back button (hidden while sticky is pinned)
            if (!_showStickySearch)
              PositionedDirectional(
                top: topInset + 10,
                start: 16,
                child: AppBackButton(onTap: () => Get.back()),
              ),

            // Floating Cart Summary Bar Popup
            Positioned(
              bottom: bottomInset + 16,
              left: 16,
              right: 16,
              child: Obx(() {
                final hasItems =
                    controller.cartItemCount.value > 0 || showCartBar;
                if (!hasItems) return const SizedBox.shrink();
                return _buildCartBar();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    final readyIn = widget.supplier['time']?.toString() ?? '30-35 min';
    final lastItem =
        lastAddedItem ??
        (Get.isRegistered<HomeController>()
            ? Get.find<HomeController>().lastCartItem
            : null);
    final price = lastItem?['price']?.toString() ?? '50 MRU';
    final title =
        lastItem?['title']?.toString() ??
        lastItem?['itemName']?.toString() ??
        'pw_drinking_water_19l'.tr;
    final portion =
        lastItem?['bottleTag']?.toString() ??
        lastItem?['sizeTag']?.toString() ??
        lastItem?['itemPortion']?.toString() ??
        '19L';
    final image =
        lastItem?['image']?.toString() ?? lastItem?['itemImage']?.toString();

    return GestureDetector(
      onTap: () {
        Get.to(
          () => CartScreen(
            showBottomNav: false,
            storeName:
                widget.supplier['name'] ??
                widget.supplier['title'] ??
                'PureLife Water Co.',
            itemName: title,
            itemPortion: portion,
            basePrice: parsePrice(price),
            itemImage: image,
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
              child: Obx(() {
                final count = Get.isRegistered<HomeController>()
                    ? Get.find<HomeController>().cartItemCount.value
                    : 1;
                final displayCount = count > 0 ? count : 1;
                return Text(
                  '$displayCount',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() {
                    final count = Get.isRegistered<HomeController>()
                        ? Get.find<HomeController>().cartItemCount.value
                        : 1;
                    final displayCount = count > 0 ? count : 1;
                    return Text(
                      'pw_view_cart_items'.trParams({'count': '$displayCount'}),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  Text(
                    'pw_ready_in'.trParams({'time': readyIn}),
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
                  price,
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
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    Future<void> handleAdd() async {
      if (!Get.isRegistered<WaterRepository>()) return;
      final productId = int.tryParse('${item['productId']}') ?? 0;
      if (productId == 0) {
        // Sample items on this screen have no server id, so they can't be ordered yet
        showAppToast(
          'pw_product_not_orderable'.tr,
          backgroundColor: const Color(0xFFEF4444),
        );
        return;
      }
      try {
        // Save the item on the server first; only update the local cart bar after success
        await Get.find<WaterRepository>().addToCart(
          waterVendorId: (widget.supplier['vendorId'] as int?) ?? 0,
          productId: productId,
          language: apiLanguageCode(),
        );
      } on ApiException catch (error) {
        if (!mounted) return;
        showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
        return;
      }
      if (!mounted) return;
      setState(() {
        showCartBar = true;
        lastAddedItem = item;
      });
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().setCartItem(
          storeName:
              widget.supplier['name'] ??
              widget.supplier['title'] ??
              'PureLife Water Co.',
          itemName: item['title']?.toString(),
          itemPortion:
              item['bottleTag']?.toString() ??
              item['sizeTag']?.toString() ??
              '19L',
          basePrice: parsePrice(item['price']?.toString() ?? '50'),
          itemImage: item['image']?.toString(),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'pw_added_to_cart'.trParams({'name': '${item['title']}'}),
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFFFF5E00),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        showWaterProductDetailsSheet(context, item, onAdd: handleAdd);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area Container with Tags
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFFEBF4FE),
                    padding: const EdgeInsets.all(12),
                    child: AutoSlideNetworkImages(
                      images: foodGalleryImages(item),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Discount Tag (Top Left)
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['discount'] as String,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Bottom Tags Overlaid on Image Container
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE6DB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['bottleTag'] as String,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE6DB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['sizeTag'] as String,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Details Area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Rating & Reviews
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item['rating'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['reviews'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price Row
                  Row(
                    children: [
                      Text(
                        item['price'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item['originalPrice'] as String,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Action Buttons (SUBSCRIBE & ADD)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => const WaterSubscriptionScreen());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFF5E00),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'pw_subscribe_caps'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: handleAdd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
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
                                  ).withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'pw_add_caps'.tr,
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
