import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../water_product_subscription_screen.dart';
import '../../widgets/auto_slide_network_images.dart';

void showWaterProductDetailsSheet(
  BuildContext context,
  Map<String, dynamic> product, {
  VoidCallback? onAdd,
}) {
  final bottomSafe = MediaQuery.of(context).padding.bottom;
  final title = product['title'] ?? 'pw_drinking_water_19l'.tr;
  final rating = product['rating'] ?? '4.6';
  final reviews =
      product['reviews'] ?? 'pw_reviews_count'.trParams({'count': '10k +'});
  final price = product['price'] ?? '50 MRU';
  final originalPrice = product['originalPrice'] ?? '100 MRU';
  final description =
      product['description'] ?? 'pw_water_default_description'.tr;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) {
      bool isFavorite = false;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: bottomSafe),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Main Sheet Container
                Container(
                  margin: const EdgeInsets.only(top: 56),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.80,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF6F0),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // 1. Centered Product Bottle Image
                              SizedBox(
                                height: 170,
                                width: double.infinity,
                                child: AutoSlideNetworkImages(
                                  images: foodGalleryImages(product),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Product Title
                              Text(
                                title,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1A1A1A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // 3. Rating & Reviews
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB800),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    reviews,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF7A6A60),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 4. Price Row
                              Row(
                                children: [
                                  Text(
                                    price,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFF5E00),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    originalPrice,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // 5. Description Paragraph
                              Text(
                                description,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF5C524B),
                                  fontSize: 12,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 6. Features Row (Contactless Production, 10 Stage Purification, Quality Checked)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    _buildFeatureCard(
                                      iconAsset:
                                          'lib/assets/images/contactless.png',
                                      title: 'pw_feature_contactless'.tr,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildFeatureCard(
                                      icon: Icons.water_drop_outlined,
                                      title: 'pw_feature_purification'.tr,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildFeatureCard(
                                      icon: Icons.verified_outlined,
                                      title: 'pw_feature_quality'.tr,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 7. Return Empty Bottle Banner Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.recycling_rounded,
                                          color: Color(0xFF00A859),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'pw_return_empty_bottle'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFFF5E00),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'pw_return_empty_bottle_body'.tr,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF6B635C),
                                        fontSize: 11,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // 8. Bottom Action Bar (ADD + Favorite)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6F0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  if (onAdd != null) {
                                    onAdd();
                                  } else {
                                    Get.to(
                                      () => WaterProductSubscriptionScreen(
                                        product: product,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF5E00),
                                        Color(0xFFFFAE00),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF5E00,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'pw_add_caps'.tr,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 15,
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
                                  isFavorite = !isFavorite;
                                });
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFEAD8C9),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFF2C2520),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Top Close (X) Button
                Positioned(
                  top: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF5E00),
                        size: 24,
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

Widget _buildFeatureCard({
  IconData? icon,
  String? iconAsset,
  required String title,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0E6),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: iconAsset != null
              ? Image.asset(
                  iconAsset,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                )
              : Icon(icon, color: const Color(0xFFFF5E00), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}
