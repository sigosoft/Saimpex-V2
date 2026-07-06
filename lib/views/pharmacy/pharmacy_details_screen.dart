import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../chat_screen.dart';
import '../messages_screen.dart';
import '../cart_screen.dart';

class PharmacyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const PharmacyDetailsScreen({Key? key, required this.store}) : super(key: key);

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
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
    {'label': 'OTC'},
    {'label': 'Baby Care'},
    {'label': 'Personal Care'},
    {'label': 'Dental Care'},
    {'label': 'Wellness'},
    {'label': 'Vitamins'},
    {'label': 'First Aid'},
    {'label': 'Device'},
  ];

  final List<Map<String, dynamic>> filters = [
    {'label': 'Filter', 'icon': Image.asset("lib/assets/images/Filter.png")},
    {'label': 'OTC Only', 'isOTC': true},
    {'label': 'Offers', 'icon': Image.asset("lib/assets/images/Offer.png")},
    {'label': 'Ratings 4.0+', 'icon': Icons.star_rounded},
  ];

  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Paracetamol 500 Mg',
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=350&auto=format&fit=crop',
      'isVeg': false,
      'tag': '10 Tablets',
      'rating': '4.6',
      'reviews': '10k+ reviews',
      'price': '50 MRU',
      'originalPrice': '100 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Vitamin C 1000mg',
      'image': 'https://images.unsplash.com/photo-1616679911721-ebd6e42582d8?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': '30 Tablets',
      'rating': '4.7',
      'reviews': '5k+ reviews',
      'price': '120 MRU',
      'originalPrice': '240 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Baby Powder 100g',
      'image': 'https://images.unsplash.com/photo-1515488042361-404e9250afef?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'Baby Care',
      'rating': '4.8',
      'reviews': '8k+ reviews',
      'price': '80 MRU',
      'originalPrice': '160 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Toothpaste 100g',
      'image': 'https://images.unsplash.com/photo-1559599101-3098485c4b36?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'Dental Care',
      'rating': '4.5',
      'reviews': '15k+ reviews',
      'price': '45 MRU',
      'originalPrice': '90 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'First Aid Bandages',
      'image': 'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=350&auto=format&fit=crop',
      'isVeg': true,
      'tag': 'First Aid',
      'rating': '4.6',
      'reviews': '4k+ reviews',
      'price': '35 MRU',
      'originalPrice': '70 MRU',
      'discount': '50% OFF',
    },
    {
      'title': 'Digital BP Monitor',
      'image': 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=350&auto=format&fit=crop',
      'isVeg': false,
      'tag': 'Device',
      'rating': '4.9',
      'reviews': '2k+ reviews',
      'price': '1200 MRU',
      'originalPrice': '2400 MRU',
      'discount': '50% OFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final storeId = widget.store['id']?.toString() ?? 'p1';
    final isClosed = widget.store['isClosed'] == true;
    final isTemporarilyClosed = widget.store['isTemporarilyClosed'] == true;
    final isNotAccepting = isClosed || isTemporarilyClosed;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // 1. Background Cover Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Image.network(
              widget.store['image'] ??
                  'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&auto=format&fit=crop',
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

          // 2. Main Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 140),

                  // Floating Info Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.store['title'] ?? 'Pharmacy Store',
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
                          widget.store['subtitle'] ?? 'Trusted Pharmacy',
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

                        // Closed / Temporarily closed banner
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

                        const SizedBox(height: 20),
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
                                        color: const Color(0xFFFF5E00).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        "lib/assets/images/Chat Details.png",
                                        height: 18,
                                        width: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Chat with Pharmacy',
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
                              onTap: () => controller.toggleLike(storeId),
                              child: Obx(() {
                                final liked = controller.isLiked(storeId);
                                return Container(
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
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: const Color(0xFFFF5E00),
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

                  const SizedBox(height: 20),

                  // Horizontal Category Row
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: subcategories.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final sub = subcategories[index];
                          final isAll = sub['isAll'] == true;
                          final isSelected = activeSubcategoryIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                activeSubcategoryIndex = index;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: Column(
                                children: [
                                  isAll
                                      ? Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFFE5102),
                                                      Color(0xFFFFAE00),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : const LinearGradient(
                                                    colors: [
                                                      Color(0xFFA59A94),
                                                      Color(0xFFC0B6B0),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              'lib/assets/images/All.png',
                                              width: 20,
                                              height: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAF5F8),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFFFF5E00)
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          width: 44,
                                          height: 44,
                                          child: Center(
                                            child: Icon(
                                              _getSubIcon(sub['label']),
                                              color: isSelected ? Colors.white : const Color(0xFF00ACC1),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sub['label'] as String,
                                    style: GoogleFonts.outfit(
                                      color: isSelected
                                          ? const Color(0xFFFF5E00)
                                          : const Color(0xFF7A6A60),
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      height: 3,
                                      width: 16,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5E00),
                                        borderRadius: BorderRadius.circular(1.5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Padding(
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
                              decoration: InputDecoration(
                                hintText: 'Find medicines in this store',
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
                            "lib/assets/images/Camera.png",
                            width: 18,
                            height: 18,
                            color: const Color(0xFFA59A94),
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

                  const SizedBox(height: 16),

                  // Horizontal Filter Chips
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        final isOTC = filter['isOTC'] == true;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              if (isOTC) ...[
                                Container(
                                  width: 14,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black26, width: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Container(color: Colors.red)),
                                      Expanded(child: Container(color: Colors.yellow)),
                                    ],
                                  ),
                                ),
                              ] else if (filter['icon'] != null) ...[
                                if (filter['icon'] is IconData)
                                  Icon(
                                    filter['icon'] as IconData,
                                    color: filter['label'] == 'Ratings 4.0+'
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
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu Title Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'All Medicines from This Store',
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
                    child: Column(
                      children: menuItems.map((food) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFoodCard(context, food, isNotAccepting),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
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
          if (showCartBar)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Get.to(
                    () => CartScreen(
                      storeName: widget.store['title'],
                      itemName: lastAddedItem?['title'],
                      itemPortion: lastAddedItemPortion,
                      basePrice: parsePrice(lastAddedItem?['price'] ?? '50'),
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
                            lastAddedItem?['price'] ?? '50 MRU',
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
              ),
            ),
        ],
      ),
    );
  }

  IconData _getSubIcon(String label) {
    if (label == 'OTC') return Icons.vaccines_rounded;
    if (label == 'Baby Care') return Icons.child_care_rounded;
    if (label == 'Personal Care') return Icons.sanitizer_rounded;
    if (label == 'Dental Care') return Icons.health_and_safety_outlined;
    if (label == 'Wellness') return Icons.spa_rounded;
    if (label == 'Vitamins') return Icons.medication_rounded;
    if (label == 'First Aid') return Icons.medical_services_rounded;
    if (label == 'Device') return Icons.monitor_heart_rounded;
    return Icons.category_rounded;
  }

  Widget _buildFoodCard(
    BuildContext context,
    Map<String, dynamic> food,
    bool isNotAccepting,
  ) {
    final isVeg = food['isVeg'] as bool;
    return GestureDetector(
      onTap: () => _showFoodDetailsBottomSheet(context, food, isNotAccepting),
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
                      child: Image.network(
                        food['image']!,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 84,
                          height: 84,
                          color: const Color(0xFFF3EFEA),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                          food['discount']!,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            food['tag']!,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildVegIndicator(isVeg),
                      ],
                    ),
                    Text(
                      food['title']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${food['reviews']})',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              food['price']!,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              food['originalPrice']!,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: const Color(0xFFA59A94),
                                decorationThickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: isNotAccepting
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Pharmacy is currently closed or temporarily not accepting orders.',
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
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isNotAccepting
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFFFF5E00).withOpacity(0.2),
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
                                  isNotAccepting ? 'CLOSED' : 'ADD',
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

  void _showFoodDetailsBottomSheet(
    BuildContext context,
    Map<String, dynamic> food,
    bool isNotAccepting,
  ) {
    bool isLiked = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFDF9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                              'Premium quality medical grade products sourced directly from licensed distributors, ensuring safety, effectiveness, and clean packaging.',
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
                                                  'Pharmacy is currently closed or temporarily not accepting orders.',
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
                                        borderRadius: BorderRadius.circular(23),
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
                                          color: Colors.black.withOpacity(0.04),
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
    int selectedQuantityIndex = 0; // Default to option 1
    int quantity = 1;
    final TextEditingController notesController = TextEditingController();

    // Determine quantity text and price options based on clicked item
    String qtyText1 = '1 Pack';
    String qtyPrice1 = food['price'] ?? '50 MRU';
    String qtyText2 = '3 Packs';
    String qtyPrice2 = '140 MRU';

    final title = food['title'] as String;
    if (title.contains('Vitamin')) {
      qtyText1 = '30 Tablets';
      qtyPrice1 = '120 MRU';
      qtyText2 = '90 Tablets';
      qtyPrice2 = '320 MRU';
    } else if (title.contains('Powder')) {
      qtyText1 = '100 g';
      qtyPrice1 = '80 MRU';
      qtyText2 = '500 g';
      qtyPrice2 = '350 MRU';
    } else if (title.contains('Toothpaste')) {
      qtyText1 = '100 g';
      qtyPrice1 = '45 MRU';
      qtyText2 = '3 tubes';
      qtyPrice2 = '120 MRU';
    } else if (title.contains('Bandages')) {
      qtyText1 = 'Pack of 20';
      qtyPrice1 = '35 MRU';
      qtyText2 = 'Pack of 100';
      qtyPrice2 = '150 MRU';
    } else if (title.contains('BP Monitor')) {
      qtyText1 = '1 Unit';
      qtyPrice1 = '1200 MRU';
      qtyText2 = '2 Units';
      qtyPrice2 = '2200 MRU';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: selectedQuantityIndex == 0
                                              ? const Color(0xFFFFF0EA)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: selectedQuantityIndex == 0
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAD8C9),
                                            width: selectedQuantityIndex == 0 ? 1.5 : 0.8,
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
                                                  color: selectedQuantityIndex == 0
                                                      ? const Color(0xFFFF5E00)
                                                      : const Color(0xFFA59A94),
                                                  width: 1.5,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(3),
                                              child: selectedQuantityIndex == 0
                                                  ? Container(
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFFFF5E00),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  qtyText1,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFF2C2520),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  qtyPrice1,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFFFF5E00),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: selectedQuantityIndex == 1
                                              ? const Color(0xFFFFF0EA)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: selectedQuantityIndex == 1
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAD8C9),
                                            width: selectedQuantityIndex == 1 ? 1.5 : 0.8,
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
                                                  color: selectedQuantityIndex == 1
                                                      ? const Color(0xFFFF5E00)
                                                      : const Color(0xFFA59A94),
                                                  width: 1.5,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(3),
                                              child: selectedQuantityIndex == 1
                                                  ? Container(
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFFFF5E00),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  qtyText2,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFF2C2520),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  qtyPrice2,
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFFFF5E00),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                          hintText: 'Add notes (e.g, verify expiry date for ${title.toLowerCase()}...)',
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                    lastAddedItem = Map<String, dynamic>.from(food);
                                    lastAddedItem!['price'] = (selectedQuantityIndex == 0) ? qtyPrice1 : qtyPrice2;
                                    lastAddedItemPortion = (selectedQuantityIndex == 0) ? qtyText1 : qtyText2;
                                    showCartBar = true;
                                  });

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
                                        color: const Color(0xFFFF5E00).withOpacity(0.3),
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
}
