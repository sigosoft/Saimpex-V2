import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'water_supplier_details_screen.dart';

class WaterSeeAllScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const WaterSeeAllScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<WaterSeeAllScreen> createState() => _WaterSeeAllScreenState();
}

class _WaterSeeAllScreenState extends State<WaterSeeAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          final name = (item['name'] ?? item['title'] ?? '')
              .toString()
              .toLowerCase();
          final sub = (item['subtitle'] ?? item['supplier'] ?? '')
              .toString()
              .toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || sub.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // 1. Header Bar
              _buildHeader(context),
              const SizedBox(height: 14),

              // 2. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 14),

              // 3. Open Map Action Pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open Map',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.pin_drop_rounded,
                        color: Color(0xFFFF5E00),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Data Cards List
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No suppliers found',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildSupplierCard(item);
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFFF5E00),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: 'Search water suppliers',
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFA59A94),
            size: 20,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFFA59A94),
                size: 20,
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(right: 6),
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E6),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'lib/assets/images/Voice.png',
                  width: 10,
                  height: 10,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFFFF5E00),
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Supplier Card Component
  Widget _buildSupplierCard(Map<String, dynamic> item) {
    final title = item['name'] ?? item['title'] ?? 'Water Supplier';
    final subtitle =
        item['subtitle'] ?? item['supplier'] ?? 'Premium drinking water';
    final image = item['image'] ?? 'lib/assets/images/Water.png';
    final rating = item['rating'] ?? '4.6';
    final time = item['time'] ?? '30-35 min';
    final dist = item['dist'] ?? '10 Km';
    final discount = item['discount'] ?? '50% OFF';
    final points = item['points'] ?? '200 Points Available';
    bool isFav = item['isFavorite'] ?? false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return GestureDetector(
          onTap: () {
            Get.to(() => WaterSupplierDetailsScreen(supplier: item));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Area Box
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Container(
                        height: 170,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF007BFF), Color(0xFF4A90E2)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            image,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.water_drop,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Left Badges (Discount + Rating)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
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
                              discount,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  rating,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1A1A1A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top Right Favorite Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setCardState(() {
                            isFav = !isFav;
                            item['isFavorite'] = isFav;
                          });
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFF2C2520),
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Left Points Overlay Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'lib/assets/images/Coin.png',
                              width: 14,
                              height: 14,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFFFB800),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              points,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Content Details Area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Delivery Details Metrics Row
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF5E00),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFFF5E00),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dist,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
