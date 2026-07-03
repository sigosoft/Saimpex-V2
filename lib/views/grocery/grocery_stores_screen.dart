import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import 'grocery_screen.dart';
import 'grocery_details_screen.dart';

class GroceryStoresScreen extends StatefulWidget {
  const GroceryStoresScreen({Key? key}) : super(key: key);

  @override
  State<GroceryStoresScreen> createState() => _GroceryStoresScreenState();
}

class _GroceryStoresScreenState extends State<GroceryStoresScreen> {
  int selectedSubcategoryIndex = 0;
  final Set<String> likedStores = {};

  final subcategories = [
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
    {'label': 'Ratings 4.0+', 'icon': Icons.star_rounded},
  ];

  final List<Map<String, dynamic>> groceryStores = [
    {
      'id': 'gs_all1',
      'name': 'Salam Supermarket',
      'category': 'Hypermarket',
      'rating': '4.6',
      'time': '35 min',
      'dist': '10 Km',
      'discount': '50% OFF',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&auto=format&fit=crop',
    },
    {
      'id': 'gs_all2',
      'name': 'Good Choice Store',
      'category': 'Fruits & Veg',
      'rating': '4.7',
      'time': '35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&auto=format&fit=crop',
    },
    {
      'id': 'gs_all3',
      'name': 'Jawda Stores',
      'category': 'Essentials',
      'rating': '4.7',
      'time': '35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1583258292688-d0213df4a3a8?w=500&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFE6DC), // Top peach gradient
            Color(0xFFFFF4EE), // Middle soft peach
            Color(0xFFFAF6F0), // Base color at the bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Bar Header Row
              _buildHeader(context),

              // 2. Subcategories Horizontal Scroll Row
              _buildSubcategoriesRow(),

              // 3. Search Bar
              _buildSearchBar(),

              // 4. Filters Row
              _buildFiltersRow(),
              const SizedBox(height: 16),

              // 5. Section Header Title + Map Button
              _buildSectionHeader(),
              const SizedBox(height: 12),

              // 6. Stores Vertical List
              Expanded(
                child: ListView.builder(
                  itemCount: groceryStores.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemBuilder: (context, index) {
                    final store = groceryStores[index];
                    final isLiked = likedStores.contains(store['id']);

                    return GestureDetector(
                      onTap: () {
                        Get.to(() => GroceryDetailsScreen(store: store));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFEAD8C9),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner Image & Badges
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      store['image']!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Container(
                                            color: const Color(0xFFF3EFEA),
                                            child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),

                                  // Discount Overlay
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE03A3A),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        store['discount']!,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Star Rating overlay
                                  Positioned(
                                    top: 10,
                                    left: 70,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFAE00),
                                            size: 10,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            store['rating']!,
                                            style: GoogleFonts.outfit(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Heart overlay
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isLiked) {
                                            likedStores.remove(store['id']);
                                          } else {
                                            likedStores.add(store['id']!);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isLiked
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: const Color(0xFFE03A3A),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom Left Points overlay with Coin.png/Points.png
                                  Positioned(
                                    bottom: 8,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            "lib/assets/images/Points.png",
                                            width: 12,
                                            height: 12,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Image.asset(
                                                  "lib/assets/images/Coin.png",
                                                  width: 12,
                                                  height: 12,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            store['points']!,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 8,
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

                            // Text details area
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store['name']!,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    store['category']!,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        color: Color(0xFFFF5E00),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        store['time']!,
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
                                        store['dist']!,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header App Bar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
            ),
          ),
          Text(
            "Grocery",
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 32), // Spacer to balance back button
        ],
      ),
    );
  }

  // Subcategories
  Widget _buildSubcategoriesRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final sub = subcategories[index];
            final isSelected = selectedSubcategoryIndex == index;
            final isAll = sub['isAll'] == true;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedSubcategoryIndex = index;
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
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF5E00)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                sub['image'] as String,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 36,
                                      height: 36,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.fastfood,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
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
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'What do you need today?',
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
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
    );
  }

  // Filters Scroll Row
  Widget _buildFiltersRow() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isMru = filter['isMru'] == true;
          return Container(
            margin: const EdgeInsets.only(right: 10),
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
                    "lib/assets/images/Points.png",
                    width: 12,
                    height: 12,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      "lib/assets/images/Coin.png",
                      width: 12,
                      height: 12,
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
    );
  }

  // Section Title + Store Map Button
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Top Stores Near You',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Store Map button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF5E00), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Store Map',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.map_outlined,
                  color: Color(0xFFFF5E00),
                  size: 11,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
