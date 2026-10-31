import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:saimpex_v2/controllers/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_store.dart';
import '../models/profile_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../views/main_shell_screen.dart';

class SelectLocationController extends GetxController {
  bool isInitialSetup = false;

  /// Opened from Saved Addresses: Continue also saves the spot to the
  /// address book under [selectedAddressType], editing [editAddressId].
  bool saveToAddressBook = false;
  int? editAddressId;

  // Track selected address type: 'Home', 'Office', or 'Other'
  final selectedAddressType = 'Home'.obs;

  // Address description details
  late final addressTitle =
      (selectedTitle.trim().isNotEmpty && !_isPlaceholder(selectedTitle)
              ? selectedTitle
              : 'Loading current location...')
          .obs;
  late final addressSubtitle =
      (selectedSubtitle.trim().isNotEmpty && !_isPlaceholder(selectedSubtitle)
              ? selectedSubtitle
              : 'Please approve location access if prompted.')
          .obs;

  static final deliveryLabel = 'Nouakchott, Mauritania'.obs;
  static String selectedSubtitle =
      'Marhaba Supermarket, Nouakchott, Mauritania';
  static double selectedLatitude = defaultCenter.latitude;
  static double selectedLongitude = defaultCenter.longitude;

  static const _titleKey = 'delivery_title';
  static const _subtitleKey = 'delivery_subtitle';
  static const _latKey = 'delivery_lat';
  static const _lngKey = 'delivery_lng';

  static String get selectedTitle => deliveryLabel.value;
  static set selectedTitle(String value) => deliveryLabel.value = value;

  String? _pickedLabel;
  int _addressRequest = 0;
  int _suppressCamera = 0;
  int _pickDepth = 0;

  // Search controller
  final searchController = TextEditingController();
  final searchText = ''.obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final showSearchResults = false.obs;
  final isSearching = false.obs;

  Timer? _searchDebounce;

  // Google Map Controller & Camera Position
  GoogleMapController? mapController;
  CameraPosition? currentCameraPosition;

  // Default coordinate if location fetching fails
  static const LatLng defaultCenter = LatLng(18.085810, -15.978500);

  final isUpdatingLocation = false.obs;

  void selectAddressType(String type) {
    selectedAddressType.value = type;
  }

  Future<void> onContinuePressed() async {
    if (isUpdatingLocation.value) return;
    _commitDeliveryAddress();

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().loadHome();
    }

    final token = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>().token
        : null;
    if (token == null || token.isEmpty) {
      if (isInitialSetup || Get.key.currentState?.canPop() != true) {
        Get.offAll(() => const MainShellScreen());
      } else {
        Get.back(result: true);
      }
      return;
    }

