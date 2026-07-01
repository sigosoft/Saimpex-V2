import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/toast_helper.dart';
import '../views/home_screen.dart';

class SelectLocationController extends GetxController {
  // Track selected address type: 'Home', 'Office', or 'Other'
  final selectedAddressType = 'Home'.obs;

  // Address description details
  final addressTitle = 'Loading current location...'.obs;
  final addressSubtitle = 'Please approve location access if prompted.'.obs;

  static String selectedTitle = 'Nouakchott, Mauritania';
  static String selectedSubtitle =
      'Marhaba Supermarket, Nouakchott, Mauritania';

  // Search controller
  final searchController = TextEditingController();

  // Google Map Controller & Camera Position
  GoogleMapController? mapController;
  CameraPosition? currentCameraPosition;

  // Default coordinate if location fetching fails
  static const LatLng defaultCenter = LatLng(18.085810, -15.978500);

  void selectAddressType(String type) {
    selectedAddressType.value = type;
  }

  void onContinuePressed() {
    Get.offAll(() => const HomeScreen());
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    getCurrentLocation(); // Fetch current location immediately when map is ready
  }

  void onCameraMove(CameraPosition position) {
    currentCameraPosition = position;
    addressTitle.value = 'Fetching address...';
    addressSubtitle.value =
        'Lat: ${position.target.latitude.toStringAsFixed(6)}, Lng: ${position.target.longitude.toStringAsFixed(6)}';
  }

  void onCameraIdle() {
    if (currentCameraPosition != null) {
      updateAddressFromCoordinates(
        currentCameraPosition!.target.latitude,
        currentCameraPosition!.target.longitude,
      );
    }
  }

  // Convert GPS coordinates into a human-readable street name/city name
  Future<void> updateAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Locality / Neighborhood / City
        String title =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            place.country ??
            'Selected Location';
        if (title.isEmpty) {
          title = 'Selected Location';
        }

        // Detailed address string
        String subtitle = [
          place.street,
          place.subLocality,
          place.locality,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        if (subtitle.isEmpty) {
          subtitle =
              'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
        }

        addressTitle.value = title;
        addressSubtitle.value = subtitle;
        selectedTitle = title;
        selectedSubtitle = subtitle;
      }
    } catch (e) {
      // If geocoding fails (e.g. offline), fallback gracefully to showing coordinates
      addressTitle.value = 'Selected Location';
      addressSubtitle.value =
          'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      selectedTitle = 'Selected Location';
      selectedSubtitle =
          'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }

  // Fetch current GPS location and center camera
  Future<void> getCurrentLocation() async {
    addressTitle.value = 'Loading current location...';
    addressSubtitle.value = 'Fetching GPS coordinates...';

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showAppToast(
          'Location services are disabled. Please enable GPS.',
          backgroundColor: Colors.redAccent,
        );
        _useDefaultFallback();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showAppToast(
            'Location permission denied.',
            backgroundColor: Colors.redAccent,
          );
          _useDefaultFallback();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showAppToast(
          'Location permissions are permanently denied. Please enable them in settings.',
          backgroundColor: Colors.redAccent,
        );
        _useDefaultFallback();
        return;
      }

      // Fetch current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);

      // Update UI with address lookup
      updateAddressFromCoordinates(position.latitude, position.longitude);

      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
      }
    } catch (e) {
      showAppToast(
        'Error fetching current location: $e',
        backgroundColor: Colors.redAccent,
      );
      _useDefaultFallback();
    }
  }

  void _useDefaultFallback() {
    updateAddressFromCoordinates(
      defaultCenter.latitude,
      defaultCenter.longitude,
    );
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(defaultCenter, 16.0),
      );
    }
  }

  // Center camera back to current location
  void centerOnDefaultLocation() {
    getCurrentLocation();
  }

  @override
  void onClose() {
    searchController.dispose();
    mapController?.dispose();
    super.onClose();
  }
}
