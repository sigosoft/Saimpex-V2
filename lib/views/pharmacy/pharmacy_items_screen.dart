import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../messages_screen.dart';
import '../cart_screen.dart';
import 'upload_prescription_screen.dart';

class PharmacyItemsScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const PharmacyItemsScreen({super.key, required this.store});

  @override
  State<PharmacyItemsScreen> createState() => _PharmacyItemsScreenState();
}

class _PharmacyItemsScreenState extends State<PharmacyItemsScreen> {
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
      'isVeg': false,
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
      'isVeg': true,
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
      'isVeg': false,
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
          // 2. 50% header / 50% products
          Positioned.fill(
            child: Column(
              children: [
                // Top 50%: store card, upload, categories, search, title
                Expanded(
                  flex: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
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
                          SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Leave room for status bar + back button
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                  color: const Color(
                                                    0xFF2C2520,
                                                  ),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00B25C),
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                                                    widget.store['rating'] ??
                                                        '4.6',
                                                    style: GoogleFonts.outfit(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                              widget.store['time'] ??
                                                  '30-35 min',
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF5E00),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                widget.store['discount'] ??
                                                    '50% OFF',
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                      color: const Color(
                                                        0xFFEF4444,
                                                      ),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                    () => MessagesScreen(
                                                      restaurant: widget.store,
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          colors: [
                                                            Color(0xFFFF5E00),
                                                            Color(0xFFFFAE00),
                                                          ],
                                                          begin: Alignment
                                                              .centerLeft,
                                                          end: Alignment
                                                              .centerRight,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          19,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        "lib/assets/images/Chat Details.png",
                                                        height: 16,
                                                        width: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        'Chat with Pharmacy',
                                                        style:
                                                            GoogleFonts.outfit(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            GestureDetector(
                                              onTap: () =>
                                                  controller.toggleLike(
                                                    storeId,
                                                    widget.store,
                                                  ),
                                              child: Obx(() {
                                                final liked = controller
                                                    .isLiked(storeId);
                                                return Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFEAD8C9,
                                                      ),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    liked
                                                        ? Icons.favorite_rounded
                                                        : Icons
                                                              .favorite_border_rounded,
                                                    color: liked
                                                        ? const Color(
                                                            0xFFFF5E00,
                                                          )
                                                        : const Color(
                                                            0xFFA59A94,
                                                          ),
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
                                            initialPharmacy:
                                                widget.store['title']
                                                    ?.toString(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCBEFF4),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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

                                  // Horizontal Category Row
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.only(top: 2),
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFFCF8),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(18),
                                      ),
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
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          2,
                                          12,
                                          0,
                                        ),
                                        itemBuilder: (context, index) {
                                          final sub = subcategories[index];
                                          final isAll = sub['isAll'] == true;
                                          final isSelected =
                                              activeSubcategoryIndex == index;
                                          final iconPath =
                                              sub['icon'] as String?;

                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                activeSubcategoryIndex = index;
                                              });
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right:
                                                    index ==
                                                        subcategories.length - 1
                                                    ? 0
                                                    : 8,
                                              ),
                                              child: SizedBox(
                                                width: 56,
                                                child: Stack(
                                                  alignment:
                                                      Alignment.topCenter,
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
                                                                    color: const Color(
                                                                      0xFFFF5E00,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            : Container(
                                                                width: 40,
                                                                height: 40,
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Colors
                                                                      .white,
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                            0.08,
                                                                          ),
                                                                      blurRadius:
                                                                          6,
                                                                      offset:
                                                                          const Offset(
                                                                            0,
                                                                            2,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                clipBehavior: Clip
                                                                    .antiAlias,
                                                                child:
                                                                    iconPath !=
                                                                        null
                                                                    ? Center(
                                                                        child: Image.asset(
                                                                          iconPath,
                                                                          width:
                                                                              24,
                                                                          height:
                                                                              24,
                                                                          fit: BoxFit
                                                                              .contain,
                                                                        ),
                                                                      )
                                                                    : Icon(
                                                                        _getSubIcon(
                                                                          sub['label']
                                                                              as String,
                                                                        ),
                                                                        color: const Color(
                                                                          0xFF00ACC1,
                                                                        ),
                                                                        size:
                                                                            16,
                                                                      ),
                                                              ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          sub['label']
                                                              as String,
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: GoogleFonts.outfit(
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFFFF5E00,
                                                                  )
                                                                : const Color(
                                                                    0xFF3A312C,
                                                                  ),
                                                            fontSize: 10,
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .w700
                                                                : FontWeight
                                                                      .w600,
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
                                                            gradient:
                                                                LinearGradient(
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
                                                                BorderRadius.only(
                                                                  topLeft:
                                                                      Radius.circular(
                                                                        10,
                                                                      ),
                                                                  topRight:
                                                                      Radius.circular(
                                                                        10,
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

                                  const SizedBox(height: 6),

                                  // Search Bar
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFEAD8C9),
                                          width: 0.8,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
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
                                                  color: const Color(
                                                    0xFFA59A94,
                                                  ),
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
                                                "lib/assets/images/Voice.png",
                                                width: 12,
                                                height: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Menu Title Section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
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
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Bottom 50%: scrollable products
                Expanded(
                  flex: 1,
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      showCartBar ? bottomInset + 88 : 24,
                    ),
                    itemCount: menuItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 280,
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
          if (showCartBar)
            Positioned(
              bottom: bottomInset + 16,
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
                    Text(
                      food['tag']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${food['rating']!} (${food['reviews']})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                          ),
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
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              boxShadow: isNotAccepting
                                  ? null
                                  : [
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
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final description =
        (food['description'] as String?) ??
        'Premium quality medical grade products sourced directly from licensed distributors, ensuring safety, effectiveness, and clean packaging.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomSafe),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8F3),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 10,
                                    child: Image.network(
                                      food['image']!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: const Color(0xFFF3EFEA),
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    16,
                                    20,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food['title']!,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        food['tag']!,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFA59A94),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            food['price']!,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFFF5E00),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            food['originalPrice']!,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFA59A94),
                                              fontSize: 13,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: const Color(
                                                0xFFA59A94,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
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
                                              color: const Color(0xFF2C2520),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        description,
                                        textAlign: TextAlign.justify,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 12,
                                          height: 1.55,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Row(
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
                                          Navigator.pop(context);
                                          setState(() {
                                            showCartBar = true;
                                            lastAddedItem = food;
                                            lastAddedItemPortion =
                                                food['tag'] as String?;
                                          });
                                        },
                                  child: Container(
                                    height: 48,
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
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: isNotAccepting
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFF5E00,
                                                ).withOpacity(0.28),
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
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isNotAccepting ? 'CLOSED' : 'ADD',
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
                                  setModalState(() {
                                    isLiked = !isLiked;
                                  });
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
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
                                    color: isLiked
                                        ? const Color(0xFFFF5E00)
                                        : const Color(0xFFA59A94),
                                    size: 20,
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
                    top: -52,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                                              'Add notes (e.g, verify expiry date for ${title.toLowerCase()}...)',
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

  void _showPrescriptionUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFDF9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Upload Prescription',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please upload a clear picture or PDF of your doctor\'s prescription. Our pharmacist will verify and confirm your order shortly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFA59A94),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUploadOption(
                          icon: Icons.camera_alt_outlined,
                          title: 'Take Photo',
                          onTap: () {
                            Navigator.pop(context);
                            _showUploadSuccessToast(
                              context,
                              'Prescription captured successfully!',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildUploadOption(
                          icon: Icons.photo_library_outlined,
                          title: 'Upload Gallery',
                          onTap: () {
                            Navigator.pop(context);
                            _showUploadSuccessToast(
                              context,
                              'Prescription uploaded from gallery!',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showUploadSuccessToast(
                        context,
                        'Prescription PDF uploaded successfully!',
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEAD8C9),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Color(0xFFFF5E00),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Select PDF / Document',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF5E00), size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadSuccessToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF00B25C),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