    isUpdatingLocation.value = true;
    try {
      final profile = Get.find<ProfileRepository>();
      var message = await profile.updateLocation(
        latitude: selectedLatitude,
        longitude: selectedLongitude,
        address: selectedTitle,
        language: apiLanguageCode(),
      );
      if (saveToAddressBook) {
        message = await profile.saveAddress(
          addressId: editAddressId,
          label: selectedAddressType.value,
          address: selectedTitle,
          latitude: selectedLatitude,
          longitude: selectedLongitude,
          language: apiLanguageCode(),
        );
      }
      if (_isDisposed) return;
      showAppToast(message, backgroundColor: const Color(0xFFFF5E00));
      if (isInitialSetup || Get.key.currentState?.canPop() != true) {
        Get.offAll(() => const MainShellScreen());
      } else {
        Get.back(result: true);
      }
    } on ApiException catch (error) {
      if (!_isDisposed) showAppToast(error.message);
    } finally {
      if (!_isDisposed) isUpdatingLocation.value = false;
    }
  }

  static Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString(_titleKey)?.trim() ?? '';
    if (title.isNotEmpty) {
      selectedTitle = title;
    }
    final subtitle = prefs.getString(_subtitleKey)?.trim() ?? '';
    if (subtitle.isNotEmpty) {
      selectedSubtitle = subtitle;
    }
    final latitude = prefs.getDouble(_latKey);
    final longitude = prefs.getDouble(_lngKey);
    if (latitude != null && longitude != null) {
      selectedLatitude = latitude;
      selectedLongitude = longitude;
    }
  }

  static void applyFetchedLocation({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    final title = address.trim();
    if (title.isNotEmpty) {
      selectedTitle = title;
      selectedSubtitle = title;
    }
    if (latitude != null && longitude != null) {
      selectedLatitude = latitude;
      selectedLongitude = longitude;
    }
    if (title.isNotEmpty || (latitude != null && longitude != null)) {
      unawaited(_saveDeliveryAddress());
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (isInitialSetup || !hasValidAddress) {
      getCurrentLocation(); // Fetch current location for initial setup or empty address
    } else {
      updateAddressFromCoordinates(selectedLatitude, selectedLongitude);
    }
  }

  void onCameraMove(CameraPosition position) {
    currentCameraPosition = position;
    if (_suppressCamera > 0 || _pickDepth > 0) return;
    _pickedLabel = null;
    addressTitle.value = 'Fetching address...';
    addressSubtitle.value =
        'Lat: ${position.target.latitude.toStringAsFixed(6)}, Lng: ${position.target.longitude.toStringAsFixed(6)}';
  }

  void onCameraIdle() {
    if (currentCameraPosition == null) return;
    final latitude = currentCameraPosition!.target.latitude;
    final longitude = currentCameraPosition!.target.longitude;
    selectedLatitude = latitude;
    selectedLongitude = longitude;
    if (_suppressCamera > 0 || _pickDepth > 0 || _pickedLabel != null) return;
    updateAddressFromCoordinates(latitude, longitude);
  }

  Future<void> _animateMapTo(LatLng target, double zoom) async {
    if (_isDisposed || mapController == null) return;
    _suppressCamera++;
    try {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, zoom),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (_suppressCamera > 0) _suppressCamera--;
    }
  }

  // Convert GPS coordinates into a human-readable street name/city name
  Future<void> updateAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    final request = ++_addressRequest;
    selectedLatitude = latitude;
    selectedLongitude = longitude;
    if (_pickedLabel != null) return;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (_isDisposed || request != _addressRequest || _pickedLabel != null) {
        return;
      }
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

        addressTitle.value = subtitle.isNotEmpty ? subtitle : title;
        addressSubtitle.value = subtitle;
      }
    } catch (e) {
      if (_isDisposed || request != _addressRequest || _pickedLabel != null) {
        return;
      }
      addressTitle.value = 'Selected Location';
      addressSubtitle.value =
          'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }

  // Fetch current GPS location and center camera
  Future<void> getCurrentLocation() async {
    if (_pickedLabel != null) return;
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

      if (_pickedLabel != null || _isDisposed) return;

      final latLng = LatLng(position.latitude, position.longitude);

      // Update UI with address lookup
      updateAddressFromCoordinates(position.latitude, position.longitude);

      if (_pickedLabel != null || _isDisposed || mapController == null) return;
      unawaited(_animateMapTo(latLng, 16));
    } catch (e) {
      showAppToast(
        'Error fetching current location: $e',
        backgroundColor: Colors.redAccent,
      );
      _useDefaultFallback();
    }
  }

  void _useDefaultFallback() {
    if (_pickedLabel != null) return;
    updateAddressFromCoordinates(
      defaultCenter.latitude,
      defaultCenter.longitude,
    );
    if (!_isDisposed && mapController != null) {
      unawaited(_animateMapTo(defaultCenter, 16));
    }
  }

  // Center camera back to current location
  void centerOnDefaultLocation() {
    getCurrentLocation();
  }

  void onSearchQueryChanged(String query) {
    searchText.value = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      searchAddress(query);
    });
  }

  Future<void> searchAddress(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      searchResults.clear();
      showSearchResults.value = false;
      return;
    }

    isSearching.value = true;
    try {
      final places = await _searchPlaces(trimmed);
      final results = places.isNotEmpty
          ? places
          : await _searchWithGeocoder(trimmed);
      searchResults.assignAll(results);
      showSearchResults.value = results.isNotEmpty;
    } catch (_) {
      searchResults.clear();
      showSearchResults.value = false;
    } finally {
      isSearching.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (!Get.isRegistered<DioClient>()) return const [];

    try {
      final response = await Get.find<DioClient>().dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _mapsApiKey,
          'location':
              '${selectedLatitude.toString()},${selectedLongitude.toString()}',
          'radius': '50000',
        },
      );
      final body = asJsonMap(response.data);
      if (body?['status'] != 'OK') return const [];

      final predictions = body?['predictions'];
      if (predictions is! List) return const [];

      final results = <Map<String, dynamic>>[];
      for (final item in predictions.take(6)) {
        final place = asJsonMap(item);
        final label = place?['description']?.toString().trim() ?? '';
        final placeId = place?['place_id']?.toString() ?? '';
        if (label.isEmpty || placeId.isEmpty) continue;
        results.add({'label': label, 'place_id': placeId});
      }
      return results;
    } on DioException {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchWithGeocoder(String query) async {
    final queries = [
      '$query, Nouakchott, Mauritania',
      '$query, Mauritania',
      query,
    ];

    List<Location> locations = [];
    for (final searchQuery in queries) {
      try {
        locations = await locationFromAddress(searchQuery);
        if (locations.isNotEmpty) break;
      } catch (_) {
        continue;
      }
    }

    if (locations.isEmpty) return const [];

    final results = <Map<String, dynamic>>[];
    for (final location in locations.take(5)) {
      var label = query;
      try {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          label = [
            place.street,
            place.subLocality,
            place.locality,
            place.country,
          ].where((part) => part != null && part.isNotEmpty).join(', ');
          if (label.isEmpty) label = query;
        }
      } catch (_) {
        label = query;
      }

      results.add({
        'label': label,
        'latitude': location.latitude,
        'longitude': location.longitude,
      });
    }
    return results;
  }

  Future<void> selectSearchResult(Map<String, dynamic> result) async {
    showSearchResults.value = false;
    FocusManager.instance.primaryFocus?.unfocus();

    final label = result['label']?.toString().trim() ?? '';
    if (label.isEmpty) return;

    _pickDepth++;
    _rememberDeliveryLabel(label);
    searchController.text = label;

    try {
      var latitude = result['latitude'];
      var longitude = result['longitude'];
      final placeId = result['place_id']?.toString() ?? '';
      if (placeId.isNotEmpty) {
        final coordinates = await _placeCoordinates(placeId);
        if (_pickedLabel != label) return;
        if (coordinates == null) {
          showAppToast('Could not select this address');
          return;
        }
        latitude = coordinates.$1;
        longitude = coordinates.$2;
      }

      if (latitude is! double || longitude is! double) return;
      if (_pickedLabel != label) return;

      final latLng = LatLng(latitude, longitude);
      currentCameraPosition = CameraPosition(target: latLng, zoom: 16);
      _addressRequest++;
      selectedLatitude = latitude;
      selectedLongitude = longitude;
      _rememberDeliveryLabel(label);
      unawaited(_saveDeliveryAddress());

      await _animateMapTo(latLng, 16);
      if (_pickedLabel != label) return;
      _rememberDeliveryLabel(label);
    } finally {
      if (_pickDepth > 0) _pickDepth--;
    }
  }

  void _rememberDeliveryLabel(String label) {
    final chosen = label.trim();
    if (chosen.isEmpty) return;
    _pickedLabel = chosen;
    addressTitle.value = chosen;
    addressSubtitle.value = chosen;
    selectedTitle = chosen;
    selectedSubtitle = chosen;
  }

  void _commitDeliveryAddress() {
    final picked = _pickedLabel?.trim() ?? '';
    final title = addressTitle.value.trim();
    final chosen = picked.isNotEmpty
        ? picked
        : (!_isPlaceholder(title) ? title : '');
    if (chosen.isNotEmpty) {
      selectedTitle = chosen;
      selectedSubtitle = chosen;
    }
    final camera = currentCameraPosition?.target;
    if (camera != null) {
      selectedLatitude = camera.latitude;
      selectedLongitude = camera.longitude;
    }
    unawaited(_saveDeliveryAddress());
  }

  /// The customer's delivery location, for screens that only borrow the map
  /// picker (courier pickup and drop-off) and must put it back afterwards.
  static ({String title, String subtitle, double latitude, double longitude})
  snapshot() => (
    title: selectedTitle,
    subtitle: selectedSubtitle,
    latitude: selectedLatitude,
    longitude: selectedLongitude,
  );

  static void restore(
    ({String title, String subtitle, double latitude, double longitude}) saved,
  ) {
    selectedTitle = saved.title;
    selectedSubtitle = saved.subtitle;
    selectedLatitude = saved.latitude;
    selectedLongitude = saved.longitude;
    unawaited(_saveDeliveryAddress());
  }

  static bool _isPlaceholder(String value) {
    final text = value.trim();
    return text.isEmpty ||
        text.startsWith('Loading') ||
        text.startsWith('Fetching') ||
        text.startsWith('Please approve') ||
        text.startsWith('Lat:');
  }

  static Future<void> _saveDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleKey, selectedTitle);
    await prefs.setString(_subtitleKey, selectedSubtitle);
    await prefs.setDouble(_latKey, selectedLatitude);
    await prefs.setDouble(_lngKey, selectedLongitude);
  }

  Future<(double, double)?> _placeCoordinates(String placeId) async {
    if (!Get.isRegistered<DioClient>()) return null;
    try {
      final response = await Get.find<DioClient>().dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry',
          'key': _mapsApiKey,
        },
      );
      final body = asJsonMap(response.data);
      final location = asJsonMap(
        asJsonMap(asJsonMap(body?['result'])?['geometry'])?['location'],
      );
      final latitude = location?['lat'];
      final longitude = location?['lng'];
      if (latitude is! num || longitude is! num) return null;
      return (latitude.toDouble(), longitude.toDouble());
    } on DioException {
      return null;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
    searchResults.clear();
    showSearchResults.value = false;
  }

  void hideSearchResults() {
    showSearchResults.value = false;
  }

  bool get hasValidAddress {
    final title = addressTitle.value.trim();
    if (title.isEmpty) return false;
    return !title.startsWith('Loading') &&
        !title.startsWith('Fetching') &&
        title != 'Selected Location';
  }

  Map<String, String>? getSelectedAddressResult() {
    if (!hasValidAddress) return null;
    return {
      'title': addressTitle.value,
      'subtitle': addressSubtitle.value,
      'latitude': selectedLatitude.toString(),
      'longitude': selectedLongitude.toString(),
    };
  }

  bool _isDisposed = false;
  static const _mapsApiKey = 'AIzaSyDSJYUxyO9KZHUpbDuvr-W1LxElSxjAWuw';

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _isDisposed = true;
    searchController.dispose();
    mapController?.dispose();
    mapController = null;
    super.onClose();
  }
}
