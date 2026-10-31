import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_back_button.dart';

import '../../controllers/home_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/water_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../cart_screen.dart';
import '../chat_screen.dart';
import 'water_product_subscription_screen.dart';
import 'widgets/water_product_card.dart';
import 'widgets/water_product_details_sheet.dart';

class WaterSupplierScreen extends StatefulWidget {
  final Map<String, dynamic> supplier;

  const WaterSupplierScreen({super.key, required this.supplier});

  @override
  State<WaterSupplierScreen> createState() => _WaterSupplierScreenState();
}

class _WaterSupplierScreenState extends State<WaterSupplierScreen> {
  final TextEditingController searchController = TextEditingController();
  bool showCartBar = false;
  Map<String, dynamic>? lastAddedItem;

  List<Map<String, dynamic>> products = const [];
  bool _productsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

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

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    final supplierId = widget.supplier['id']?.toString() ?? 'w1';
    final isClosed = widget.supplier['isClosed'] == true;
    final isTemporarilyClosed = widget.supplier['isTemporarilyClosed'] == true;
    final isNotAccepting = isClosed || isTemporarilyClosed;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final headerImage =
        (widget.supplier['headerImage'] ??
                widget.supplier['cardImage'] ??
                'lib/assets/images/19Lbottle.png')
            .toString();

    return Scaffold(
      backgroundColor: const Color(0xFFFFEADF),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeaderSection(
                  controller,
                  supplierId,
                  headerImage,
                  isNotAccepting,
                  isTemporarilyClosed,
                  topInset,
                ),
              ),
              Obx(() {
                final hasItems = controller.cartItemCount.value > 0;
                if (_productsLoading) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF5E00),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    hasItems ? bottomInset + 88 : 24,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 210,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      return WaterProductCard(
                        product: product,
                        isNotAccepting: isNotAccepting,
                        onTap: () =>
                            showWaterProductDetailsSheet(context, product),
                        onSubscribe: () {
                          Get.to(
                            () => WaterProductSubscriptionScreen(
                              product: Map<String, dynamic>.from(product),
                              supplier: Map<String, dynamic>.from(
                                widget.supplier,
                              ),
                            ),
                          );
                        },
                        onAdd: () async {
                          if (!Get.isRegistered<WaterRepository>()) return;
                          if ((int.tryParse('${product['productId']}') ?? 0) ==
                              0) {
                            // Sample items on this screen have no server id, so they can't be ordered yet
                            showAppToast(
                              'pw_product_not_orderable'.tr,
                              backgroundColor: const Color(0xFFEF4444),
                            );
                            return;
                          }
                          try {
                            // Save the item on the server first; only then update the cart bar
                            await Get.find<WaterRepository>().addToCart(
                              waterVendorId:
                                  (widget.supplier['vendorId'] as int?) ?? 0,
                              productId:
                                  int.tryParse('${product['productId']}') ?? 0,
                              language: apiLanguageCode(),
                            );
                          } on ApiException catch (error) {
                            if (!mounted) return;
                            showAppToast(
                              error.message,
                              backgroundColor: const Color(0xFFEF4444),
                            );
                            return;
                          }
                          if (!mounted) return;
                          setState(() {
                            showCartBar = true;
                            lastAddedItem = product;
                          });
                          if (Get.isRegistered<HomeController>()) {
                            Get.find<HomeController>().setCartItem(
                              storeName:
                                  widget.supplier['title']?.toString() ??
                                  'PureLife Water Co.',
                              itemName: product['title']?.toString(),
                              itemPortion: product['size']?.toString(),
                              basePrice: parsePrice(
                                product['price']?.toString() ?? '50',
                              ),
                              itemImage: product['image']?.toString(),
                            );
                          }
                        },
                      );
                    }, childCount: products.length),
                  ),
                );
              }),
            ],
          ),
          PositionedDirectional(
            top: topInset + 10,
            start: 16,
            child: AppBackButton(onTap: () => Navigator.pop(context)),
          ),
          Positioned(
            bottom: bottomInset + 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final hasItems = controller.cartItemCount.value > 0;
              if (!hasItems) return const SizedBox.shrink();
              return _buildCartBar();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    HomeController controller,
    String supplierId,
    String headerImage,
    bool isNotAccepting,
    bool isTemporarilyClosed,
    double topInset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: topInset + 200,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topInset + 160,
                child: headerImage.startsWith('http')
                    ? Image.network(
                        headerImage,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackHeader(),
                      )
                    : Image.asset(
                        headerImage,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackHeader(),
                      ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: _buildSupplierInfoCard(
                  controller,
                  supplierId,
                  isNotAccepting,
                  isTemporarilyClosed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
                    style: GoogleFonts.outfit(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'pw_find_from_supplier'.tr,
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0EA),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'lib/assets/images/Voice.png',
                      width: 12,
                      height: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'pw_products'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B4F8A), Color(0xFF1BA4B8)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            end: -20,
            bottom: -10,
            child: Image.asset(
              'lib/assets/images/19Lbottle.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.water_drop_outlined,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
          PositionedDirectional(
            start: 40,
            top: 40,
            child: Icon(
              Icons.water_drop,
              size: 48,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfoCard(
    HomeController controller,
    String supplierId,
    bool isNotAccepting,
    bool isTemporarilyClosed,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.supplier['title']?.toString() ??
                      'pw_water_supplier'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B25C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFAE00),
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      widget.supplier['rating']?.toString() ?? '4.6',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.supplier['subtitle']?.toString() ??
                'pw_premium_purified_water'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFFFF5E00),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                widget.supplier['time']?.toString() ?? '30-35 min',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7A6A60),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFFF5E00),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                widget.supplier['dist']?.toString() ?? '10 Km',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7A6A60),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.supplier['discount']?.toString() ?? '50% OFF',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (isNotAccepting) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
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
                          ? 'pw_temporarily_not_accepting_orders'.tr
                          : 'pw_currently_closed'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
                          'title':
                              widget.supplier['title'] ?? 'PureLife Water Co.',
                          'image': headerImageForChat(),
                        },
                      ),
                    );
                  },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/images/Chat Details.png',
                          height: 16,
                          width: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'pw_chat_with_supplier'.tr,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => controller.toggleLike(supplierId, widget.supplier),
                child: Obx(() {
                  final liked = controller.isLiked(supplierId);
                  return Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEAD8C9),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
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
    );
  }

  String headerImageForChat() {
    final image =
        (widget.supplier['headerImage'] ??
                widget.supplier['cardImage'] ??
                widget.supplier['image'])
            ?.toString();
    if (image != null && image.startsWith('http')) return image;
    return 'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=150&auto=format&fit=crop';
  }

  Widget _buildCartBar() {
    final readyIn = widget.supplier['time']?.toString() ?? '30-35 min';
    final price = lastAddedItem?['price']?.toString() ?? '50 MRU';

    return GestureDetector(
      onTap: () {
        Get.to(
          () => CartScreen(
            showBottomNav: false,
            storeName: widget.supplier['title']?.toString(),
            itemName: lastAddedItem?['title']?.toString(),
            itemPortion: lastAddedItem?['size']?.toString(),
            basePrice: parsePrice(lastAddedItem?['price']?.toString() ?? '50'),
            itemImage: lastAddedItem?['image']?.toString(),
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
                '1',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
                    'pw_view_cart_items'.trParams({'count': '1'}),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                    fontWeight: FontWeight.w800,
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
}
