import 'dart:math' as math;
import '../../widgets/app_back_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/order_tracking.dart';
import '../widgets/tracking_widgets.dart';

class CourierTrackOrderScreen extends StatefulWidget {
  final String orderId;

  /// Numeric order id for customer/trackOrder.
  final int? apiOrderId;

  const CourierTrackOrderScreen({
    super.key,
    this.orderId = '',
    this.apiOrderId,
  });

  @override
  State<CourierTrackOrderScreen> createState() =>
      _CourierTrackOrderScreenState();
}

class _CourierTrackOrderScreenState extends State<CourierTrackOrderScreen>
    with OrderTrackingMixin<CourierTrackOrderScreen> {
  GoogleMapController? _mapController;

  // Placeholder positions until the first tracking response arrives.
  LatLng pickupLoc = const LatLng(18.0836, -15.9802);
  LatLng riderLoc = const LatLng(18.0858, -15.9768);
  LatLng dropOffLoc = const LatLng(18.0884, -15.9746);

  @override
  void onTrackingUpdated(OrderTracking tracking) {
    final pickup = tracking.pickup.location ?? pickupLoc;
    final dropOff =
        tracking.dropoff.location ?? tracking.deliveryLocation ?? dropOffLoc;
    // Without a driver location the rider pin waits at the pickup.
    final rider = tracking.driverLocation ?? pickup;
    setState(() {
      pickupLoc = pickup;
      dropOffLoc = dropOff;
      riderLoc = rider;
    });
    _initMapData();
  }

  Set<Polyline> _polylines = {};
  Offset? _pickupScreen;
  Offset? _riderScreen;
  Offset? _dropOffScreen;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMapData();
      startTracking(widget.apiOrderId);
    });
  }

  String get _displayOrderId {
    final id = (tracking?.orderCode.isNotEmpty == true
            ? tracking!.orderCode
            : widget.orderId)
        .trim();
    return id.startsWith('#') ? id : '#$id';
  }

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
          u * u * p0.longitude +
              2 * u * t * p1.longitude +
              t * t * p2.longitude,
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
        systemNavigationBarColor: Color(0xFFFFFDF9),
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
                            bottom: 300 + bottomPad,
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
                          height: 220,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(
                                      0xFFFFFDF9,
                                    ).withValues(alpha: 0),
                                    const Color(
                                      0xFFFFFDF9,
                                    ).withValues(alpha: 0.55),
                                    const Color(0xFFFFFDF9),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _routePin(
                          screen: _pickupScreen,
                          icon: Icons.inventory_2_rounded,
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
            // Bottom panel — same floating cream card pattern as food Track Order
            Align(
              alignment: Alignment.bottomCenter,
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
        AppBackButton(onTap: () => Get.back()),
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
      margin: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: TrackingSummary(
        tracking: tracking,
        error: trackingError,
        fallbackOrderCode: widget.orderId,
        preparingLabel: 'Accepted',
      ),
    );
  }
}
