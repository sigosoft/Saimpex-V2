import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../coupons_screen.dart';
import 'express_store_detail_screen.dart';
import 'widgets/express_filter_sheet.dart';

class ExpressFifteenMinDeliveryScreen extends StatelessWidget {
  const ExpressFifteenMinDeliveryScreen({super.key});

  static const _filters = [
    {'label': 'Filter', 'icon': 'lib/assets/images/Filter.png'},
    {'label': 'Under 200 MRU', 'isMru': true},
    {'label': 'Offers', 'icon': 'lib/assets/images/Offer.png'},
    {'label': 'Rating', 'isRating': true},
  ];

  static const _stores = [
    {
      'id': 'e15_1',
      'name': 'Freshmart',
      'rating': '4.6',
      'time': '15 min',
      'badgeTime': '15m',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop',
    },
    {
      'id': 'e15_2',
      'name': 'Express Hub',
      'rating': '4.6',
      'time': '15 min',
      'badgeTime': '15m',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&auto=format&fit=crop',
    },
    {
      'id': 'e15_3',
      'name': 'Freshmart',
      'rating': '4.6',
      'time': '15 min',
      'badgeTime': '15m',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFDDCF),
            Color(0xFFFFEEE5),
            Color(0xFFFAF6F0),
          ],
          stops: [0.0, 0.38, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
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
                      children: [
                        GestureDetector(
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
                                  blurRadius: 4,
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
                        Expanded(
                          child: Text(
                            '15-Min Delivery',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFiltersRow(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '15-Min Delivery',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _stores.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildStoreCard(controller, _stores[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
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
              'lib/assets/images/Camera.png',
              width: 18,
              height: 18,
              color: const Color(0xFFA59A94),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.camera_alt_outlined,
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

  Widget _buildFiltersRow() {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isMru = filter['isMru'] == true;
          final isRating = filter['isRating'] == true;
          final iconPath = filter['icon'] as String?;

          return GestureDetector(
            onTap: () {
              if (filter['label'] == 'Filter') {
                showExpressFilterSheet(context);
              } else if (filter['label'] == 'Offers') {
                Get.to(() => const CouponsScreen());
              }
            },
            child: Container(
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
                  if (isMru) ...[
                    Image.asset(
                      'lib/assets/images/Coin.png',
                      width: 14,
                      height: 14,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFFFF5E00),
                        size: 14,
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
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF7A6A60),
                        size: 14,
                      ),
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

  Widget _buildStoreCard(
    HomeController controller,
    Map<String, String> store,
  ) {
    return GestureDetector(
      onTap: () => Get.to(() => ExpressStoreDetailScreen(store: store)),
      child: Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    store['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF3EFEA),
                      child: const Icon(
                        Icons.store_outlined,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAE00),
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          store['rating']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Obx(() {
                    final liked = controller.isLiked(store['id']!);
                    return GestureDetector(
                      onTap: () => controller.toggleLike(store['id']!, store),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: liked
                              ? const Color(0xFFE03A3A)
                              : const Color(0xFF2C2520),
                          size: 16,
                        ),
                      ),
                    );
                  }),
                ),
                Positioned(
                  left: 10,
                  bottom: 8,
                  child: _pointsBadge(store['points']!),
                ),
                Positioned(
                  right: 10,
                  bottom: 8,
                  child: _timeBadge(store['badgeTime']!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['name']!,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFFFF5E00),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      store['time']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4A453F),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFFF5E00),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      store['dist']!,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4A453F),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

  Widget _pointsBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'lib/assets/images/Coin.png',
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFAE00),
              size: 14,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
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
            time,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
