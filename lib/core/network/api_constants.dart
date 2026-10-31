class ApiConstants {
  static const String baseUrl = 'https://dev.saimpexenterprise.com/api/';
  static const String mediaBaseUrl =
      'https://dev.saimpexenterprise.com/storage/';

  static const String splash = 'customer/splash';
  static const String search = 'customer/search';
  static const String imageSearch = 'customer/image-recognition/analyze';
  static const String sendOtp = 'customer/sendOtp';
  static const String verifyOtp = 'customer/verifyOtp';
  static const String customerCheck = 'customer/customerCheck';
  static const String logout = 'customer/logout';
  static const String profile = 'customer/profile';
  static const String updateProfile = 'customer/updateProfile';
  static const String updateLanguage = 'customer/updateLanguage';
  static const String customerDelete = 'customer/delete';
  static const String notificationPreference =
      'customer/notification/preference';
  static const String notifications = 'customer/notifications';
  static const String userPoints = 'customer/userPoints';
  static const String updateLocation = 'customer/updateLocation';
  static const String fetchLocation = 'customer/fetchLocation';
  static const String addresses = 'customer/addresses';
  static const String saveAddress = 'customer/addresses/save';
  static const String deleteAddress = 'customer/addresses/delete';
  static const String favourites = 'customer/favourites';
  static const String toggleFavourite = 'customer/favourites/toggle';
  static const String loyalty = 'customer/loyalty';
  static const String applyReferral = 'customer/referral/apply';
  static const String claimMission = 'customer/missions/claim';
  static const String rewardList = 'customer/rewardList';
  static const String redeemBasket = 'customer/redeemBasket';
  static const String rewardHistory = 'customer/transactionHistory';
  static const String pharmacyHome = 'customer/pharmacyHome';
  static const String pharmacyHomeCategories =
      'customer/pharmacyHomeCategories';
  static const String pharmacySearchV2 = 'customer/pharmacySearchV2';
  static const String pharmacyStore = 'customer/pharmacy/store';
  static const String pharmacyDetails = 'customer/pharmacy/details';
  static const String pharmacyCategories = 'customer/pharmacy/categories';
  static const String pharmacyItems = 'customer/pharmacy/items';
  static const String pharmacyCategoryItems =
      'customer/pharmacy/category/items';
  static const String pharmacyCategoryPharmacies =
      'customer/pharmacy/category/pharmacies';
  static const String pharmacyItemDetail = 'customer/pharmacy/item/detail';
  static const String prescriptionPharmacies =
      'customer/prescription/pharmacies';
  static const String prescriptionUpload = 'customer/prescription/upload';
  static const String prescriptions = 'customer/prescriptions';
  static String prescriptionById(int id) => 'customer/prescription/$id';
  static String prescriptionPay(int id) => 'customer/prescription/$id/pay';
  static String prescriptionAccept(int id) =>
      'customer/prescription/$id/accept';
  static String prescriptionDecline(int id) =>
      'customer/prescription/$id/decline';
  static const String pharmacyOrders = 'customer/orders/pharmacy';
  static const String restaurantOrders = 'customer/orders/restaurant';
  static const String cartList = 'customer/cart/list';
  static const String cartListAll = 'customer/cart/listAll';
  static const String cartReplace = 'customer/cart/replace';
  static const String cartUpdate = 'customer/cart/update';
  static const String cartItemDelete = 'customer/cart/item/delete';
  static const String cartPharmacyAdd = 'customer/cart/pharmacy/add';
  static const String catalogCartAdd = 'customer/catalog/cart/add';
  static const String catalogCartList = 'customer/catalog/cart/list';
  static const String catalogCartItemDelete =
      'customer/catalog/cart/item/delete';
  static const String catalogCartUpdate = 'customer/catalog/cart/update';
  static const String catalogCheckout = 'customer/catalog/checkout';
  static const String catalogOrderDetail = 'customer/catalog/orderDetail';
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
  static const String payAfterDelivery = 'customer/payAfterDelivery';
  static const String preorderWindow = 'customer/preorder/window';
  static const String wallet = 'customer/wallet';
  static const String walletTopUp = 'customer/wallet/topup';
  static String walletTopUpStatus(int id) => 'customer/wallet/topup/$id';
  static String orderPayOnline(int orderId) =>
      'customer/orders/$orderId/payOnline';
  static String payAfterDeliveryPay(int orderId) =>
      'customer/payAfterDelivery/orders/$orderId/pay';
  static const String trackOrder = 'customer/trackOrder';
  static const String coupons = 'customer/coupons';
  static const String applyCoupon = 'customer/applyCoupon';
  static const String rating = 'customer/rating';
  static const String submitRating = 'customer/submitRating';
  static const String foodVendorCategories = 'customer/foodVendorCategories';
  static const String restaurantHomeV2 = 'customer/restaurantHomeV2';
  static const String restaurantSearchV2 = 'customer/restaurantSearchV2';
  static const String restaurantSearch = 'customer/restaurantSearch';
  static const String restaurantBarcodeSearch =
      'customer/restaurantBarcodeSearch';
  static const String restaurantHome = 'customer/restaurantHome';
  static const String restaurantProducts = 'customer/restaurantProducts';
  static const String foodCategories = 'customer/foodCategories';
  static const String restaurantCategories = 'customer/restaurant/categories';
  static const String restaurantItemsSearch =
      'customer/restaurant/items/search';
  static const String restaurantItemsBarcodeSearch =
      'customer/restaurant/items/barcode/search';
  static const String restaurantItemDetail = 'customer/restaurant/item/detail';
  static const String restaurantMenuVariants =
      'customer/restaurant/getMenuItemVariants';
  static const String restaurantMenuTags = 'customer/getRestaurantMenuTags';
  static const String restaurantTags = 'customer/getRestaurantTags';
  static const String restaurantDetails = 'customer/restaurant/details';
  static const String restaurantItems = 'customer/restaurant/items';
  static const String groceryHomeV2 = 'customer/groceryHomeV2';
  static const String groceryHomeCategories = 'customer/groceryHomeCategories';
  static const String groceryVendorCategories =
      'customer/groceryVendorCategories';
  static const String groceryDetails = 'customer/grocery/details';
  static const String groceryItems = 'customer/grocery/items';
  static const String groceryProducts = 'customer/groceryProducts';
  static const String grocerySearch = 'customer/grocerySearch';
  static const String grocerySearchV2 = 'customer/grocerySearchV2';
  static const String groceryBarcodeSearch = 'customer/groceryBarcodeSearch';
  static const String groceryStoreCategories = 'customer/grocery/categories';
  static const String grocerySubCategories = 'customer/grocery/subCategories';
  static const String groceryItemsSearch = 'customer/grocery/items/search';
  static const String groceryItemsBarcodeSearch =
      'customer/grocery/items/barcode/search';
  static const String groceryItemDetail = 'customer/grocery/item/detail';
  static const String groceryMenuVariants =
      'customer/grocery/getMenuItemVariants';
  static const String groceryMenuTags = 'customer/getGroceryMenuTags';
  static const String groceryTags = 'customer/getGroceryTags';
  static const String groceryOrders = 'customer/orders/grocery';
  static const String courierQuote = 'customer/courier/quote';
  static const String courierCreate = 'customer/courier/create';
  static const String courierOrders = 'customer/courier/orders';
  static const String waterHome = 'customer/waterHome';
  static const String waterSearchV2 = 'customer/waterSearchV2';
  static const String waterPlans = 'customer/water/plans';
  static const String waterSubscriptions = 'customer/water/subscriptions';
  static const String waterSubscribe = 'customer/water/subscribe';
  static const String serviceProviders = 'customer/serviceProviders';
  static const String serviceProvider = 'customer/serviceProvider';
  static const String serviceSlots = 'customer/serviceSlots';
  static const String serviceQuote = 'customer/service/quote';
  static const String serviceBook = 'customer/service/book';
  static const String serviceBookings = 'customer/service/bookings';
  static const String serviceBooking = 'customer/service/booking';
  static const String serviceCancel = 'customer/service/cancel';
  static const String waterSubscriptionPause =
      'customer/water/subscription/pause';
  static const String waterSubscriptionResume =
      'customer/water/subscription/resume';
  static const String waterSubscriptionCancel =
      'customer/water/subscription/cancel';
  static const String waterCategories = 'customer/water/categories';
  static const String waterItems = 'customer/water/items';
  static const String waterOrders = 'customer/orders/water';
  static const String cartWaterAdd = 'customer/cart/water/add';
  static const String cartGroceryAdd = 'customer/cart/grocery/add';
  static const String cartGroceryRemove = 'customer/cart/grocery/remove';
  static const String localStoreHome = 'customer/localStoreHome';
  static const String localStoreDetails = 'customer/localStore/details';
  static const String localStoreCategories = 'customer/localStore/categories';
  static const String localStoreSubCategories =
      'customer/localStore/subCategories';
  static const String localStoreItems = 'customer/localStore/items';
  static const String localStoreItemsSearch =
      'customer/localStore/items/search';
  static const String localStoreItemsBarcodeSearch =
      'customer/localStore/items/barcode/search';
  static const String localStoreItemDetail = 'customer/localStore/item/detail';
  static const String localStoreMenuVariants =
      'customer/localStore/getMenuItemVariants';
  static const String cartLocalStoreAdd = 'customer/cart/localStore/add';
  static const String cartLocalStoreRemove = 'customer/cart/localStore/remove';
  static const String localStoreOrders = 'customer/orders/localStore';
  static const String expressHome = 'customer/expressHome';
  static const String homeHub = 'customer/homeHub';
  static const String reviews = 'customer/reviews';
  static const String getAbout = 'customer/getAbout';
  static const String getPrivacyPolicy = 'customer/getPrivacyPolicy';
  static const String getTermsAndConditions = 'customer/getTermsandConditions';
  static const String getContact = 'customer/getContact';
  static const String chatAllConversations = 'customer/chat/allConversations';
  static const String chatGetConversation = 'customer/chat/getConversation';
  static const String chatSendMessage = 'customer/chat/sendMessage';

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
