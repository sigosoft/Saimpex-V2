import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../coupons_screen.dart';
import '../cart_screen.dart';
import 'pharmacy_details_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  int selectedCategoryIndex = 0; // Default to "All"
  final Set<String> likedPharmacies = {};

  final quickCategories = [
    {
      'label': 'All',
      'icon': 'lib/assets/images/All.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'label': 'OTC',
      'icon': 'lib/assets/images/OTC.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFEEF5FC), Color(0xFFD3E5F6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Baby Care',
      'icon': 'lib/assets/images/BabyCare.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFF5EC), Color(0xFFFEE6D6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Personal Care',
      'icon': 'lib/assets/images/PersonalCare.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFEBF6EE), Color(0xFFD4EBD9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Dental Care',
      'icon': 'lib/assets/images/DentalCare.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFE6F7FF), Color(0xFFCBEBFE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Wellness',
      'icon':
          'lib/assets/images/Welness.png', // Spelled as Welness.png in assets
      'gradient': const LinearGradient(
        colors: [Color(0xFFF7EBF6), Color(0xFFECD2EB)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Vitamins',
      'icon': 'lib/assets/images/Vitamins.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFFBE6), Color(0xFFFFF1CC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'First Aid',
      'icon': 'lib/assets/images/FirstAid.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFEE2E2), Color(0xFFFCA5A5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
    {
      'label': 'Device',
      'icon': 'lib/assets/images/Device.png',
      'gradient': const LinearGradient(
        colors: [Color(0xFFF6F6F6), Color(0xFFE8E8E8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
  ];

  final trustedPharmacies = [
    {
      'id': 'p_trusted1',
      'title': 'Pharmacy Nasr',
      'subtitle': 'Trusted',
      'rating': '4.6',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '50% OFF',
      'points': '200 Points Available',
      'isClosed': false,
      'isOpen247': true,
      'image':
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&auto=format&fit=crop',
    },
    {
      'id': 'p_trusted2',
      'title': 'Pharmacy Mauritanie',
      'subtitle': 'Trusted',
      'rating': '4.5',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'isClosed': false,
      'isOpen247': true,
      'image':
          'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?w=400&auto=format&fit=crop',
    },
  ];

  final nearbyPharmacies = [
    {
      'id': 'p_nearby1',
      'title': 'Pharmacie Ibn Sina',
      'subtitle': 'Trusted',
      'rating': '4.7',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '30% OFF',
      'points': '200 Points Available',
      'isClosed': false,
      'isOpen247': true,
      'image':
          'https://images.unsplash.com/photo-1628771065518-0d82f1938462?w=400&auto=format&fit=crop',
    },
    {
      'id': 'p_nearby2',
      'title': 'Pharmacy Safa',
      'subtitle': 'Trusted',
      'rating': '4.3',
      'time': '30-35 min',
      'dist': '10 Km',
      'discount': '50% OFF',
      'points': '200 Points Available',
      'isTemporarilyClosed': true,
      'isOpen247': false,
      'image':
          'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

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

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title "Pharmacy"
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Pharmacy',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      // Green Promotional Banner Slider
                      _buildPromoSlider(),

                      const SizedBox(height: 12),

                      // Upload Your Prescription Button
                      _buildPrescriptionUploadButton(context),

                      const SizedBox(height: 12),

                      // Search Bar Row
                      _buildSearchBar(),

                      const SizedBox(height: 16),

                      // Quick categories Grid Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Quick categories',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildQuickCategoriesGrid(),

                      const SizedBox(height: 12),

                      // Section Header: Trusted Pharmacies
                      _buildSectionHeader(
                        'Trusted Pharmacies',
                        'See All',
                        () {},
                      ),
                      _buildTrustedPharmaciesList(),

                      const SizedBox(height: 12),

                      // Section Header: Nearby Pharmacies
                      _buildSectionHeader(
                        'Nearby Pharmacies',
                        'Store Map',
                        () {},
                        showMapIcon: true,
                      ),
                      _buildNearbyPharmaciesList(),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
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
          const SizedBox(width: 12),

          // Location details
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  "lib/assets/images/Home.png",
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Deliver To',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              SelectLocationController.selectedTitle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF2C2520),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Points indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5E00).withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "lib/assets/images/Coin.png",
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "300 MRU",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Promotional Banner Slider with indicators
  Widget _buildPromoSlider() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 130,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              "lib/assets/images/Pharmacy slider.png",
              fit: BoxFit.fill,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFDCD6CF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFDCD6CF),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Upload Your Prescription Button
  Widget _buildPrescriptionUploadButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showPrescriptionUploadSheet(context),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFCBEFF4), // soft light teal
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFA2E0E8), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF0097A7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Upload Your Prescription',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF006064),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFA59A94),
              size: 22,
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
              width: 20,
              height: 20,
              color: const Color(0xFFA59A94),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 249, 210, 187),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "lib/assets/images/Voice.png",
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Quick categories Grid View matching home screen stack design
  Widget _buildQuickCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: quickCategories.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 1.30,
        ),
        itemBuilder: (context, index) {
          final cat = quickCategories[index];
          final isSelected = selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategoryIndex = index;
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Card Background (Starts 16px from top)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFE5102), Color(0xFFFFAE00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : (cat['gradient'] as Gradient?),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      cat['label'] as String,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF2C2520),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 2. Overlapping Illustration Image
                Positioned(
                  top: (cat['label'] == 'All') ? 12 : 0,
                  left: (cat['label'] == 'All') ? 0 : 24,
                  right: (cat['label'] == 'All') ? 0 : 24,
                  bottom: (cat['label'] == 'All') ? 22 : 22,
                  child: (cat['label'] == 'All')
                      ? Center(
                          child: Image.asset(
                            cat['icon'] as String,
                            width: 28,
                            height: 28,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFFF5E00),
                          ),
                        )
                      : Image.asset(cat['icon'] as String, fit: BoxFit.contain),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Section header
  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onTap, {
    bool showMapIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF5E00), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionText,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showMapIcon) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFFF5E00),
                      size: 11,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Horizontal Trusted Pharmacies List
  Widget _buildTrustedPharmaciesList() {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trustedPharmacies.length,
        itemBuilder: (context, index) {
          final store = trustedPharmacies[index];
          final isLiked = likedPharmacies.contains(store['id']);

          return GestureDetector(
            onTap: () {
              Get.to(() => PharmacyDetailsScreen(store: store));
            },
            child: Container(
              width: 240,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image & Badges
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            store['image'] as String,
                            width: double.infinity,
                            height: double.infinity,
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
                        // Discount Badge
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
                              store['discount'] as String,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Star Rating Badge
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
                                  store['rating'] as String,
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
                        // Favorite Heart Badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isLiked) {
                                  likedPharmacies.remove(store['id']);
                                } else {
                                  likedPharmacies.add(store['id'] as String);
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
                        // Points Badge with Coin
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
                                  store['points'] as String,
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
                  // Details Info
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              store['title'] as String,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (store['isOpen247'] == true)
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Open 24/7',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF4CAF50),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          store['subtitle'] as String,
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
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store['time'] as String,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF7A6A60),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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
                              store['dist'] as String,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF7A6A60),
                                fontSize: 10,
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
    );
  }

  // Vertical list for Nearby Pharmacies
  Widget _buildNearbyPharmaciesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: nearbyPharmacies.length,
        itemBuilder: (context, index) {
          final store = nearbyPharmacies[index];
          final isLiked = likedPharmacies.contains(store['id']);
          final isClosed = store['isClosed'] == true;
          final isTemporarilyClosed = store['isTemporarilyClosed'] == true;

          return GestureDetector(
            onTap: () {
              Get.to(() => PharmacyDetailsScreen(store: store));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 1),
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
                  // Image with Overlays
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            store['image'] as String,
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
                        // Discount Badge
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
                              store['discount'] as String,
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
                                  store['rating'] as String,
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
                                  likedPharmacies.remove(store['id']);
                                } else {
                                  likedPharmacies.add(store['id'] as String);
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
                        // Coin overlay
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
                                  store['points'] as String,
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
                        // Closed / Temporarily Closed Overlay
                        if (isClosed) ...[
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ),
                          Positioned.fill(child: _buildClosedOverlay('9 AM')),
                        ] else if (isTemporarilyClosed) ...[
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ),
                          Positioned.fill(
                            child: _buildTemporarilyClosedOverlay(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Details
                  Opacity(
                    opacity: (isClosed || isTemporarilyClosed) ? 0.65 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                store['title'] as String,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (store['isOpen247'] == true)
                                Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Open 24/7',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF4CAF50),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store['subtitle'] as String,
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
                                store['time'] as String,
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
                                store['dist'] as String,
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
    );
  }

  // Closed overlay
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

  // Temporarily Closed Overlay
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
                      'Temporarily not accepting',
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
                  'orders',
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

  // Prescription Upload bottom sheet
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
                  _buildUploadOptionRow(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Select PDF / Document',
                    onTap: () {
                      Navigator.pop(context);
                      _showUploadSuccessToast(
                        context,
                        'Prescription PDF uploaded successfully!',
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Float Close Button
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOptionRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF5E00), size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
