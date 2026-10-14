import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'select_location_controller.dart';
import '../core/network/api_exception.dart';
import '../models/general_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';

class HomeController extends GetxController {
  static const int navHome = 0;
  static const int navChat = 1;
  static const int navBookings = 2;
  static const int navServices = 3;
  static const int navOrders = 4;
  static const int navCart = 5;
  static const int navProfile = 6;
  static const int navMaxIndex = 6;

  // Active bottom navigation index
  final currentNavIndex = 0.obs;

  // Active service category index (All, Food, Grocery, etc.)
  final selectedCategoryIndex = 0.obs;

  // Active subcategory index inside CategoryScreen (All, Meals, Breakfast, etc.)
  final selectedSubcategoryIndex = 0.obs;

  // Top banner slider active index
  final bannerSliderIndex = 0.obs;

  // Grocery mid-page banner slider active index
  final groceryBannerSliderIndex = 0.obs;

  // Water mid-page banner slider active index
  final waterBannerSliderIndex = 0.obs;

  // Pharmacy mid-page banner slider active index
  final pharmacyBannerSliderIndex = 0.obs;

  /// Favourited stores/restaurants with full card data for My Favourites.
  final favourites = <Map<String, dynamic>>[].obs;

  /// Kept in sync for any legacy ID-only checks.
  final likedItems = <String>[].obs;

  /// When >= 0, [MyOrdersScreen] opens on this category once then resets.
  final pendingOrdersCategoryIndex = (-1).obs;

  /// Active cart items count for bottom navigation badge.
  final cartItemCount = 0.obs;

  /// Active cart product details so that tapping Cart in bottom navigation bar displays the added product.
  Map<String, dynamic>? lastCartItem;

  int get favouritesCount => favourites.length;

  void updateCartItemCount(int count) {
    cartItemCount.value = count < 0 ? 0 : count;
    if (count == 0) {
      lastCartItem = null;
    }
  }

  void setCartItem({
    String? storeName,
    String? itemName,
    String? itemPortion,
    dynamic basePrice,
    String? itemImage,
    int quantity = 1,
  }) {
    int parsedPrice = 50;
    if (basePrice is num) {
      parsedPrice = basePrice.toInt();
    } else if (basePrice is String) {
      parsedPrice =
          int.tryParse(basePrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 50;
    }

    final count = quantity < 1 ? 1 : quantity;
    lastCartItem = {
      'storeName': storeName,
      'itemName': itemName,
      'itemPortion': itemPortion,
      'basePrice': parsedPrice,
      'itemImage': itemImage,
    };
    cartItemCount.value = count;
  }

  void clearCart() {
    lastCartItem = null;
    cartItemCount.value = 0;
  }

  void selectNavigation(int index) {
    currentNavIndex.value = index;
  }

  void goToOrdersTab({int categoryIndex = 0}) {
    pendingOrdersCategoryIndex.value = categoryIndex;
    selectNavigation(navOrders);
  }

  int consumePendingOrdersCategory(int fallback) {
    final pending = pendingOrdersCategoryIndex.value;
    pendingOrdersCategoryIndex.value = -1;
    if (pending < 0) return fallback;
    return pending;
  }

  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
  }

  void selectSubcategory(int index) {
    selectedSubcategoryIndex.value = index;
  }

  void updateBannerIndex(int index) {
    bannerSliderIndex.value = index;
  }

  void updateGroceryBannerIndex(int index) {
    groceryBannerSliderIndex.value = index;
  }

  void updateWaterBannerIndex(int index) {
    waterBannerSliderIndex.value = index;
  }

  void updatePharmacyBannerIndex(int index) {
    pharmacyBannerSliderIndex.value = index;
  }

  void toggleLike(String itemId, [Map<String, dynamic>? item]) {
    if (itemId.isEmpty) return;

    final existingIndex = favourites.indexWhere(
      (e) => (e['id'] ?? '').toString() == itemId,
    );

    if (existingIndex >= 0) {
      favourites.removeAt(existingIndex);
      likedItems.remove(itemId);
    } else {
      final data = Map<String, dynamic>.from(item ?? {});
      data['id'] = itemId;
      if (data['title'] == null && data['name'] != null) {
        data['title'] = data['name'];
      }
      if (data['subtitle'] == null) {
        data['subtitle'] =
            data['category'] ?? data['subtitle'] ?? '';
      }
      data.putIfAbsent('title', () => 'Favourite');
      data.putIfAbsent('subtitle', () => '');
      data.putIfAbsent('rating', () => '4.5');
      data.putIfAbsent('time', () => '30–35 min');
      data.putIfAbsent('dist', () => '10 Km');
      data.putIfAbsent('discount', () => '50% OFF');
      data.putIfAbsent('points', () => '200 Points Available');
      data.putIfAbsent(
        'image',
        () =>
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&auto=format&fit=crop',
      );
      favourites.add(data);
      if (!likedItems.contains(itemId)) {
        likedItems.add(itemId);
      }
    }
  }

