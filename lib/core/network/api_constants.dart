class ApiConstants {
  static const String baseUrl = 'https://dev.saimpexenterprise.com/api/';
  static const String mediaBaseUrl = 'https://dev.saimpexenterprise.com/storage/';

  static const String splash = 'customer/splash';
  static const String sendOtp = 'customer/sendOtp';
  static const String verifyOtp = 'customer/verifyOtp';
  static const String customerCheck = 'customer/customerCheck';
  static const String logout = 'customer/logout';
  static const String profile = 'customer/profile';
  static const String updateProfile = 'customer/updateProfile';
  static const String updateLocation = 'customer/updateLocation';
  static const String fetchLocation = 'customer/fetchLocation';
  static const String pharmacyHome = 'customer/pharmacyHome';
  static const String pharmacyHomeCategories = 'customer/pharmacyHomeCategories';
  static const String pharmacyStore = 'customer/pharmacy/store';
  static const String pharmacyDetails = 'customer/pharmacy/details';
  static const String pharmacyCategories = 'customer/pharmacy/categories';
  static const String pharmacyItems = 'customer/pharmacy/items';
  static const String pharmacyCategoryItems = 'customer/pharmacy/category/items';
  static const String pharmacyCategoryPharmacies =
      'customer/pharmacy/category/pharmacies';
  static const String pharmacyItemDetail = 'customer/pharmacy/item/detail';
  static const String prescriptionPharmacies = 'customer/prescription/pharmacies';
  static const String prescriptionUpload = 'customer/prescription/upload';
  static const String pharmacyOrders = 'customer/orders/pharmacy';
  static const String cartList = 'customer/cart/list';
  static const String foodVendorCategories = 'customer/foodVendorCategories';
  static const String homeHub = 'customer/homeHub';

  static String? mediaUrl(String? path) {
    if (path == null) return null;
    final value = path.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$mediaBaseUrl${value.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
