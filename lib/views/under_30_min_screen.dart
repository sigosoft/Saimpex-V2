import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';

class Under30MinScreen extends StatelessWidget {
  final String title;

  const Under30MinScreen({Key? key, this.title = 'Food'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    final filters = [
      {'label': 'Filter', 'icon': Icons.tune_rounded},
      {'label': 'Veg', 'isVeg': true},
      {'label': 'Offers', 'icon': Icons.percent_rounded},
      {'label': 'Ratings 4.0+', 'icon': Icons.star_rounded},
    ];

    final items = [
      {
        'id': 'u1',
        'title': 'Al Fantasia',
        'subtitle': 'Moroccan • Traditional',
        'rating': '4.6',
        'time': '30-35 min',
        'dist': '10 Km',
        'discount': '50% OFF',
        'points': '200 Points Available',
        'image':
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=350&auto=format&fit=crop',
      },
      {
        'id': 'u2',
        'title': 'Tarif Restaurant',
        'subtitle': 'Lebanese • Grill',
        'rating': '4.7',
        'time': '30-35 min',
        'dist': '10 Km',
        'discount': '30% OFF',
        'points': '200 Points Available',
        'image':
            'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=350&auto=format&fit=crop',
      },
      {
        'id': 'u3',
        'title': 'Portuguese restaurant',
        'subtitle': 'Lebanese • Grill',
        'rating': '4.7',
        'time': '30-35 min',
        'dist': '10 Km',
        'discount': '30% OFF',
        'points': '200 Points Available',
        'image':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=350&auto=format&fit=crop',
      },
    ];

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
        body: Column(
          children: [
            // 1. App Bar Header Container (No Subcategories Scroll)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF6F1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button card
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
                          title,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 32), // spacer to center title
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Search Field Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'What do you need today?',
                          hintStyle: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Image.asset(
                      "lib/assets/images/Camera.png",
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      "lib/assets/images/Voice.png",
                      width: 20,
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Filters Horizontal Scroll Row
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isVeg = filter['isVeg'] == true;
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
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
                        if (isVeg) ...[
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ] else if (filter['icon'] != null) ...[
                          Icon(
                            filter['icon'] as IconData,
                            color: filter['label'] == 'Ratings 4.0+'
                                ? const Color(0xFFFFAE00)
                                : const Color(0xFF7A6A60),
                            size: 14,
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

            // 4. Section Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Under 30 Minutes',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Restaurants Vertical List
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isClosed =
                      item['isClosed'] == true || item['isClosed'] == 'true';
                  return Container(
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
                                  item['image']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: const Color(0xFFF3EFEA),
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
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
                                    item['discount']!,
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
                                        item['rating']!,
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
                                child: Obx(() {
                                  final liked = controller.isLiked(item['id']!);
                                  return GestureDetector(
                                    onTap: () =>
                                        controller.toggleLike(item['id']!),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        liked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: const Color(0xFFE03A3A),
                                        size: 16,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              // Bottom Left Points overlay with Coin.png
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
                                        "lib/assets/images/Coin.png",
                                        width: 12,
                                        height: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['points']!,
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
                              // Bottom Right 30m overlay with clock icon
                              Positioned(
                                bottom: 8,
                                right: 10,
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
                                      const Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '30m',
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
                              if (isClosed) ...[
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.35),
                                  ),
                                ),
                                Positioned.fill(
                                  child: _buildClosedOverlay(
                                    (item['opensAt'] ?? '10 AM').toString(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Info Details
                        Opacity(
                          opacity: isClosed ? 0.65 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle']!,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF7A6A60),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Color(0xFFFF5E00),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['time']!,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF7A6A60),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFFFF5E00),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['dist']!,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF7A6A60),
                                        fontSize: 11,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedOverlay(String opensAt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD30000),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Closed',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Opens $opensAt',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Container(
                width: 8,
                height: 8,
                color: const Color(0xFFD30000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
