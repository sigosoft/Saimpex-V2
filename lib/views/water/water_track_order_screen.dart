import 'dart:math' as math;
import '../../widgets/app_back_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/order_tracking.dart';
import '../widgets/tracking_widgets.dart';

class WaterTrackOrderScreen extends StatefulWidget {
  final String orderId;
  final String merchantName;

  /// Numeric order id for customer/trackOrder.
  final int? apiOrderId;

  const WaterTrackOrderScreen({
    super.key,
    this.orderId = '',
    this.merchantName = '',
    this.apiOrderId,
  });

  @override
  State<WaterTrackOrderScreen> createState() => _WaterTrackOrderScreenState();
}

class _WaterTrackOrderScreenState extends State<WaterTrackOrderScreen>
    with OrderTrackingMixin<WaterTrackOrderScreen> {
  GoogleMapController? _mapController;

  // Placeholder positions until the first tracking response arrives.
  LatLng storeLoc = const LatLng(18.0836, -15.9802);
  LatLng riderLoc = const LatLng(18.0858, -15.9768);
  LatLng homeLoc = const LatLng(18.0884, -15.9746);

  @override
  void onTrackingUpdated(OrderTracking tracking) {
    final store = tracking.storeLocation ?? storeLoc;
    final home = tracking.deliveryLocation ?? homeLoc;
    // Without a driver location the rider pin waits at the store.
    final rider = tracking.driverLocation ?? store;
    setState(() {
      storeLoc = store;
      homeLoc = home;
      riderLoc = rider;
    });
    _initMapData();
  }

  Set<Polyline> _polylines = {};
  Offset? _storeScreen;
  Offset? _riderScreen;
  Offset? _homeScreen;
  bool _updatingPins = false;
  bool _needsPinUpdate = false;

  static const Color _bg = Color(0xFFFFFDF9);
  static const Color _orange = Color(0xFFFF5E00);

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

  String get _displayId {
    final id = (tracking?.orderCode.isNotEmpty == true
            ? tracking!.orderCode
            : widget.orderId)
        .trim();
    return id.startsWith('#') ? id : '#$id';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMapData();
      startTracking(widget.apiOrderId);
    });
  }

  Future<void> _initMapData() async {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('delivery_route'),
          points: _curvedRoute(storeLoc, riderLoc, homeLoc),
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
      final store = await controller.getScreenCoordinate(storeLoc);
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

    final lats = [storeLoc.latitude, riderLoc.latitude, homeLoc.latitude];
    final lngs = [storeLoc.longitude, riderLoc.longitude, homeLoc.longitude];
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
    bool outlined = false,
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
            color: outlined ? Colors.white : _orange,
            shape: BoxShape.circle,
            border: outlined ? Border.all(color: _orange, width: 2.5) : null,
            boxShadow: [
              BoxShadow(
                color: _orange.withValues(alpha: outlined ? 0.22 : 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: outlined ? _orange : Colors.white,
            size: size * 0.48,
          ),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _bg,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: _bg,
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
                  child: AppBackButton(onTap: () => Get.back()),
                ),
                Text(
                  'Track Order $_displayId',
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
                        _bg.withValues(alpha: 0),
                        _bg.withValues(alpha: 0.55),
                        _bg,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            _routePin(
              screen: _storeScreen,
              icon: Icons.storefront_rounded,
              size: 34,
              outlined: true,
            ),
            _routePin(
              screen: _homeScreen,
              icon: Icons.home_rounded,
              size: 34,
              outlined: true,
            ),
            _routePin(
              screen: _riderScreen,
              icon: Icons.delivery_dining_rounded,
              size: 48,
            ),
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
                  color: const Color(0xFFFDF8F1),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrackingSummary(
                      tracking: tracking,
                      error: trackingError,
                      fallbackOrderCode: widget.orderId,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
