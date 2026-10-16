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
  static const String updateLanguage = 'customer/updateLanguage';
  static const String userPoints = 'customer/userPoints';
  static const String updateLocation = 'customer/updateLocation';
  static const String fetchLocation = 'customer/fetchLocation';
  static const String pharmacyHome = 'customer/pharmacyHome';
  static const String pharmacyHomeCategories = 'customer/pharmacyHomeCategories';
  static const String pharmacySearch = 'customer/pharmacySearch';
  static const String pharmacySearchV2 = 'customer/pharmacySearchV2';
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
  static const String prescriptions = 'customer/prescriptions';
  static String prescriptionById(int id) => 'customer/prescription/$id';
  static String prescriptionPay(int id) => 'customer/prescription/$id/pay';
  static String prescriptionAccept(int id) => 'customer/prescription/$id/accept';
  static const String pharmacyOrders = 'customer/orders/pharmacy';
  static const String cartList = 'customer/cart/list';
  static const String cartListAll = 'customer/cart/listAll';
  static const String cartReplace = 'customer/cart/replace';
  static const String cartUpdate = 'customer/cart/update';
  static const String cartItemDelete = 'customer/cart/item/delete';
  static const String cartPharmacyAdd = 'customer/cart/pharmacy/add';
  static const String cartPharmacyAttachPrescription =
      'customer/cart/pharmacy/attachPrescription';
  static const String checkDeliveryAvailability =
      'customer/checkDeliveryAvailability';
  static const String checkoutSummary = 'customer/checkoutSummary';
  static const String checkoutSummaryV2 = 'customer/checkoutSummaryV2';
  static const String checkout = 'customer/checkout';
  static const String checkoutV2 = 'customer/checkoutV2';
  static const String masrviSession = 'customer/payments/masrvi/session';
  static const String masrviInit = 'customer/payments/masrvi/init';
  static const String orderDetails = 'customer/orderDetails';
  static const String cancelOrder = 'customer/cancelOrder';
  static const String trackOrder = 'customer/trackOrder';
  static const String coupons = 'customer/coupons';
  static const String applyCoupon = 'customer/applyCoupon';
  static const String rating = 'customer/rating';
  static const String submitRating = 'customer/submitRating';
  static const String foodVendorCategories = 'customer/foodVendorCategories';
  static const String restaurantHomeV2 = 'customer/restaurantHomeV2';
  static const String groceryHomeV2 = 'customer/groceryHomeV2';
  static const String groceryHomeCategories = 'customer/groceryHomeCategories';
  static const String groceryVendorCategories = 'customer/groceryVendorCategories';
  static const String groceryDetails = 'customer/grocery/details';
  static const String groceryItems = 'customer/grocery/items';
  static const String homeHub = 'customer/homeHub';
  static const String reviews = 'customer/reviews';
  static const String getAbout = 'customer/getAbout';
  static const String getPrivacyPolicy = 'customer/getPrivacyPolicy';
  static const String getTermsAndConditions = 'customer/getTermsandConditions';
  static const String getContact = 'customer/getContact';

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
