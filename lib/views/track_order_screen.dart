import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({Key? key, this.orderId = "#22789002"}) : super(key: key);

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  GoogleMapController? _mapController;

  // Store (left) → courier (mid) → home (upper-right), matching the mockup path.
  final LatLng restaurantLoc = const LatLng(18.0836, -15.9802);
  final LatLng riderLoc = const LatLng(18.0858, -15.9768);
  final LatLng homeLoc = const LatLng(18.0884, -15.9746);

  Set<Polyline> _polylines = {};
  Offset? _storeScreen;
  Offset? _riderScreen;
  Offset? _homeScreen;
  bool _updatingPins = false;
  bool _needsPinUpdate = false;

  static const String _lightMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f4efe8"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a7d74"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f4efe8"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#e4efe0"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e6dcd3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f7e7d4"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d5e6ee"}]}
]
''';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMapData());
  }

  Future<void> _initMapData() async {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('delivery_route'),
          points: _curvedRoute(restaurantLoc, riderLoc, homeLoc),
          color: const Color(0xFF3E342F),
          width: 4,
          geodesic: false,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
    });

    await _fitRouteInView();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _updateMarkerScreens();
  }

  Future<void> _updateMarkerScreens() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;
    if (_updatingPins) {
      _needsPinUpdate = true;
      return;
    }
    _updatingPins = true;
    try {
      final dpr = View.of(context).devicePixelRatio;
      final store = await controller.getScreenCoordinate(restaurantLoc);
      final rider = await controller.getScreenCoordinate(riderLoc);
      final home = await controller.getScreenCoordinate(homeLoc);
      if (!mounted) return;
      setState(() {
        _storeScreen = Offset(store.x / dpr, store.y / dpr);
        _riderScreen = Offset(rider.x / dpr, rider.y / dpr);
        _homeScreen = Offset(home.x / dpr, home.y / dpr);
      });
    } finally {
      _updatingPins = false;
      if (_needsPinUpdate) {
        _needsPinUpdate = false;
        _updateMarkerScreens();
      }
    }
  }

  List<LatLng> _curvedRoute(LatLng start, LatLng mid, LatLng end) {
    final c1 = _perpOffset(start, mid, 0.42);
    final c2 = _perpOffset(mid, end, -0.38);
    return [
      ..._quadraticPoints(start, c1, mid, 24),
      ..._quadraticPoints(mid, c2, end, 24).skip(1),
    ];
  }

  LatLng _perpOffset(LatLng a, LatLng b, double factor) {
    final midLat = (a.latitude + b.latitude) / 2;
    final midLng = (a.longitude + b.longitude) / 2;
    final dLat = b.latitude - a.latitude;
    final dLng = b.longitude - a.longitude;
    return LatLng(midLat - dLng * factor, midLng + dLat * factor);
  }

  List<LatLng> _quadraticPoints(LatLng p0, LatLng p1, LatLng p2, int steps) {
    final points = <LatLng>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final u = 1 - t;
      points.add(
        LatLng(
          u * u * p0.latitude + 2 * u * t * p1.latitude + t * t * p2.latitude,
          u * u * p0.longitude + 2 * u * t * p1.longitude + t * t * p2.longitude,
        ),
      );
    }
    return points;
  }

  Future<void> _fitRouteInView() async {
    final controller = _mapController;
    if (controller == null) return;

    final lats = [
      restaurantLoc.latitude,
      riderLoc.latitude,
      homeLoc.latitude,
    ];
    final lngs = [
      restaurantLoc.longitude,
      riderLoc.longitude,
      homeLoc.longitude,
    ];
    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce(math.min) - 0.0008, lngs.reduce(math.min) - 0.0008),
      northeast: LatLng(lats.reduce(math.max) + 0.0008, lngs.reduce(math.max) + 0.0008),
    );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 88));
  }

  Widget _routePin({
    required Offset? screen,
    required IconData icon,
    double size = 34,
  }) {
    if (screen == null) return const SizedBox.shrink();
    return Positioned(
      left: screen.dx - size / 2,
      top: screen.dy - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5E00),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.52),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFFFFDF9),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFFF5E00),
                      size: 15,
                    ),
                  ),
                ),
              ),
              Text(
                'Track Order ${widget.orderId}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Google Map View
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: riderLoc,
                zoom: 15.0,
              ),
              onMapCreated: (controller) async {
                _mapController = controller;
                await _fitRouteInView();
                await _updateMarkerScreens();
              },
              onCameraMove: (_) => _updateMarkerScreens(),
              onCameraIdle: _updateMarkerScreens,
              style: _lightMapStyle,
              polylines: _polylines,
              padding: const EdgeInsets.only(bottom: 280, top: 8),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFFDF9).withValues(alpha: 0),
                      const Color(0xFFFFFDF9).withValues(alpha: 0.55),
                      const Color(0xFFFFFDF9),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          _routePin(
            screen: _storeScreen,
            icon: Icons.restaurant,
            size: 34,
          ),
          _routePin(
            screen: _homeScreen,
            icon: Icons.home_rounded,
            size: 34,
          ),
          _routePin(
            screen: _riderScreen,
            icon: Icons.delivery_dining_rounded,
            size: 48,
          ),

          // 2. Sliding bottom panel card overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.viewPaddingOf(context).bottom + 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5E00),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "ON THE WAY",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ETA text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '12 min',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ETA',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Order tag
                  Text(
                    'Order #22789000 • Salam Supermarket',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7A6A60),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mini stepper progress
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 18,
                        left: 30,
                        right: 30,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                color: const Color(0xFFFF5E00),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: const Color(0xFFFF5E00),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: const Color(0xFFEAD8C9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepperNode(
                            isActive: true,
                            icon: Icons.check,
                            title: "Order placed",
                            time: "22 Oct 2025, 10 AM",
                          ),
                          _buildStepperNode(
                            isActive: true,
                            icon: Icons.shopping_bag_outlined,
                            title: "Picking Items",
                            time: "",
                          ),
                          _buildStepperNode(
                            isActive: true,
                            icon: Icons.delivery_dining_rounded,
                            title: "On the way",
                            time: "",
                          ),
                          _buildStepperNode(
                            isActive: false,
                            icon: Icons.check,
                            title: "Delivered",
                            time: "",
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Your Driver',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 64,
                                  height: 64,
                                  color: const Color(0xFFEAD8C9),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amadou Sy',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFAE00),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '4.6',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2C2520),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    ' (10k + reviews)',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA59A94),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Calling Amadou Sy...',
                                  style: GoogleFonts.outfit(),
                                ),
                                backgroundColor: const Color(0xFFFF5E00),
                              ),
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5E00),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 20,
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
        ],
      ),
    );
  }

  Widget _buildStepperNode({
    required bool isActive,
    required IconData icon,
    required String title,
    required String time,
  }) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF5E00) : const Color(0xFFEAD8C9),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withOpacity(0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: isActive ? const Color(0xFF2C2520) : const Color(0xFFA59A94),
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 6.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
