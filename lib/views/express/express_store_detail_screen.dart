import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import 'express_cart_screen.dart';
import '../messages_screen.dart';
import 'widgets/express_filter_sheet.dart';
import 'widgets/express_product_sheets.dart';

class ExpressStoreDetailScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const ExpressStoreDetailScreen({super.key, required this.store});

  @override
  State<ExpressStoreDetailScreen> createState() =>
      _ExpressStoreDetailScreenState();
}

class _ExpressStoreDetailScreenState extends State<ExpressStoreDetailScreen> {
  int activeCategoryIndex = 0;
  bool showCartBar = false;
  Map<String, dynamic>? lastAddedItem;
  String? lastAddedItemPortion;

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  final categories = [
    {'label': 'All', 'isAll': true},
    {
      'label': 'Fruits & Veg',
      'image': 'lib/assets/images/Fruits & Veg.png',
      'isAsset': true,
    },
    {
      'label': 'Snacks',
      'image': 'lib/assets/images/Snacks.png',
      'isAsset': true,
    },
    {
      'label': 'Beverages',
      'image':
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Dairy & Eggs',
      'image':
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=100&auto=format&fit=crop',
    },
  ];

  final filters = [
    {'label': 'Filter', 'icon': 'lib/assets/images/Filter.png'},
    {'label': 'Under 200 MRU', 'isMru': true},
    {'label': 'Offers', 'icon': 'lib/assets/images/Offer.png'},
    {'label': 'Rating', 'isRating': true},
  ];

  final products = [
    {
      'title': 'Whole Milk 1L',
      'image':
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=350&auto=format&fit=crop',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
      'tag': 'Fresh',
      'description':
          'Fresh whole milk sourced from trusted local farms, perfect for daily nutrition, cooking, and beverages.',
    },
    {
      'title': 'Tomato 1Kg',
      'image':
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=350&auto=format&fit=crop',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
      'tag': 'Fresh',
      'description':
          'Ripe, juicy tomatoes picked at peak freshness — ideal for salads, sauces, curries, and everyday cooking.',
    },
    {
      'title': 'Potato 1Kg',
      'image':
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=350&auto=format&fit=crop',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
      'tag': 'Fresh',
      'description':
          'Our farm-fresh potatoes are harvested with care to deliver superior quality, freshness, and flavor. Whether you\'re making crispy fries, creamy mashed potatoes, curries, soups, or baked dishes, these potatoes are a reliable choice for every kitchen.',
    },
    {
      'title': 'Banana 1Kg',
      'image':
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=350&auto=format&fit=crop',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
      'tag': 'Fresh',
      'description':
          'Sweet, ripe bananas packed with natural energy — great for snacking, smoothies, and breakfast bowls.',
    },
  ];

  String get storeName =>
      (widget.store['name'] ?? widget.store['title'] ?? 'Freshmart').toString();

  String get storeImage =>
      (widget.store['image'] ??
              'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop')
          .toString();

  String get storeTime => (widget.store['time'] ?? '35 min').toString();

  String get storeDist => (widget.store['dist'] ?? '10 Km').toString();

  String get storeRating => (widget.store['rating'] ?? '4.6').toString();

  String get storeDiscount =>
      (widget.store['discount'] ?? '50% OFF').toString();

  String get storeId => (widget.store['id'] ?? 'express_store').toString();

  bool get isAssetImage => storeImage.startsWith('lib/');

