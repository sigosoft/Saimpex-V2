import 'package:get/get.dart';

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
  }) {
    int parsedPrice = 50;
    if (basePrice is num) {
      parsedPrice = basePrice.toInt();
    } else if (basePrice is String) {
      parsedPrice =
          int.tryParse(basePrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 50;
    }

    lastCartItem = {
      'storeName': storeName,
      'itemName': itemName,
      'itemPortion': itemPortion,
      'basePrice': parsedPrice,
      'itemImage': itemImage,
    };
    cartItemCount.value = 1;
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
}
