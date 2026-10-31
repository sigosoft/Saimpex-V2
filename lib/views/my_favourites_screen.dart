import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_back_button.dart';
import '../controllers/home_controller.dart';
import 'restaurant_details_screen.dart';

class MyFavouritesScreen extends StatelessWidget {
  const MyFavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Column(
          children: [
            _buildHeader(context, controller),
            Expanded(
              child: Obx(() {
                final favourites = controller.favourites;
                if (favourites.isEmpty) {
                  return Center(
                    child: Text(
                      'core_favourites_empty'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: favourites.length,
                  itemBuilder: (context, index) {
                    return _buildFavouriteCard(controller, favourites[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Obx(() {
              final count = controller.favouritesCount;
              return Text(
                count > 0
                    ? 'core_favourites_title_count'.trParams({
                        'count': '$count',
                      })
                    : 'core_favourites_title'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
          ),
          const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.more_vert_rounded,
              color: Color(0xFFB0A59C),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavouriteCard(
    HomeController controller,
    Map<String, dynamic> item,
  ) {
    final id = (item['id'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Get.to(() => RestaurantDetailsScreen(restaurant: item));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
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
            SizedBox(
              height: 168,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildImage((item['image'] ?? '').toString()),
                  ),
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: Row(
                      children: [
                        if (_text(item, 'discount').isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5E00),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _text(item, 'discount'),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_text(item, 'rating').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFAE00),
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _text(item, 'rating'),
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: GestureDetector(
                      onTap: () => controller.toggleLike(id, item),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFE03A3A),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  if (_text(item, 'points').isNotEmpty)
                    PositionedDirectional(
                      bottom: 10,
                      start: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'lib/assets/images/Coin.png',
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _text(item, 'points'),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(item, 'title').isEmpty
                        ? 'core_favourites_fallback_title'.tr
                        : _text(item, 'title'),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (item['subtitle'] ?? '').toString(),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7E76),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_text(item, 'time').isNotEmpty ||
                      _text(item, 'dist').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (_text(item, 'time').isNotEmpty) ...[
                          const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFFFF5E00),
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _text(item, 'time'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4A453F),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 18),
                        ],
                        if (_text(item, 'dist').isNotEmpty) ...[
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFFF5E00),
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _text(item, 'dist'),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF4A453F),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A card field as text; empty when the card doesn't have it.
  static String _text(Map<String, dynamic> item, String key) =>
      '${item[key] ?? ''}'.trim();

  Widget _buildImage(String image) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF3EFEA),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
          ),
        ),
      );
    }
    if (image.isEmpty) {
      return Container(
        color: const Color(0xFFF3EFEA),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        ),
      );
    }
    return Image.asset(image, fit: BoxFit.cover);
  }
}
