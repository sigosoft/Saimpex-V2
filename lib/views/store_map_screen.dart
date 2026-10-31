import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/select_location_controller.dart';
import '../widgets/app_back_button.dart';

/// Real stores on Google Maps: a pin per store, a card per store underneath
/// (swiping the cards follows the pins and tapping a pin shows its card), and
/// a search box that filters by name. [stores] are the cards the calling
/// screen already loaded (`title` or `name`, `image`, `rating`, `dist` or
/// `distance_km`, `latitude`, `longitude`); stores without coordinates are
/// left off. [onOpen] opens a store's own screen.
class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({super.key, required this.stores, required this.onOpen});

  final List<Map<String, dynamic>> stores;
  final void Function(Map<String, dynamic> store) onOpen;

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  int _selectedIndex = 0;
  String _query = '';

  static LatLng? _pointOf(Map<String, dynamic> store) {
    final lat = double.tryParse('${store['latitude'] ?? ''}');
    final lng = double.tryParse('${store['longitude'] ?? ''}');
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return LatLng(lat, lng);
  }

  static String _titleOf(Map<String, dynamic> store) =>
      '${store['title'] ?? store['name'] ?? ''}'.trim();

  late final List<Map<String, dynamic>> _mappable = [
    for (final store in widget.stores)
      if (_pointOf(store) != null) store,
  ];

  List<Map<String, dynamic>> get _stores {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _mappable;
    return [
      for (final store in _mappable)
        if (_titleOf(store).toLowerCase().contains(query)) store,
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _query = value;
      _selectedIndex = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    _frameStores();
  }

  void _selectStore(int index) {
    setState(() => _selectedIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _onCardChanged(int index) {
    setState(() => _selectedIndex = index);
    final point = _pointOf(_stores[index]);
    if (point != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(point));
    }
  }

  /// Fits every shown store on screen.
  Future<void> _frameStores() async {
    final controller = _mapController;
    final points = [for (final store in _stores) _pointOf(store)!];
    if (controller == null || points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14),
      );
      return;
    }
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final point in points.skip(1)) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        72,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final stores = _stores;
    final selected = stores.isEmpty
        ? -1
        : _selectedIndex.clamp(0, stores.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECE4),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: stores.isEmpty
                    ? LatLng(
                        SelectLocationController.selectedLatitude,
                        SelectLocationController.selectedLongitude,
                      )
                    : _pointOf(stores.first)!,
                zoom: 13,
              ),
              markers: {
                for (var index = 0; index < stores.length; index++)
                  Marker(
                    markerId: MarkerId('${stores[index]['id']}_$index'),
                    position: _pointOf(stores[index])!,
                    infoWindow: InfoWindow(title: _titleOf(stores[index])),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      index == selected
                          ? BitmapDescriptor.hueOrange
                          : BitmapDescriptor.hueRed,
                    ),
                    zIndexInt: index == selected ? 1 : 0,
                    onTap: () => _selectStore(index),
                  ),
              },
              padding: EdgeInsets.only(
                top: topInset + 60,
                bottom: bottomInset + 140,
              ),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _frameStores();
              },
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                AppBackButton(onTap: () => Get.back()),
                const SizedBox(width: 10),
                Expanded(child: _buildSearchBox()),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 12,
            child: stores.isEmpty
                ? Center(child: _buildEmptyCard())
                : SizedBox(
                    height: 118,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: stores.length,
                      onPageChanged: _onCardChanged,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: _buildStoreCard(stores[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFFA59A94), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'core_store_map_search_hint'.tr,
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
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'core_store_map_empty'.tr,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: const Color(0xFF7A6A60),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final subtitle = '${store['subtitle'] ?? store['category'] ?? ''}'.trim();
    final rating = '${store['rating'] ?? ''}'.trim();
    final km = double.tryParse('${store['distance_km'] ?? ''}');
    final distance = '${store['dist'] ?? ''}'.trim().isNotEmpty
        ? '${store['dist']}'.trim()
        : km == null
        ? ''
        : 'st_km'.trParams({'km': km.toStringAsFixed(1)});

    return GestureDetector(
      onTap: () => widget.onOpen(store),
      child: Container(
        margin: const EdgeInsetsDirectional.only(start: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                '${store['image'] ?? ''}',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 88,
                  height: 88,
                  color: const Color(0xFFF3EFEA),
                  child: const Icon(Icons.store, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _titleOf(store),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (rating.isNotEmpty && rating != '0') ...[
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFF5E00),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(rating, style: _metaStyle),
                        const SizedBox(width: 14),
                      ],
                      if (distance.isNotEmpty) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFF5E00),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(distance, style: _metaStyle),
                      ],
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

  TextStyle get _metaStyle => GoogleFonts.outfit(
    color: const Color(0xFF4A453F),
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}