  bool isLiked(String itemId) {
    return favourites.any((e) => (e['id'] ?? '').toString() == itemId);
  }

  final homeLoaded = false.obs;
  final homeLoading = false.obs;
  final walletBalance = ''.obs;
  final walletCurrency = ''.obs;
  final unreadNotifications = 0.obs;
  final profileImage = ''.obs;
  final homeVerticals = <Map<String, dynamic>>[].obs;
  final homeSliders = <Map<String, dynamic>>[].obs;
  final homePromos = <Map<String, dynamic>>[].obs;
  final homeTrending = <Map<String, dynamic>>[].obs;
  final homeRecentOrders = <Map<String, dynamic>>[].obs;
  final homeUnder30 = <Map<String, dynamic>>[].obs;
  final homeTopGrocery = <Map<String, dynamic>>[].obs;
  final homeTrusted = <Map<String, dynamic>>[].obs;
  final homeSuppliers = <Map<String, dynamic>>[].obs;
  final homeBanners = <Map<String, dynamic>>[].obs;
  final homeSections = <String, Map<String, String>>{}.obs;

  int _homeRequest = 0;

  String get walletLabel {
    final amount = walletBalance.value.trim();
    final currency = walletCurrency.value.trim();
    if (amount.isEmpty) return currency;
    if (currency.isEmpty) return amount;
    return '$amount $currency';
  }

  String sectionTitle(String key) => homeSections[key]?['title'] ?? '';

  String sectionSeeAll(String key) => homeSections[key]?['seeAll'] ?? '';

  Map<String, dynamic>? bannerFor(String section) {
    for (final banner in homeBanners) {
      if (banner['section'] == section) return banner;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    loadHome();
  }

  Future<void> loadHome() async {
    if (!Get.isRegistered<GeneralRepository>()) return;
    final request = ++_homeRequest;
    if (!homeLoaded.value) homeLoading.value = true;
    try {
      final home = await Get.find<GeneralRepository>().fetchHome(
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
      );
      if (request != _homeRequest) return;
      _applyHomeLocation(home);
      walletBalance.value = home['walletBalance']?.toString() ?? '';
      walletCurrency.value = home['walletCurrency']?.toString() ?? '';
      unreadNotifications.value = home['unreadNotifications'] as int? ?? 0;
      profileImage.value = home['profileImage']?.toString() ?? '';
      homeVerticals.assignAll(_maps(home['verticals']));
      homeSliders.assignAll(_maps(home['sliders']));
      homePromos.assignAll(_maps(home['promos']));
      homeTrending.assignAll(_maps(home['trending']));
      homeRecentOrders.assignAll(_maps(home['recentOrders']));
      homeUnder30.assignAll(_maps(home['under30']));
      homeTopGrocery.assignAll(_maps(home['topGrocery']));
      homeTrusted.assignAll(_maps(home['trustedPharmacies']));
      homeSuppliers.assignAll(_maps(home['topSuppliers']));
      homeBanners.assignAll(_maps(home['banners']));
      final sections = home['sections'];
      homeSections.clear();
      if (sections is Map) {
        sections.forEach((key, value) {
          if (value is Map) {
            homeSections[key.toString()] = {
              'title': value['title']?.toString() ?? '',
              'seeAll': value['seeAll']?.toString() ?? '',
            };
          }
        });
      }
      homeLoaded.value = true;
    } on ApiException catch (error) {
      if (request != _homeRequest) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (request == _homeRequest) homeLoading.value = false;
    }
  }

  void _applyHomeLocation(Map<String, dynamic> home) {
    final address = home['locationAddress']?.toString().trim() ?? '';
    final city = home['locationCity']?.toString().trim() ?? '';
    final latitude = home['locationLatitude'] as double?;
    final longitude = home['locationLongitude'] as double?;
    final label = address.isNotEmpty
        ? address
        : city.isNotEmpty
        ? city
        : (latitude != null && longitude != null)
        ? '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'
        : '';
    if (label.isEmpty && latitude == null && longitude == null) return;
    SelectLocationController.applyFetchedLocation(
      address: label,
      latitude: latitude,
      longitude: longitude,
    );
  }

  List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
