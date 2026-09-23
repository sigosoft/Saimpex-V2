import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../widgets/filter_chip_style.dart';
import '../coupons_screen.dart';
import 'express_store_detail_screen.dart';
import '../../widgets/app_back_button.dart';

class ExpressTrendingScreen extends StatelessWidget {
  const ExpressTrendingScreen({super.key});

  static const _filters = [
    {'label': 'Filter', 'icon': 'lib/assets/images/Filter.png'},
    {'label': 'Under 200 MRU', 'isMru': true},
    {'label': 'Offers', 'icon': 'lib/assets/images/Offer.png'},
    {'label': 'Rating', 'isRating': true},
  ];

  static const _stores = [
    {
      'id': 'e_tr1',
      'name': 'Quick Mart',
      'rating': '4.6',
      'time': '15-20 min',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=600&auto=format&fit=crop',
    },
    {
      'id': 'e_tr2',
      'name': 'Sante Pharmacy',
      'rating': '4.6',
      'time': '15-20 min',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image': 'lib/assets/images/Pharmacy.png',
      'isAsset': true,
    },
    {
      'id': 'e_tr3',
      'name': 'Pure Care Store',
      'rating': '4.6',
      'time': '15-20 min',
      'dist': '10 Km',
      'points': '200 Points Available',
      'image':
          'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=600&auto=format&fit=crop',
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
            Color(0xFFFDE8DD),
            Color(0xFFFFF3EC),
            Color(0xFFFFFBF7),
          ],
          stops: [0.0, 0.42, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      AppBackButton(onTap: () => Get.back()),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trending in express',
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
    return AppFilterChipsRow(
      children: [
        for (final filter in _filters)
          AppFilterChip(
            label: filter['label'].toString(),
            onTap: () {
              if (filter['label'] == 'Offers') {
                Get.to(() => const CouponsScreen());
              }
            },
            leading: filter['isMru'] == true
                ? AppFilterChip.mruLeading()
                : filter['isRating'] == true
                    ? AppFilterChip.iconLeading(
                        Icons.star_rounded,
                        color: const Color(0xFFFFAE00),
                      )
                    : filter['icon'] is String
                        ? AppFilterChip.assetLeading(filter['icon'] as String)
                        : null,
          ),
      ],
    );
  }

  Widget _buildStoreCard(
    HomeController controller,
    Map<String, dynamic> store,
  ) {
    final imagePath = (store['image'] ?? '').toString();
    final isAsset = store['isAsset'] == true || imagePath.startsWith('lib/');

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
                  child: isAsset
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      : Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
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
                          store['rating'].toString(),
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
                    final liked =
                        controller.isLiked(store['id'].toString());
                    return GestureDetector(
                      onTap: () => controller.toggleLike(
                        store['id'].toString(),
                        store,
                      ),
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
                  child: _pointsBadge(store['points'].toString()),
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
                  store['name'].toString(),
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
                      store['time'].toString(),
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
                      store['dist'].toString(),
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

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF3EFEA),
      child: const Icon(
        Icons.store_outlined,
        color: Colors.grey,
        size: 40,
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
}
