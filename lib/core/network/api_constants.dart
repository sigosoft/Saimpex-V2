class ApiConstants {
  static const String baseUrl = 'https://dev.saimpexenterprise.com/api/';
  static const String mediaBaseUrl = 'https://dev.saimpexenterprise.com/storage/';

  static const String sendOtp = 'customer/sendOtp';
  static const String verifyOtp = 'customer/verifyOtp';
  static const String logout = 'customer/logout';
  static const String profile = 'customer/profile';
  static const String updateProfile = 'customer/updateProfile';
  static const String updateLocation = 'customer/updateLocation';
  static const String fetchLocation = 'customer/fetchLocation';
  static const String pharmacyHome = 'customer/pharmacyHome';
  static const String pharmacyStore = 'customer/pharmacy/store';
  static const String pharmacyItemDetail = 'customer/pharmacy/item/detail';
  static const String prescriptionUpload = 'customer/prescription/upload';
  static const String pharmacyOrders = 'customer/orders/pharmacy';
  static const String cartList = 'customer/cart/list';

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
