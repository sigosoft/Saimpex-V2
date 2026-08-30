import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../messages_screen.dart';
import '../cart_screen.dart';

class GroceryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const GroceryDetailsScreen({Key? key, required this.store}) : super(key: key);

  @override
  State<GroceryDetailsScreen> createState() => _GroceryDetailsScreenState();
}

class _GroceryDetailsScreenState extends State<GroceryDetailsScreen> {
  int activeSubcategoryIndex = 0;
  final TextEditingController searchController = TextEditingController();
  bool showCartBar = false;
  Map<String, dynamic>? lastAddedItem;
  String? lastAddedItemPortion;

  int parsePrice(String priceStr) {
    final clean = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  final List<Map<String, dynamic>> subcategories = [
    {'label': 'All', 'isAll': true},
    {
      'label': 'Fruits',
      'image':
          'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Vegetables',
      'image':
          'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Meat',
      'image':
          'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Masalas',
      'image':
          'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=100&auto=format&fit=crop',
    },
    {
      'label': 'Rice',
      'image':
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=100&auto=format&fit=crop',
    },
  ];

  final List<Map<String, dynamic>> filters = [
    {'label': 'Filter', 'icon': Image.asset("lib/assets/images/Filter.png")},
    {'label': 'Under 200 MRU', 'isMru': true},
    {'label': 'Offers', 'icon': Image.asset("lib/assets/images/Offer.png")},
    {'label': 'Rating', 'icon': Icons.star_rounded},
  ];

  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Whole Milk 1L',
      'image':
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'Dairy',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Tomato',
      'image':
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'Veg',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Potato',
      'image':
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'Veg',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Banana',
      'image':
          'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'Fruits',
      'rating': '4.6',
      'reviews': '10k + reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final storeId = widget.store['id']?.toString() ?? 'g1';
    final isClosed =
        widget.store['isClosed'] == true || widget.store['isClosed'] == 'true';
    final isTemporarilyClosed =
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
            child: Column(
              children: [
                Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topInset + 132,
                      child: Image.network(
                        widget.store['image'] ??
                            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
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
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.store['name'] ?? 'Store',
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
                              const SizedBox(height: 4),
                              Text(
                                widget.store['category'] ?? 'Grocery',
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
                                    widget.store['time'] ?? '30-35 min',
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
                                    widget.store['dist'] ?? '10 Km',
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
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      widget.store['discount'] ?? '30% OFF',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                                            restaurant: widget.store,
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
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
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
                                      widget.store,
                                    ),
                                    child: Obx(() {
                                      final liked = controller.isLiked(storeId);
                                      return Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
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
                        ),

                        const SizedBox(height: 8),

                        Padding(
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
                                      hintText:
                                          'Find something from this Store',
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
                        ),
                        const SizedBox(height: 8),

                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 8, 0, 10),
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
                              itemCount: subcategories.length,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
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
                                      right: index == subcategories.length - 1
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
                                                            shape:
                                                                BoxShape.circle,
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
                                                          sub['image']
                                                              as String,
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
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 32,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filters.length,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final filter = filters[index];
                              final isMru = filter['isMru'] == true;
                              return GestureDetector(
                                onTap: () {
                                  if (filter['label'] == 'Filter') {
                                    _showFilterBottomSheet();
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFEAD8C9),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isMru) ...[
                                        Image.asset(
                                          'lib/assets/images/currency.png',
                                          width: 12,
                                          height: 12,
                                          color: const Color(0xFFFF5E00),
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Image.asset(
                                                'lib/assets/images/Coin.png',
                                                width: 12,
                                                height: 12,
                                              ),
                                        ),
                                      ] else if (filter['icon'] != null) ...[
                                        if (filter['icon'] is IconData)
                                          Icon(
                                            filter['icon'] as IconData,
                                            color: filter['label'] == 'Rating'
                                                ? const Color(0xFFFFAE00)
                                                : const Color(0xFF7A6A60),
                                            size: 14,
                                          )
                                        else if (filter['icon'] is Widget)
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: filter['icon'] as Widget,
                                          ),
                                      ],
                                      const SizedBox(width: 6),
                                      Text(
                                        filter['label'] as String,
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
                        ),
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
                          _buildSmartBundleCard(context, isNotAccepting),
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
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // 3. Floating Back Button
          Positioned(
            top: topInset + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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

  Widget _buildSmartBundleCard(BuildContext context, bool isNotAccepting) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  'Special Bundle',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Milk 1L • Eggs • Bread • Yogurt',
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
                      '750 MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '1500 MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFFA59A94),
                      ),
                    ),
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
                        'title': 'Special Bundle',
                        'price': '750 MRU',
                        'image': widget.store['image'],
                      };
                      lastAddedItemPortion = 'Bundle';
                    });
                    if (Get.isRegistered<HomeController>()) {
                      Get.find<HomeController>().setCartItem(
                        storeName: widget.store['name']?.toString() ?? 'Grocery Store',
                        itemName: 'Special Bundle',
                        itemPortion: 'Bundle',
                        basePrice: 750,
                        itemImage: widget.store['image']?.toString(),
                      );
                    }
                  },
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isNotAccepting
                    ? const Color(0xFFA59A94)
                    : const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 12,
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
                    child: Image.network(
                      food['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF3EFEA),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
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
                        food['discount']!,
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
                      food['title']!,
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
                          food['rating']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '(${food['reviews']})',
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
                      food['originalPrice']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFFA59A94),
                      ),
                    ),
                    Text(
                      food['price']!,
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
                          child: Image.network(
                            food['image']!,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 240,
                                  color: const Color(0xFFF3EFEA),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
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
                                food['title']!,
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
                                  food['tag']!,
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
                                    food['price']!,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5E00),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    food['originalPrice']!,
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
                                    '${food['rating']!} (${food['reviews']!})',
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
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

    final title = food['title'] as String;
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
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: notesController,
                                        maxLines: 1,
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
                                      width: 28,
                                      height: 28,
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
                                      width: 28,
                                      height: 28,
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
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Color(0xFFFF5E00),
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
                                      storeName: widget.store['name']?.toString() ?? 'Grocery Store',
                                      itemName: lastAddedItem?['title']?.toString(),
                                      itemPortion: lastAddedItemPortion,
                                      basePrice: parsePrice(lastAddedItem?['price']?.toString() ?? '65'),
                                      itemImage: lastAddedItem?['image']?.toString(),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
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
