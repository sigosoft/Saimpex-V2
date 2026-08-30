import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../chat_screen.dart';
import '../cart_screen.dart';
import 'upload_prescription_screen.dart';
import 'widgets/pharmacy_cart_bar.dart';
import 'widgets/pharmacy_customize_sheet.dart';
import 'widgets/pharmacy_product_card.dart';
import 'widgets/pharmacy_product_details_sheet.dart';
import 'widgets/pharmacy_subcategory_icon.dart';

class PharmacyItemsScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const PharmacyItemsScreen({super.key, required this.store});

  @override
  State<PharmacyItemsScreen> createState() => _PharmacyItemsScreenState();
}

class _PharmacyItemsScreenState extends State<PharmacyItemsScreen> {
  int activeSubcategoryIndex = 0;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool showCartBar = false;
  bool _showStickySearch = false;
  Map<String, dynamic>? lastAddedItem;
  String? lastAddedItemPortion;

  /// categories(~80) + gap(6) + search(40) + padding ≈ 130
  static const double _searchFiltersExtent = 130;

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

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  Widget _buildSubcategoriesRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.only(top: 2),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF8),
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: subcategories.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          itemBuilder: (context, index) {
            final sub = subcategories[index];
            final isAll = sub['isAll'] == true;
            final isSelected = activeSubcategoryIndex == index;
            final iconPath = sub['icon'] as String?;

            return GestureDetector(
              onTap: () {
                setState(() {
                  activeSubcategoryIndex = index;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == subcategories.length - 1 ? 0 : 8,
                ),
                child: SizedBox(
                  width: 56,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Column(
                        children: [
                          isAll
                              ? SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: Image.asset(
                                      'lib/assets/images/All.png',
                                      width: 20,
                                      height: 20,
                                      color: const Color(0xFFFF5E00),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: iconPath != null
                                      ? Center(
                                          child: Image.asset(
                                            iconPath,
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : Icon(
                                          pharmacySubcategoryIcon(
                                            sub['label'] as String,
                                          ),
                                          color: const Color(0xFF00ACC1),
                                          size: 16,
                                        ),
                                ),
                          const SizedBox(height: 4),
                          Text(
                            sub['label'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? const Color(0xFFFF5E00)
                                  : const Color(0xFF3A312C),
                              fontSize: 10,
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
                            height: 8,
                            width: 44,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
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
                  hintText: 'Search items',
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
              width: 24,
              height: 24,
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
    );
  }

  Widget _buildStickySection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubcategoriesRow(),
        const SizedBox(height: 6),
        _buildSearchBar(),
      ],
    );
  }

  final List<Map<String, dynamic>> subcategories = [
    {'label': 'All', 'isAll': true},
    {'label': 'OTC', 'icon': 'lib/assets/images/pill.png'},
    {'label': 'Baby Care', 'icon': 'lib/assets/images/BabyCare.png'},
    {'label': 'Personal Care', 'icon': 'lib/assets/images/PersonalCare.png'},
    {'label': 'Dental Care', 'icon': 'lib/assets/images/DentalCare.png'},
    {'label': 'Wellness', 'icon': 'lib/assets/images/Welness.png'},
    {'label': 'Vitamins', 'icon': 'lib/assets/images/Vitamins.png'},
    {'label': 'First Aid', 'icon': 'lib/assets/images/FirstAid.png'},
    {'label': 'Device', 'icon': 'lib/assets/images/Device.png'},
  ];

  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Paracetamol 500 Mg',
      'image':
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=350&auto=format&fit=crop',
      'tag': '10 Tablets',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '500 MRU',
      'originalPrice': '1,000 MRU',
      'discount': '50% OFF',
      'description':
          'Paracetamol is commonly used to reduce fever and relieve mild to moderate pain such as headaches, muscle aches, toothache, and cold-related discomfort. It works by blocking pain signals in the brain and helping regulate body temperature.',
    },
    {
      'title': 'Adhesive Bandages',
      'image':
          'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=350&auto=format&fit=crop',
      'tag': '20 Pieces • Waterproof',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '500 MRU',
      'originalPrice': '1,000 MRU',
      'discount': '50% OFF',
      'description':
          'Flexible waterproof adhesive bandages that protect minor cuts and scrapes. Soft padding cushions the wound while the adhesive stays secure during daily activity.',
    },
    {
      'title': 'Digital Thermometer',
      'image':
          'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=350&auto=format&fit=crop',
      'tag': 'Accurate Reading',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '500 MRU',
      'originalPrice': '1,000 MRU',
      'discount': '50% OFF',
      'description':
          'Fast and accurate digital thermometer for home use. Easy-read display and reliable temperature measurement for adults and children.',
    },
    {
      'title': 'Baby Diapers',
      'image':
          'https://images.unsplash.com/photo-1716972065448-e08a46809530?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'Soft & Absorbent',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '500 MRU',
      'originalPrice': '1,000 MRU',
      'discount': '50% OFF',
      'description':
          'Soft, highly absorbent baby diapers designed for all-day comfort. Leak-lock core keeps baby dry while gentle materials protect sensitive skin.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final storeId = widget.store['id']?.toString() ?? 'p1';
    final isClosed = widget.store['isClosed'] == true;
    final isTemporarilyClosed = widget.store['isTemporarilyClosed'] == true;
    final isNotAccepting = isClosed || isTemporarilyClosed;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEADF),
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
                          child: Image.network(
                            widget.store['image'] ??
                                'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            width: double.infinity,
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
                                    color: Colors.black.withOpacity(0.06),
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
                                          widget.store['title'] ??
                                              'Pharmacy Store',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
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
                                              color: Color(0xFFFFAE00),
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              widget.store['rating'] ?? '4.6',
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
                                    widget.store['subtitle'] ??
                                        'Trusted Pharmacy',
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
                                        widget.store['time'] ?? '30-35 min',
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
                                        widget.store['dist'] ?? '10 Km',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5E00),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          widget.store['discount'] ?? '50% OFF',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
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
                                                  ? 'Temporarily not accepting orders'
                                                  : 'Currently Closed',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFFEF4444),
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
                                                  'title':
                                                      widget.store['title'] ??
                                                      'Pharmacy Nasr',
                                                  'image':
                                                      widget.store['image'] ??
                                                      'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=150&auto=format&fit=crop',
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
                                                  'Chat with Pharmacy',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
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
                                          widget.store,
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
                                      initialPharmacy: widget.store['title']
                                          ?.toString(),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                        'Upload Your Prescription',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF006064),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
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
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'All Items from This Pharmacy',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

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
                              mainAxisExtent: 220,
                            ),
                        itemBuilder: (context, index) {
                          final food = menuItems[index];
                          return PharmacyProductCard(
                            food: food,
                            isNotAccepting: isNotAccepting,
                            onTap: () => showPharmacyProductDetailsSheet(
                              context,
                              food: food,
                              isNotAccepting: isNotAccepting,
                              onAdd: () {
                                setState(() {
                                  showCartBar = true;
                                  lastAddedItem = food;
                                  lastAddedItemPortion = food['tag'] as String?;
                                });
                                if (Get.isRegistered<HomeController>()) {
                                  Get.find<HomeController>().setCartItem(
                                    storeName:
                                        widget.store['title']?.toString() ??
                                        'Pharmacy Nasr',
                                    itemName: food['title']?.toString(),
                                    itemPortion:
                                        food['tag']?.toString() ?? '10 Tablets',
                                    basePrice: parsePrice(
                                      food['price']?.toString() ?? '50',
                                    ),
                                    itemImage: food['image']?.toString(),
                                  );
                                }
                              },
                            ),
                            onAdd: () => showPharmacyCustomizeSheet(
                              context,
                              food: food,
                              fromBottomSheet: false,
                              onAdded: (item, portion) {
                                setState(() {
                                  lastAddedItem = item;
                                  lastAddedItemPortion = portion;
                                  showCartBar = true;
                                });
                                if (Get.isRegistered<HomeController>()) {
                                  Get.find<HomeController>().setCartItem(
                                    storeName:
                                        widget.store['title']?.toString() ??
                                        'Pharmacy Nasr',
                                    itemName:
                                        item['title']?.toString() ??
                                        food['title']?.toString(),
                                    itemPortion: portion,
                                    basePrice: parsePrice(
                                      item['price']?.toString() ??
                                          food['price']?.toString() ??
                                          '50',
                                    ),
                                    itemImage:
                                        item['image']?.toString() ??
                                        food['image']?.toString(),
                                  );
                                }
                              },
                            ),
                          );
                        },
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
                color: const Color(0xFFFFEADF),
                child: Padding(
                  padding: EdgeInsets.only(top: topInset, bottom: 8),
                  child: _buildStickySection(),
                ),
              ),
            ),
          // 3. Floating Back Button
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
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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

          // 4. Floating Cart Summary Bar
          Positioned(
            bottom: bottomInset + 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final hasItems = controller.cartItemCount.value > 0;
              if (!hasItems) return const SizedBox.shrink();
              return PharmacyCartBar(
                price: lastAddedItem?['price'] ?? '50 MRU',
                onTap: () {
                  Get.to(
                    () => CartScreen(
                      showBottomNav: false,
                      storeName: widget.store['title'],
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
    );
  }
}
