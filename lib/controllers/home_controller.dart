import 'package:get/get.dart';

class HomeController extends GetxController {
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

  // List of liked restaurant/grocery item IDs
  final likedItems = <String>[].obs;

  void selectNavigation(int index) {
    currentNavIndex.value = index;
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

  void toggleLike(String itemId) {
    if (likedItems.contains(itemId)) {
      likedItems.remove(itemId);
    } else {
      likedItems.add(itemId);
    }
  }

  bool isLiked(String itemId) {
    return likedItems.contains(itemId);
  }
}
