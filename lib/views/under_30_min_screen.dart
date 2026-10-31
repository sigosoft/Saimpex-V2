import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';
import '../widgets/app_back_button.dart';
import 'widgets/search_camera_button.dart';
import '../widgets/filter_chip_style.dart';
import 'coupons_screen.dart';
import 'restaurant_details_screen.dart';

class Under30MinScreen extends StatelessWidget {
  final String title;

  const Under30MinScreen({super.key, this.title = 'Food'});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    final filters = [
      // 'label' is matched below; 'text' is what the chip shows.
      {
        'label': 'Filter',
        'text': 'orders_chip_filter'.tr,
        'icon': Image.asset("lib/assets/images/Filter.png"),
      },
      {'label': 'Veg', 'text': 'orders_chip_veg'.tr, 'isVeg': true},
      {
        'label': 'Offers',
        'text': 'orders_chip_offers'.tr,
        'icon': Image.asset("lib/assets/images/Offer.png"),
      },
      {
        'label': 'Ratings 4.0+',
        'text': 'orders_chip_ratings'.trParams({'rating': '4.0'}),
        'icon': Icons.star_rounded,
      },
    ];

    // Restaurants that deliver within 30 minutes, from homeHub's
    // under_30_minutes (loaded with Home).
    final List<Map<String, dynamic>> items = controller.homeUnder30.toList();

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
                        AppBackButton(onTap: () => Get.back()),
                        Text(
                          title == 'Food' ? 'search_vertical_food'.tr : title,
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
            ScanSearchHost(
              builder: (controller) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'orders_search_hint'.tr,
                              hintStyle: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        SearchCameraButton(
                          controller: controller,
                          child: Image.asset(
                            "lib/assets/images/Camera.png",
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF0E0),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            "lib/assets/images/Voice.png",
                            width: 16,
                            height: 16,
                            color: const Color(0xFFFF5E00),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 3. Filters Horizontal Scroll Row
            AppFilterChipsRow(
              children: [
                for (final filter in filters)
                  AppFilterChip(
                    label: filter['text'] as String,
                    onTap: () {
                      if (filter['label'] == 'Filter') {
                        _showFilterBottomSheet(context);
                      } else if (filter['label'] == 'Offers') {
                        Get.to(() => const CouponsScreen());
                      }
                    },
                    leading: filter['isVeg'] == true
                        ? AppFilterChip.vegLeading()
                        : filter['icon'] is IconData
                        ? AppFilterChip.iconLeading(
                            filter['icon'] as IconData,
                            color:
                                (filter['label'] as String).contains('Rating')
                                ? const Color(0xFFFFAE00)
                                : const Color(0xFF2C2520),
                          )
                        : filter['icon'] is Widget
                        ? AppFilterChip.widgetLeading(filter['icon'] as Widget)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Section Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'orders_under_30_title'.tr,
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
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'under30_empty'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isClosed =
                            item['isClosed'] == true ||
                            item['isClosed'] == 'true';
                        final isTemporarilyClosed =
                            item['isTemporarilyClosed'] == true ||
                            item['isTemporarilyClosed'] == 'true';
                        return GestureDetector(
                          onTap: () {
                            Get.to(
                              () => RestaurantDetailsScreen(restaurant: item),
                            );
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
                                  color: Colors.black.withValues(alpha: 0.02),
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
                                      PositionedDirectional(
                                        top: 10,
                                        start: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE03A3A),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                      PositionedDirectional(
                                        top: 10,
                                        start: 70,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
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
                                      PositionedDirectional(
                                        top: 10,
                                        end: 10,
                                        child: Obx(() {
                                          final liked = controller.isLiked(
                                            item['id']!,
                                          );
                                          return GestureDetector(
                                            onTap: () => controller.toggleLike(
                                              item['id']!,
                                              item,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                liked
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                          .favorite_border_rounded,
                                                color: const Color(0xFFE03A3A),
                                                size: 16,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      // Bottom Left Points overlay with Coin.png
                                      PositionedDirectional(
                                        bottom: 8,
                                        start: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                      PositionedDirectional(
                                        bottom: 8,
                                        end: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                'orders_30_min'.tr,
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
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: _buildClosedOverlay(
                                            (item['opensAt'] ?? '10 AM')
                                                .toString(),
                                          ),
                                        ),
                                      ] else if (isTemporarilyClosed) ...[
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child:
                                              _buildTemporarilyClosedOverlay(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Info Details
                                Opacity(
                                  opacity: (isClosed || isTemporarilyClosed)
                                      ? 0.65
                                      : 1.0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'orders_closed'.tr,
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
                      'orders_opens_at'.trParams({'time': opensAt}),
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

  Widget _buildTemporarilyClosedOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      'orders_temp_closed_line1'.tr,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'orders_temp_closed_line2'.tr,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
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
                color: const Color(0xFFFF8A00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _FilterBottomSheetContent();
      },
    );
  }
}

class _FilterBottomSheetContent extends StatefulWidget {
  const _FilterBottomSheetContent();

  @override
  State<_FilterBottomSheetContent> createState() =>
      _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  final List<String> selectedFoodTags = [];
  RangeValues priceRange = const RangeValues(65, 1500);
  String selectedSortBy = 'Relevance';

  final List<String> foodTags1 = [
    'Spicy',
    'Non Spicy',
    'Sugar Free',
    'Mild Sugar',
  ];
  final List<String> foodTags2 = [
    'Offers',
    'Ratings: 4.5+',
    'Ratings: 4.0+',
    'Ratings: 3.5+',
  ];
  final List<String> sortOptions = [
    'Relevance',
    'Delivery Time',
    'Cost: Low to High',
    'Cost: High to Low',
  ];

  /// Shown text for a chip value (the values stay English for matching).
  static String _chipText(String value) => switch (value) {
    'Spicy' => 'orders_tag_spicy'.tr,
    'Non Spicy' => 'orders_tag_non_spicy'.tr,
    'Sugar Free' => 'orders_tag_sugar_free'.tr,
    'Mild Sugar' => 'orders_tag_mild_sugar'.tr,
    'Offers' => 'orders_chip_offers'.tr,
    'Ratings: 4.5+' => 'orders_sheet_ratings'.trParams({'rating': '4.5'}),
    'Ratings: 4.0+' => 'orders_sheet_ratings'.trParams({'rating': '4.0'}),
    'Ratings: 3.5+' => 'orders_sheet_ratings'.trParams({'rating': '3.5'}),
    'Relevance' => 'orders_sort_relevance'.tr,
    'Delivery Time' => 'orders_sort_delivery_time'.tr,
    'Cost: Low to High' => 'orders_sort_cost_low_high'.tr,
    'Cost: High to Low' => 'orders_sort_cost_high_low'.tr,
    _ => value,
  };

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
          _chipText(label),
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

  Widget _buildHorizontalChips(
    List<String> tags,
    List<String> selectedList,
    Function(String) onSelected,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tags.map((tag) {
          final isSelected = selectedList.contains(tag);
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _buildChip(tag, isSelected, () => onSelected(tag)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortChips(
    List<String> options,
    String selectedOption,
    Function(String) onSelected,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: options.map((option) {
          final isSelected = selectedOption == option;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _buildChip(option, isSelected, () => onSelected(option)),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 60),
                        Text(
                          'orders_filters'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFoodTags.clear();
                              priceRange = const RangeValues(65, 1500);
                              selectedSortBy = 'Relevance';
                            });
                          },
                          child: Text(
                            'orders_clear_all_link'.tr,
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
                  const SizedBox(height: 24),

                  // Chips Row 1
                  _buildHorizontalChips(foodTags1, selectedFoodTags, (tag) {
                    setState(() {
                      if (selectedFoodTags.contains(tag)) {
                        selectedFoodTags.remove(tag);
                      } else {
                        selectedFoodTags.add(tag);
                      }
                    });
                  }),
                  const SizedBox(height: 10),

                  // Chips Row 2
                  _buildHorizontalChips(foodTags2, selectedFoodTags, (tag) {
                    setState(() {
                      if (selectedFoodTags.contains(tag)) {
                        selectedFoodTags.remove(tag);
                      } else {
                        selectedFoodTags.add(tag);
                      }
                    });
                  }),
                  const SizedBox(height: 24),

                  // Price Range Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'orders_price_range'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${'mru'.trParams({'amount': '${priceRange.start.round()}'})} - '
                          '${'mru'.trParams({'amount': '${priceRange.end.round()}'})}',
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

                  // Range Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF5E00),
                        inactiveTrackColor: const Color(0xFFF3EFEA),
                        activeTickMarkColor: Colors.transparent,
                        inactiveTickMarkColor: Colors.transparent,
                        overlayColor: const Color(
                          0xFFFF5E00,
                        ).withValues(alpha: 0.12),
                        valueIndicatorColor: const Color(0xFFFF5E00),
                        rangeValueIndicatorShape:
                            const RectangularRangeSliderValueIndicatorShape(),
                        rangeThumbShape: const CustomRangeThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: RangeSlider(
                        values: priceRange,
                        min: 0,
                        max: 3000,
                        divisions: 60,
                        onChanged: (values) {
                          setState(() {
                            priceRange = values;
                          });
                        },
                      ),
                    ),
                  ),

                  // Range Bounds Labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'mru'.trParams({'amount': '0'}),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'mru'.trParams({'amount': '3000'}),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sort by Header
                  Center(
                    child: Text(
                      'orders_sort_by'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sort by Chips
                  _buildSortChips(sortOptions, selectedSortBy, (option) {
                    setState(() {
                      selectedSortBy = option;
                    });
                  }),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFoodTags.clear();
                                priceRange = const RangeValues(65, 1500);
                                selectedSortBy = 'Relevance';
                              });
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6F1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  'orders_clear_all'.tr,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF5E00),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5E00),
                                    Color(0xFFFFAE00),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF5E00,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'orders_apply'.tr,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        ),

        // Floating close button
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
                    color: Colors.black.withValues(alpha: 0.1),
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

class CustomRangeThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;

  const CustomRangeThumbShape({this.enabledThumbRadius = 10.0});

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
    final Canvas canvas = context.canvas;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, enabledThumbRadius, shadowPaint);

    // Draw white background
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, fillPaint);

    // Draw orange border
    final borderPaint = Paint()
      ..color = const Color(0xFFFF5E00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, enabledThumbRadius - 1.25, borderPaint);
  }
}
