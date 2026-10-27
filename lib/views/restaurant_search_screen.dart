import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/select_location_controller.dart';
import '../core/network/api_exception.dart';
import '../models/food_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'pharmacy/widgets/pharmacy_background.dart';
import 'restaurant_details_screen.dart';

/// Restaurant search results, laid out like the pharmacy search.
class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key, this.initialKeyword = ''});

  final String initialKeyword;

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  int _requestId = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _restaurants = const [];
  List<Map<String, dynamic>> _filters = const [];
  final Map<String, String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialKeyword);
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _load() async {
    if (!Get.isRegistered<FoodRepository>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final requestId = ++_requestId;
    setState(() => _loading = true);
    try {
      final result = await Get.find<FoodRepository>().searchRestaurants(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
        keyword: _searchController.text,
        filters: Map<String, String>.from(_selectedFilters),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _restaurants = result.restaurants;
        if (result.filters.isNotEmpty) _filters = result.filters;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _loading = false);
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  void _toggleFilter(Map<String, dynamic> filter) {
    final param = '${filter['param']}';
    final value = '${filter['value']}';
    setState(() {
      if (_selectedFilters[param] == value) {
        _selectedFilters.remove(param);
      } else {
        _selectedFilters[param] = value;
      }
    });
    _load();
  }

  void _openRestaurant(Map<String, dynamic> restaurant) {
    Get.to(() => RestaurantDetailsScreen(restaurant: restaurant));
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hasResults = _restaurants.isNotEmpty;

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SizedBox(height: topInset + 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  AppBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _searchField()),
                ],
              ),
            ),
            if (_filters.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final selected =
                        _selectedFilters['${filter['param']}'] ==
                        '${filter['value']}';
                    return GestureDetector(
                      onTap: () => _toggleFilter(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFF5E00)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFEAD8C9),
                          ),
                        ),
                        child: Text(
                          '${filter['label']}',
                          style: GoogleFonts.outfit(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF2C2520),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E00),
                      ),
                    )
                  : !hasResults
                  ? Center(
                      child: Text(
                        'No results',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A6A60),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        bottomInset + 20,
                      ),
                      children: [
                        _sectionTitle('Restaurants'),
                        const SizedBox(height: 10),
                        for (final restaurant in _restaurants) ...[
                          _resultTile(
                            title: '${restaurant['title'] ?? ''}',
                            subtitle: '${restaurant['subtitle'] ?? ''}',
                            meta:
                                [
                                      restaurant['rating'],
                                      restaurant['time'],
                                      restaurant['dist'],
                                    ]
                                    .where((part) {
                                      final text = '$part'.trim();
                                      return text.isNotEmpty &&
                                          text != 'null' &&
                                          text != '0';
                                    })
                                    .join(' • '),
                            image: '${restaurant['image'] ?? ''}',
                            onTap: () => _openRestaurant(restaurant),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAD8C9)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFFA59A94), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 13,
                height: 1,
              ),
              decoration: InputDecoration(
                hintText: 'Search restaurants',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 12.5,
                  height: 1,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2C2520),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _resultTile({
    required String title,
    required String subtitle,
    required String meta,
    required String image,
    required VoidCallback onTap,
  }) {
    final fallback = const ColoredBox(
      color: Color(0xFFF3EFEA),
      child: Icon(Icons.restaurant_outlined, color: Color(0xFFA59A94)),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAD8C9)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: image.startsWith('http')
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => fallback,
                          )
                        : fallback,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (meta.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
