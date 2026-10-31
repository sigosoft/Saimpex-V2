import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../widgets/app_back_button.dart';
import 'pharmacy_items_screen.dart';
import 'widgets/pharmacy_background.dart';

class PharmacyStoresScreen extends StatelessWidget {
  const PharmacyStoresScreen({
    super.key,
    required this.title,
    required this.stores,
    this.categoryId,
  });

  final String title;
  final List<Map<String, dynamic>> stores;
  final int? categoryId;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SizedBox(height: topInset + 10),
            _PharmacyTitleBar(title: title),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 20),
                itemCount: stores.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return _PharmacyStoreTile(
                    store: store,
                    onTap: () => Get.to(
                      () => PharmacyItemsScreen(
                        store: store,
                        initialCategoryId: categoryId,
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
}

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({
    super.key,
    required this.title,
    required this.stores,
  });

  final String title;
  final List<Map<String, dynamic>> stores;

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  int _selectedIndex = 0;
  GoogleMapController? _mapController;

  List<Map<String, dynamic>> get _stores => widget.stores.where((store) {
    return store['latitude'] is num && store['longitude'] is num;
  }).toList();

  LatLng _point(Map<String, dynamic> store) {
    return LatLng(
      (store['latitude'] as num).toDouble(),
      (store['longitude'] as num).toDouble(),
    );
  }

  Future<void> _frameStores() async {
    final controller = _mapController;
    final stores = _stores;
    if (controller == null || stores.isEmpty) return;
    if (stores.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_point(stores.first), 14),
      );
      return;
    }
    var bounds = LatLngBounds(
      southwest: _point(stores.first),
      northeast: _point(stores.first),
    );
    for (final store in stores.skip(1)) {
      final point = _point(store);
      bounds = LatLngBounds(
        southwest: LatLng(
          point.latitude < bounds.southwest.latitude
              ? point.latitude
              : bounds.southwest.latitude,
          point.longitude < bounds.southwest.longitude
              ? point.longitude
              : bounds.southwest.longitude,
        ),
        northeast: LatLng(
          point.latitude > bounds.northeast.latitude
              ? point.latitude
              : bounds.northeast.latitude,
          point.longitude > bounds.northeast.longitude
              ? point.longitude
              : bounds.northeast.longitude,
        ),
      );
    }
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final stores = _stores;
    final selected = stores.isEmpty
        ? null
        : stores[_selectedIndex.clamp(0, stores.length - 1)];

    return PharmacyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SizedBox(height: topInset + 10),
            _PharmacyTitleBar(title: widget.title),
            const SizedBox(height: 12),
            Expanded(
              child: stores.isEmpty
                  ? Center(
                      child: Text(
                        'pw_no_pharmacies_to_show'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _point(stores.first),
                        zoom: 14,
                      ),
                      markers: {
                        for (var index = 0; index < stores.length; index++)
                          Marker(
                            markerId: MarkerId('${stores[index]['id']}_$index'),
                            position: _point(stores[index]),
                            onTap: () => setState(() => _selectedIndex = index),
                          ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _frameStores();
                      },
                    ),
            ),
            if (selected != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
                child: _PharmacyStoreTile(
                  store: selected,
                  onTap: () =>
                      Get.to(() => PharmacyItemsScreen(store: selected)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyTitleBar extends StatelessWidget {
  const _PharmacyTitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppBackButton(onTap: () => Navigator.pop(context)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyStoreTile extends StatelessWidget {
  const _PharmacyStoreTile({required this.store, required this.onTap});

  final Map<String, dynamic> store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = '${store['title'] ?? ''}';
    final subtitle = '${store['subtitle'] ?? ''}';
    final time = '${store['time'] ?? ''}';
    final dist = '${store['dist'] ?? ''}';
    final rating = '${store['rating'] ?? ''}';
    final image = '${store['image'] ?? ''}';

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
                    width: 64,
                    height: 64,
                    child: image.startsWith('http')
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _ImageFallback(),
                          )
                        : const _ImageFallback(),
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
                            color: const Color(0xFFA59A94),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (rating.isNotEmpty) rating,
                          if (time.isNotEmpty) time,
                          if (dist.isNotEmpty) dist,
                        ].join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF3EFEA),
      child: Icon(Icons.local_pharmacy_outlined, color: Color(0xFFA59A94)),
    );
  }
}