  void _onProductAdded(
    Map<String, dynamic> product,
    String portion,
    String price,
  ) {
    setState(() {
      lastAddedItem = Map<String, dynamic>.from(product);
      lastAddedItem!['price'] = price;
      lastAddedItemPortion = portion;
      showCartBar = true;
    });
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().setCartItem(
        storeName: storeName,
        itemName: product['title']?.toString(),
        itemPortion: portion,
        basePrice: parsePrice(price),
        itemImage: product['image']?.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEADF),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topInset + 132,
                      child: isAssetImage
                          ? Image.asset(
                              storeImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _headerFallback(),
                            )
                          : Image.network(
                              storeImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _headerFallback(),
                            ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: topInset + 56),
                        _buildStoreInfoCard(controller),
                        const SizedBox(height: 8),
                        _buildSearchBar(),
                        const SizedBox(height: 8),
                        _buildCategoriesRow(),
                        const SizedBox(height: 12),
                        _buildFiltersRow(),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Obx(() {
                    final hasItems = controller.cartItemCount.value > 0;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: hasItems ? bottomInset + 88 : 24,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'All Items from This Store',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: 248,
                                  ),
                              itemBuilder: (_, index) =>
                                  _buildProductCard(products[index]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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

  Widget _headerFallback() {
    return Container(
      color: const Color(0xFFF3EFEA),
      child: const Icon(
        Icons.storefront_outlined,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  Widget _buildStoreInfoCard(HomeController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  storeName,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 18,
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
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      storeRating,
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
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  storeDiscount,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Get.to(
                      () => MessagesScreen(
                        restaurant: {
                          'title': storeName,
                          'name': storeName,
                          'image': storeImage,
                        },
                      ),
                    );
                  },
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/images/Chat Details.png',
                          height: 18,
                          width: 18,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chat with Store',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => controller.toggleLike(storeId, widget.store),
                child: Obx(() {
                  final liked = controller.isLiked(storeId);
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
            Image.asset(
              'lib/assets/images/Camera.png',
              width: 18,
              height: 18,
              color: const Color(0xFFA59A94),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFFA59A94),
                size: 18,
              ),
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
                  'lib/assets/images/Voice.png',
                  width: 14,
                  height: 14,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFFFF5E00),
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isAll = cat['isAll'] == true;
            final isSelected = activeCategoryIndex == index;
            final isAsset = cat['isAsset'] == true;

            return GestureDetector(
              onTap: () => setState(() => activeCategoryIndex = index),
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == categories.length - 1 ? 0 : 10,
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
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.grid_view_rounded,
                                        color: Color(0xFFFF5E00),
                                        size: 22,
                                      ),
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
                                    child: isAsset
                                        ? Image.asset(
                                            cat['image'] as String,
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _catFallback(),
                                          )
                                        : Image.network(
                                            cat['image'] as String,
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _catFallback(),
                                          ),
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label'] as String,
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

  Widget _catFallback() {
    return Container(
      width: 46,
      height: 46,
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.shopping_basket_outlined,
        size: 18,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildFiltersRow() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isMru = filter['isMru'] == true;
          final isRating = filter['isRating'] == true;
          final iconPath = filter['icon'] as String?;

          return GestureDetector(
            onTap: () {
              if (filter['label'] == 'Filter') {
                showExpressFilterSheet(context);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMru) ...[
                    Image.asset(
                      'lib/assets/images/Coin.png',
                      width: 12,
                      height: 12,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFF5E00),
                        size: 12,
                      ),
                    ),
                  ] else if (isRating) ...[
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFAE00),
                      size: 14,
                    ),
                  ] else if (iconPath != null) ...[
                    Image.asset(
                      iconPath,
                      width: 14,
                      height: 14,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.tune_rounded, size: 14),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    filter['label'].toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        showExpressProductDetailSheet(
          context,
          product: product,
          onAdded: _onProductAdded,
        );
      },
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
                    child: Image.network(
                      product['image'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF3EFEA),
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
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
                        product['discount'].toString(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
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
                      product['title'].toString(),
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
                          product['rating'].toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '(${product['reviews']})',
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
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          product['price'].toString(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            showExpressProductCustomizeSheet(
                              context,
                              product: product,
                              onAdded: _onProductAdded,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                    fontWeight: FontWeight.w800,
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

  Widget _buildCartBar() {
    final readyIn = storeTime.contains('min') ? storeTime : '$storeTime min';
    final price = lastAddedItem?['price']?.toString() ?? '50 MRU';

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ExpressCartScreen(
            storeName: storeName,
            itemName: lastAddedItem?['title']?.toString(),
            itemPortion: lastAddedItemPortion,
            basePrice: parsePrice(price),
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
                    'View Cart • 1 items',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Ready in $readyIn',
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
