import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/select_location_controller.dart';
import '../core/network/api_exception.dart';
import '../models/food_repository.dart';
import '../models/grocery_repository.dart';
import '../models/pharmacy_repository.dart';
import '../models/water_repository.dart';
import '../utils/api_language.dart';
import '../widgets/app_back_button.dart';
import 'grocery/grocery_details_screen.dart';
import 'pharmacy/pharmacy_items_screen.dart';
import 'pharmacy/pharmacy_search_screen.dart';
import 'restaurant_details_screen.dart';
import 'restaurant_search_screen.dart';
import 'water/water_supplier_details_screen.dart';

/// Home search across Food, Grocery, Pharmacy and Water. There is no single
/// search API, so it runs each vertical's search (…SearchV2) side by side and
/// opens results with that vertical's own store screen.
class AllSearchScreen extends StatefulWidget {
  const AllSearchScreen({super.key, this.initialKeyword = ''});

  final String initialKeyword;

  @override
  State<AllSearchScreen> createState() => _AllSearchScreenState();
}

class _Section {
  const _Section({
    required this.title,
    required this.rows,
    required this.open,
    this.seeAll,
  });

  final String title;
  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic> row) open;
  final VoidCallback? seeAll;
}

class _AllSearchScreenState extends State<AllSearchScreen> {
  static const _shownPerSection = 5;

  late final TextEditingController _controller;
  List<_Section> _sections = const [];
  bool _loading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
    _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// One vertical's results; a vertical that fails just shows nothing.
  Future<List<Map<String, dynamic>>> _rows(
    Future<List<Map<String, dynamic>>> Function() load,
  ) async {
    try {
      return await load();
    } on ApiException {
      return const [];
    }
  }

  Future<void> _search() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    final requestId = ++_requestId;
    setState(() => _loading = true);
    final latitude = SelectLocationController.selectedLatitude;
    final longitude = SelectLocationController.selectedLongitude;
    final language = apiLanguageCode();

    final results = await Future.wait([
      _rows(
        () async => (await Get.find<FoodRepository>().searchRestaurants(
          latitude: latitude,
          longitude: longitude,
          language: language,
          keyword: keyword,
        )).restaurants,
      ),
      _rows(
        () async => (await Get.find<GroceryRepository>().searchGroceryStores(
          latitude: latitude,
          longitude: longitude,
          language: language,
          keyword: keyword,
        )).stores,
      ),
      _rows(
        () async => (await Get.find<PharmacyRepository>().searchPharmaciesV2(
          latitude: latitude,
          longitude: longitude,
          language: language,
          keyword: keyword,
        )).pharmacies,
      ),
      _rows(
        () async => (await Get.find<WaterRepository>().search(
          latitude: latitude,
          longitude: longitude,
          language: language,
          keyword: keyword,
        )).suppliers,
      ),
    ]);
    if (!mounted || requestId != _requestId) return;

    setState(() {
      _loading = false;
      _sections = [
        _Section(
          title: 'Food',
          rows: results[0],
          open: (row) => Get.to(() => RestaurantDetailsScreen(restaurant: row)),
          seeAll: () =>
              Get.to(() => RestaurantSearchScreen(initialKeyword: keyword)),
        ),
        _Section(
          title: 'Grocery',
          rows: results[1],
          open: (row) => Get.to(() => GroceryDetailsScreen(store: row)),
        ),
        _Section(
          title: 'Pharmacy',
          rows: results[2],
          open: (row) => Get.to(() => PharmacyItemsScreen(store: row)),
          seeAll: () =>
              Get.to(() => PharmacySearchScreen(initialKeyword: keyword)),
        ),
        _Section(
          title: 'Water',
          rows: results[3],
          open: (row) =>
              Get.to(() => WaterSupplierDetailsScreen(supplier: row)),
        ),
      ].where((section) => section.rows.isNotEmpty).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 1.5),
              ),
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
                      controller: _controller,
                      autofocus: widget.initialKeyword.isEmpty,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search food, groceries, pharmacy, water',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
      );
    }
    if (_sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _controller.text.trim().isEmpty
                ? 'Type what you are looking for'
                : 'No results for "${_controller.text.trim()}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8C7D73),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final section in _sections) ...[
          _buildSectionHeader(section),
          const SizedBox(height: 10),
          for (final row in section.rows.take(_shownPerSection)) ...[
            _buildRow(section, row),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(_Section section) {
    return Row(
      children: [
        Expanded(
          child: Text(
            section.title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (section.seeAll != null && section.rows.length > _shownPerSection)
          GestureDetector(
            onTap: section.seeAll,
            child: Text(
              'See all',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(_Section section, Map<String, dynamic> row) {
    String text(dynamic value) => '${value ?? ''}'.trim();
    final title = text(row['title']).isEmpty
        ? text(row['name'])
        : text(row['title']);
    final details = [
      text(row['rating']),
      text(row['dist']),
      text(row['time']),
    ].where((part) => part.isNotEmpty && part != 'null').join(' · ');
    final image = text(row['image']);

    return GestureDetector(
      onTap: () => section.open(row),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
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
                        errorBuilder: (_, _, _) => _imageFallback(),
                      )
                    : image.isEmpty
                    ? _imageFallback()
                    : Image.asset(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imageFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? section.title : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8C7D73),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8AFA8)),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: const Color(0xFFFFF0EA),
    alignment: Alignment.center,
    child: const Icon(Icons.storefront_outlined, color: Color(0xFFFF5E00)),
  );
}
