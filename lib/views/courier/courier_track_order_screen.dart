import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CourierTrackOrderScreen extends StatefulWidget {
  final String orderId;
  final String vehicleLabel;
  final String amount;

  const CourierTrackOrderScreen({
    super.key,
    this.orderId = '#227890011',
    this.vehicleLabel = 'Bike Delivery',
    this.amount = '50 MRU',
  });

  @override
  State<CourierTrackOrderScreen> createState() =>
      _CourierTrackOrderScreenState();
}

class _CourierTrackOrderScreenState extends State<CourierTrackOrderScreen> {
  GoogleMapController? _mapController;

  final LatLng pickupLoc = const LatLng(18.0836, -15.9802);
  final LatLng riderLoc = const LatLng(18.0858, -15.9768);
  final LatLng dropOffLoc = const LatLng(18.0884, -15.9746);

  Set<Polyline> _polylines = {};
  Offset? _pickupScreen;
  Offset? _riderScreen;
  Offset? _dropOffScreen;
  bool _updatingPins = false;
  bool _needsPinUpdate = false;

  static const _steps = [
    _TrackStep(
      label: 'Booking\nConfirmed',
      time: '22 Oct 2025,\n10:00 AM',
      done: true,
      icon: Icons.check_rounded,
    ),
    _TrackStep(
      label: 'At Pickup',
      time: '22 Oct 2025,\n10:05 AM',
      done: true,
      icon: Icons.location_on_outlined,
    ),
    _TrackStep(
      label: 'On the way',
      time: '22 Oct 2025,\n10:10 AM',
      done: true,
      icon: Icons.two_wheeler_rounded,
      useDeliveryIcon: true,
    ),
    _TrackStep(
      label: 'Delivered',
      time: '',
      done: false,
      icon: Icons.check_rounded,
    ),
  ];

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

  String get _displayOrderId =>
      widget.orderId.startsWith('#') ? widget.orderId : '#${widget.orderId}';

  Future<void> _initMapData() async {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('courier_route'),
          points: _curvedRoute(pickupLoc, riderLoc, dropOffLoc),
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
      final pickup = await controller.getScreenCoordinate(pickupLoc);
      final rider = await controller.getScreenCoordinate(riderLoc);
      final dropOff = await controller.getScreenCoordinate(dropOffLoc);
      if (!mounted) return;
      setState(() {
        _pickupScreen = Offset(pickup.x / dpr, pickup.y / dpr);
        _riderScreen = Offset(rider.x / dpr, rider.y / dpr);
        _dropOffScreen = Offset(dropOff.x / dpr, dropOff.y / dpr);
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

    final lats = [pickupLoc.latitude, riderLoc.latitude, dropOffLoc.latitude];
    final lngs = [
      pickupLoc.longitude,
      riderLoc.longitude,
      dropOffLoc.longitude,
    ];
    final bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce(math.min) - 0.0008,
        lngs.reduce(math.min) - 0.0008,
      ),
      northeast: LatLng(
        lats.reduce(math.max) + 0.0008,
        lngs.reduce(math.max) + 0.0008,
      ),
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
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: riderLoc,
                            zoom: 15,
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
                          padding: EdgeInsets.only(
                            bottom: 340 + bottomPad,
                            top: 8,
                          ),
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 120,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.65),
                                    Colors.white,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _routePin(
                          screen: _pickupScreen,
                          icon: Icons.restaurant_rounded,
                        ),
                        _routePin(
                          screen: _dropOffScreen,
                          icon: Icons.home_rounded,
                        ),
                        _routePin(
                          screen: _riderScreen,
                          icon: Icons.two_wheeler_rounded,
                          size: 48,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 16,
              right: 16,
              child: _buildHeader(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomSheet(bottomPad),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAD8C9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
            'Track Order $_displayOrderId',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildBottomSheet(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'ON THE WAY',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '12 min',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ETA',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8C7E75),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.vehicleLabel} • ${widget.amount} • $_displayOrderId',
            style: GoogleFonts.outfit(
              color: const Color(0xFF8C7E75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressTracker(),
          const SizedBox(height: 18),
          Text(
            'Your Driver',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _buildDriverCard(),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const circle = 32.0;
        final usable = constraints.maxWidth - circle;
        final segment = usable / 3;

        return Column(
          children: [
            SizedBox(
              height: circle + 6,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: circle / 2,
                    right: circle / 2,
                    child: Row(
                      children: List.generate(3, (i) {
                        final active = i < 2;
                        return Container(
                          width: segment,
                          height: 3,
                          color: active
                              ? const Color(0xFFFF5E00)
                              : const Color(0xFFE5DDD4),
                        );
                      }),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final step in _steps)
                        Container(
                          width: circle,
                          height: circle,
                          decoration: BoxDecoration(
                            color: step.done
                                ? const Color(0xFFFF5E00)
                                : const Color(0xFFEFE8E1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: step.useDeliveryIcon && step.done
                              ? Image.asset(
                                  'lib/assets/images/delivery_icon.png',
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                  errorBuilder: (_, __, ___) => Icon(
                                    step.icon,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : Icon(
                                  step.icon,
                                  color: step.done
                                      ? Colors.white
                                      : const Color(0xFFB0A59C),
                                  size: 16,
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _steps.map((step) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        step.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: step.done
                              ? const Color(0xFF2C2520)
                              : const Color(0xFFA59A94),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (step.time.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          step.time,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop',
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: const Color(0xFFF3EFEA),
                child: const Icon(Icons.person, color: Color(0xFFFF5E00)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amadou Sy',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFAE00),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '4.6 (10k + reviews)',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackStep {
  final String label;
  final String time;
  final bool done;
  final IconData icon;
  final bool useDeliveryIcon;

  const _TrackStep({
    required this.label,
    required this.time,
    required this.done,
    required this.icon,
    this.useDeliveryIcon = false,
  });
}
