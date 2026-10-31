import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/select_location_controller.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/general_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'grocery/grocery_details_screen.dart';
import 'pharmacy/pharmacy_items_screen.dart';
import 'restaurant_details_screen.dart';
import 'water/water_supplier_details_screen.dart';

/// Home search across every category: typed or voice text with GET
/// customer/search, or a photo with image-recognition/analyze. Stores that
/// deliver to the selected location, nearest first, grouped by category,
/// then matching products. Results open in that category's own store screen.
class AllSearchScreen extends StatefulWidget {
  const AllSearchScreen({super.key, this.initialKeyword = '', this.imagePath});

  final String initialKeyword;

  /// A photo to search by instead of [initialKeyword].
  final String? imagePath;

  @override
  State<AllSearchScreen> createState() => _AllSearchScreenState();
}

class _Section {
  const _Section({required this.title, required this.rows, required this.open});

  final String title;
  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic> row) open;
}

class _AllSearchScreenState extends State<AllSearchScreen> {
  late final TextEditingController _controller;
  List<_Section> _sections = const [];
  bool _loading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
    final imagePath = widget.imagePath;
    if (imagePath != null) {
      _run(
        () => Get.find<GeneralRepository>().searchByImage(
          imagePath: imagePath,
          latitude: SelectLocationController.selectedLatitude,
          longitude: SelectLocationController.selectedLongitude,
          language: apiLanguageCode(),
        ),
      );
    } else {
      _search();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Categories whose store screen the app can open, in display order.
  static const _verticals = [
    'food',
    'grocery',
    'local_store',
    'pharmacy',
    'water',
  ];

  static String _localName(Map<String, dynamic> row, String key) {
    final language = apiLanguageCode();
    for (final field in [
      '${key}_$language',
      if (language == 'en') key,
      '${key}_en',
      key,
    ]) {
      final value = '${row[field] ?? ''}'.trim();
      if (value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  /// A search store row as the card map that vertical's store screen reads.
  static Map<String, dynamic> _storeCard(Map<String, dynamic> store) {
    final id = int.tryParse('${store['id'] ?? ''}') ?? 0;
    final name = _localName(store, 'name');
    final distance = num.tryParse('${store['distance_km'] ?? ''}');
    final rating = num.tryParse('${store['rating'] ?? ''}');
    return {
      'id': '$id',
      'vendor_id': id,
      'restaurant_id': id,
      'grocery_id': id,
      'vendorId': id,
      'title': name,
      'name': name,
      'image': ApiConstants.mediaUrl('${store['image'] ?? ''}') ?? '',
      'rating': rating == null || rating <= 0 ? '' : rating.toStringAsFixed(1),
      'dist': distance == null ? '' : '${distance.toStringAsFixed(1)} km',
      if (store['vertical'] == 'local_store') 'isLocalStore': true,
    };
  }

  static void _openStore(String vertical, Map<String, dynamic> card) {
    switch (vertical) {
      case 'food':
        Get.to(() => RestaurantDetailsScreen(restaurant: card));
      case 'grocery':
      case 'local_store':
        Get.to(() => GroceryDetailsScreen(store: card));
      case 'pharmacy':
        Get.to(() => PharmacyItemsScreen(store: card));
      case 'water':
        Get.to(() => WaterSupplierDetailsScreen(supplier: card));
    }
  }

  Future<void> _search() async {
    final keyword = _controller.text.trim();
    // The API takes 2–100 characters.
    if (keyword.length < 2) return;
    await _run(
      () => Get.find<GeneralRepository>().search(
        query: keyword.length > 100 ? keyword.substring(0, 100) : keyword,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
      ),
    );
  }

  Future<void> _run(
    Future<
      ({List<Map<String, dynamic>> stores, List<Map<String, dynamic>> products})
    >
    Function()
    load,
  ) async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    try {
      final result = await load();
      if (!mounted || requestId != _requestId) return;

      final sections = <_Section>[];
      for (final vertical in _verticals) {
        final rows = result.stores
            .where((store) => store['vertical'] == vertical)
            .map(_storeCard)
            .toList();
        if (rows.isEmpty) continue;
        sections.add(
          _Section(
            title: 'search_vertical_$vertical'.tr,
            rows: rows,
            open: (card) => _openStore(vertical, card),
          ),
        );
      }
      // Products open their store, where the customer adds them to the cart.
      final products = <Map<String, dynamic>>[];
      for (final product in result.products) {
        final store = product['store'] is Map
            ? Map<String, dynamic>.from(product['store'] as Map)
            : <String, dynamic>{};
        final vertical = '${store['vertical'] ?? product['vertical'] ?? ''}';
        if (!_verticals.contains(vertical)) continue;
        final price = num.tryParse(
          '${product['discount_price'] ?? product['price'] ?? ''}',
        );
        products.add({
          'title': _localName(product, 'name'),
          'image': ApiConstants.mediaUrl('${product['image'] ?? ''}') ?? '',
          'rating': '${store['name'] ?? ''}',
          'dist': price == null
              ? ''
              : 'mru'.trParams({'amount': price.round().toString()}),
          'vertical': vertical,
          'store': _storeCard({...store, 'vertical': vertical}),
        });
      }
      if (products.isNotEmpty) {
        sections.add(
          _Section(
            title: 'search_products'.tr,
            rows: products,
            open: (row) => _openStore(
              '${row['vertical']}',
              Map<String, dynamic>.from(row['store'] as Map),
            ),
          ),
        );
      }
      setState(() => _sections = sections);
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _sections = const []);
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
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
                        hintText: 'search_hint'.tr,
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
                ? 'search_prompt'.tr
                : 'search_no_results'.trParams({
                    'query': _controller.text.trim(),
                  }),
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
          for (final row in section.rows) ...[
            _buildRow(section, row),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(_Section section) {
    return Text(
      section.title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2C2520),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
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
