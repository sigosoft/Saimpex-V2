import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_detail_screen.dart';
import 'order_updated_detail_screen.dart';
import 'water/water_order_details_screen.dart';
import 'courier/courier_order_detail_screen.dart';
import 'courier/courier_track_order_screen.dart';
import 'water/water_track_order_screen.dart';
import 'rate_order_screen.dart';
import 'pharmacy/my_prescriptions_screen.dart';
import 'pharmacy/widgets/pharmacy_order_cards.dart';
import '../core/network/api_exception.dart';
import '../models/grocery_repository.dart';
import 'pharmacy/pharmacy_item_order_detail_screen.dart';
import '../models/courier_repository.dart';
import '../models/food_repository.dart';
import '../models/order_repository.dart';
import '../models/pharmacy_repository.dart';
import '../models/water_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../controllers/home_controller.dart';
import '../constants/text_styles.dart';
import '../widgets/app_back_button.dart';
import '../widgets/home_background_blend.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';

class MyOrdersScreen extends StatefulWidget {
  final bool showBottomNav;
  final int initialCategoryIndex;

  const MyOrdersScreen({
    super.key,
    this.showBottomNav = true,
    this.initialCategoryIndex = 0,
  });

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // Matches design: All, Food, Pharmacy, Water, Courier, Local Store
  late int selectedCategoryIndex;
  // Translation keys; tabs are matched by index, never by text.
  final List<String> categories = [
    'orders_filter_all',
    'search_vertical_food',
    'search_vertical_grocery',
    'search_vertical_pharmacy',
    'search_vertical_water',
    'orders_cat_courier',
    'search_vertical_local_store',
  ];
  Worker? _ordersCategoryWorker;
  Worker? _navWorker;
  List<Map<String, dynamic>> _pharmacyOrders = const [];
  bool _pharmacyOrdersLoading = false;
  List<Map<String, dynamic>> _restaurantOrders = const [];
  bool _restaurantOrdersLoading = false;
  List<Map<String, dynamic>> _groceryOrders = const [];
  // Grocery order id → store proposals waiting and amount due.
  Map<int, ({int pending, num due})> _groceryChanges = const {};
  bool _groceryOrdersLoading = false;
  List<Map<String, dynamic>> _waterOrders = const [];
  bool _waterOrdersLoading = false;
  List<Map<String, dynamic>> _courierOrders = const [];
  bool _courierOrdersLoading = false;
  List<Map<String, dynamic>> _localStoreOrders = const [];
  bool _localStoreOrdersLoading = false;

  @override
  void initState() {
    super.initState();
    _applyInitialCategory();
    _loadPharmacyOrders();
    _loadRestaurantOrders();
    _loadGroceryOrders();
    _loadWaterOrders();
    _loadCourierOrders();
    _loadLocalStoreOrders();
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      _ordersCategoryWorker = ever<int>(home.pendingOrdersCategoryIndex, (
        pending,
      ) {
        if (pending < 0 || !mounted) return;
        setState(() {
          selectedCategoryIndex = pending.clamp(0, categories.length - 1);
        });
        home.pendingOrdersCategoryIndex.value = -1;
      });
      // Orders placed since the last visit must show up when the tab opens.
      _navWorker = ever<int>(home.currentNavIndex, (index) {
        if (index == HomeController.navOrders && mounted) _reloadOrders();
      });
    }
  }

  void _reloadOrders() {
    _loadPharmacyOrders();
    _loadRestaurantOrders();
    _loadGroceryOrders();
    _loadWaterOrders();
    _loadCourierOrders();
    _loadLocalStoreOrders();
  }

  /// customer/orders/localStore, through the local-store GroceryRepository
  /// (same order shape as grocery).
  Future<void> _loadLocalStoreOrders() async {
    if (!Get.isRegistered<GroceryRepository>(
      tag: GroceryRepository.localStoreTag,
    )) {
      return;
    }
    setState(() => _localStoreOrdersLoading = true);
    try {
      final repository = Get.find<GroceryRepository>(
        tag: GroceryRepository.localStoreTag,
      );
      final language = apiLanguageCode();
      final first = await repository.fetchGroceryOrders(language: language);
      final orders = [...first.orders];
      var page = first.currentPage;
      var lastPage = first.lastPage;
      while (page < lastPage && page < 5) {
        page += 1;
        final next = await repository.fetchGroceryOrders(
          language: language,
          page: page,
        );
        orders.addAll(next.orders);
        lastPage = next.lastPage;
      }
      if (!mounted) return;
      setState(() => _localStoreOrders = orders);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _localStoreOrdersLoading = false);
    }
  }

  @override
  void dispose() {
    _ordersCategoryWorker?.dispose();
    _navWorker?.dispose();
    super.dispose();
  }

  void _applyInitialCategory() {
    final fallback = widget.initialCategoryIndex.clamp(
      0,
      categories.length - 1,
    );
    if (Get.isRegistered<HomeController>()) {
      selectedCategoryIndex = Get.find<HomeController>()
          .consumePendingOrdersCategory(fallback)
          .clamp(0, categories.length - 1);
    } else {
      selectedCategoryIndex = fallback;
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }

    BottomNavRouter.returnToShell(tabIndex: HomeController.navOrders);
  }

  @override
  Widget build(BuildContext context) {
    return HomeBackgroundBlend(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: widget.showBottomNav
                      ? AppBackButton(onTap: () => _handleBack(context))
                      : const SizedBox(width: 38),
                ),
                Text('orders_my_orders'.tr, style: AppTextStyles.heading()),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            // Scrollable content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: 110,
                ), // extra padding for bottom nav bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Horizontal Category Pills
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final isSelected = selectedCategoryIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsetsDirectional.only(end: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFF5E00)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF5E00)
                                      : const Color(0xFFEAD8C9),
                                  width: 0.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                categories[index].tr,
                                style: GoogleFonts.outfit(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF8A7F77),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Orders Cards List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: selectedCategoryIndex == 0
                          ? _buildAllOrders()
                          : selectedCategoryIndex == 1
                          ? _buildFoodOrders()
                          : selectedCategoryIndex == 2
                          ? _buildGroceryOrders()
                          : selectedCategoryIndex == 3
                          ? _buildPharmacyOrders()
                          : selectedCategoryIndex == 4
                          ? _buildWaterOrders()
                          : selectedCategoryIndex == 5
                          ? _buildCourierOrders()
                          : _buildOtherCategoryOrders(),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Bottom Navigation Bar
            if (widget.showBottomNav)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNavBar(
                  selectedIndex: HomeController.navOrders,
                  onTap: BottomNavRouter.go,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOrders() {
    return Column(
      children: [
        _buildFoodOrders(),
        _buildGroceryOrders(),
        _buildPharmacyOrders(),
        _buildWaterOrders(),
        _buildCourierOrders(),
        _buildOtherCategoryOrders(),
      ],
    );
  }

  Future<void> _loadGroceryOrders() async {
    if (!Get.isRegistered<GroceryRepository>()) return;
    setState(() => _groceryOrdersLoading = true);
    try {
      final repository = Get.find<GroceryRepository>();
      final language = apiLanguageCode();
      final first = await repository.fetchGroceryOrders(language: language);
      final orders = [...first.orders];
      var page = first.currentPage;
      var lastPage = first.lastPage;
      while (page < lastPage && page < 5) {
        page += 1;
        final next = await repository.fetchGroceryOrders(
          language: language,
          page: page,
        );
        orders.addAll(next.orders);
        lastPage = next.lastPage;
      }
      if (!mounted) return;
      setState(() => _groceryOrders = orders);
      _loadGroceryChanges(orders);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _groceryOrdersLoading = false);
    }
  }

  /// For active grocery orders: proposals waiting for an answer and any
  /// amount due from a pricier substitute (orders/{id}/substitutions).
  Future<void> _loadGroceryChanges(List<Map<String, dynamic>> orders) async {
    if (!Get.isRegistered<OrderRepository>()) return;
    final changes = <int, ({int pending, num due})>{};
    for (final order in orders) {
      final id = order['numericOrderId'];
      if (id is! int ||
          order['isCancelled'] == true ||
          order['isDelivered'] == true) {
        continue;
      }
      try {
        final data = await Get.find<OrderRepository>().substitutions(
          orderId: id,
          language: apiLanguageCode(),
        );
        final rows = data['substitutions'];
        final pending = rows is List
            ? rows.whereType<Map>().where((row) => row['status'] == 'pending')
            : const <Map>[];
        final due = num.tryParse('${data['amount_due'] ?? ''}') ?? 0;
        if (pending.isNotEmpty || due > 0) {
          changes[id] = (pending: pending.length, due: due);
        }
      } on ApiException {
        // An order without substitutions just shows its normal buttons.
      }
    }
    if (mounted) setState(() => _groceryChanges = changes);
  }

  Future<void> _openGroceryChanges(Map<String, dynamic> order) async {
    await Get.to(
      () => OrderUpdatedDetailScreen(
        orderId: order['numericOrderId'] as int,
        orderCode: '${order['orderId'] ?? ''}',
        storeName: '${order['restaurantName'] ?? ''}',
      ),
    );
    if (mounted) _loadGroceryOrders();
  }

  Widget _buildGroceryOrders() {
    if (_groceryOrdersLoading && _groceryOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    }
    if (_groceryOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'orders_no_orders'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [for (final order in _groceryOrders) _groceryOrderCard(order)],
    );
  }

  /// A grocery order card, laid out as in the design: store, status, one details
  /// line, Cancel and Track Order, and a link to the order details.
  Widget _groceryOrderCard(Map<String, dynamic> order) {
    final statusText = '${order['statusText'] ?? ''}';
    final cancelled = order['isCancelled'] == true;
    final delivered = order['isDelivered'] == true;
    final badge = _pharmacyStatusColors(statusText, cancelled);
    final details = [
      order['isSelfPickup'] == true ? 'orders_pickup'.tr : 'orders_delivery'.tr,
      if ('${order['totalText'] ?? ''}'.isNotEmpty) '${order['totalText']}',
      if ((order['itemsCount'] is int) && (order['itemsCount'] as int) > 0)
        'orders_items_count'.trParams({'count': '${order['itemsCount']}'}),
      if ('${order['orderId'] ?? ''}'.isNotEmpty) '${order['orderId']}',
    ].join(' • ');

    return _buildOrderCard(
      restaurantName:
          '${order['restaurantName'] ?? 'search_vertical_grocery'.tr}',
      statusText: statusText,
      statusColor: badge.$1,
      statusBgColor: badge.$2,
      detailsText: details,
      onDetailsLink: () => _showGroceryOrderDetail(order),
      buttons: [
        if (!delivered && !cancelled) ...[
          // The store proposed changes (or a substitute left an amount due):
          // reviewing them comes first.
          if (_groceryChanges.containsKey(order['numericOrderId']))
            _buildOrderButton(
              text: 'subs_review'.tr,
              onTap: () => _openGroceryChanges(order),
            )
          else
            _buildOrderButton(
              text: 'cancel'.tr,
              onTap: () => _cancelRestaurantOrder(order),
            ),
          const SizedBox(width: 12),
          _buildGradientButton(
            text: 'orders_track_order_btn'.tr,
            onTap: () => _trackRestaurantOrder(order),
          ),
        ] else if (delivered)
          _buildOrderButton(
            text: 'orders_rate'.tr,
            onTap: () => Get.to(
              () => RateOrderScreen(orderId: order['numericOrderId'] as int?),
            ),
          ),
      ],
    );
  }

  Future<void> _loadRestaurantOrders() async {
    if (!Get.isRegistered<FoodRepository>()) return;
    setState(() => _restaurantOrdersLoading = true);
    try {
      final repository = Get.find<FoodRepository>();
      final language = apiLanguageCode();
      final first = await repository.fetchRestaurantOrders(language: language);
      final orders = [...first.orders];
      var page = first.currentPage;
      var lastPage = first.lastPage;
      while (page < lastPage && page < 5) {
        page += 1;
        final next = await repository.fetchRestaurantOrders(
          language: language,
          page: page,
        );
        orders.addAll(next.orders);
        lastPage = next.lastPage;
      }
      if (!mounted) return;
      setState(() => _restaurantOrders = orders);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _restaurantOrdersLoading = false);
    }
  }

  Widget _buildFoodOrders() {
    if (_restaurantOrdersLoading && _restaurantOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    }
    if (_restaurantOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'orders_no_orders'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final order in _restaurantOrders) _restaurantOrderCard(order),
      ],
    );
  }

  /// Tapping the card opens the order details; the buttons inside keep their own taps.
  Widget _restaurantOrderCard(Map<String, dynamic> order) {
    return GestureDetector(
      onTap: () => _showRestaurantOrderDetail(order),
      child: _restaurantOrderCardContent(order),
    );
  }

  Widget _restaurantOrderCardContent(Map<String, dynamic> order) {
    final statusText = '${order['statusText'] ?? ''}';
    final cancelled = order['isCancelled'] == true;
    final delivered = order['isDelivered'] == true;
    final orderId = '${order['orderId'] ?? ''}';
    final badge = _pharmacyStatusColors(statusText, cancelled);
    final details = [
      order['isSelfPickup'] == true ? 'orders_pickup'.tr : 'orders_delivery'.tr,
      if ('${order['totalText'] ?? ''}'.isNotEmpty) '${order['totalText']}',
      if ((order['itemsCount'] is int) && (order['itemsCount'] as int) > 0)
        'orders_items_count'.trParams({'count': '${order['itemsCount']}'}),
      if (orderId.isNotEmpty) orderId,
    ].join(' • ');

    return _buildOrderCard(
      restaurantName: '${order['restaurantName'] ?? 'orders_restaurant'.tr}',
      statusText: statusText,
      statusColor: badge.$1,
      statusBgColor: badge.$2,
      detailsText: details,
      onDetailsLink: () => _showRestaurantOrderDetail(order),
      buttons: [
        if (delivered)
          _buildOrderButton(
            text: 'orders_rate'.tr,
            onTap: () => Get.to(
              () => RateOrderScreen(orderId: order['numericOrderId'] as int?),
            ),
          )
        else if (!cancelled) ...[
          _buildOrderButton(
            text: 'cancel'.tr,
            onTap: () => _cancelRestaurantOrder(order),
          ),
          const SizedBox(width: 12),
          _buildGradientButton(
            text: 'orders_track_order_btn'.tr,
            onTap: () => _trackRestaurantOrder(order),
          ),
        ],
      ],
    );
  }

  int? _restaurantOrderId(Map<String, dynamic> order) {
    final orderId = order['numericOrderId'];
    return orderId is int && orderId > 0 ? orderId : null;
  }

  Future<void> _trackRestaurantOrder(Map<String, dynamic> order) async {
    final orderId = _restaurantOrderId(order);
    if (orderId == null) {
      showAppToast('orders_tracking_unavailable'.tr);
      return;
    }
    try {
      final tracking = await Get.find<OrderRepository>().trackOrder(
        orderId: orderId,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _TrackingSheet(detail: tracking),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  Future<void> _cancelRestaurantOrder(Map<String, dynamic> order) async {
    final orderId = _restaurantOrderId(order);
    if (orderId == null) {
      showAppToast('orders_cannot_cancel'.tr);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('orders_cancel_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('orders_no'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('orders_yes_cancel'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final message = await Get.find<OrderRepository>().cancelOrder(
        orderId: orderId,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      showAppToast(
        message.isEmpty ? 'orders_cancelled_title'.tr : message,
        backgroundColor: const Color(0xFFFF5E00),
      );
      _loadRestaurantOrders();
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  /// Grocery orders are general orders, so the shared order-detail screen loads them.
  void _showGroceryOrderDetail(Map<String, dynamic> order) {
    final orderId = order['numericOrderId'];
    if (orderId is! int || orderId < 1) {
      showAppToast('orders_details_unavailable'.tr);
      return;
    }
    Get.to(
      () => PharmacyItemOrderDetailScreen(
        orderId: '${order['orderId']}',
        apiOrderId: orderId,
        isDelivery: order['isSelfPickup'] != true,
        storeName: order['restaurantName']?.toString(),
      ),
    );
  }

  Future<void> _showRestaurantOrderDetail(Map<String, dynamic> order) async {
    final orderId = order['numericOrderId'];
    if (orderId is! int || orderId < 1) {
      showAppToast('orders_details_unavailable'.tr);
      return;
    }
    try {
      final detail = await Get.find<OrderRepository>().catalogOrderDetail(
        orderId: orderId,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      // catalogOrderDetail already returns the order fields, not the envelope
      final orderCode = detail['order_code'];
      if (orderCode == null) {
        showAppToast('orders_details_unavailable'.tr);
        return;
      }
      Get.to(() => OrderDetailScreen(orderId: '$orderCode', detail: detail));
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  Future<void> _loadPharmacyOrders() async {
    if (!Get.isRegistered<PharmacyRepository>()) return;
    setState(() => _pharmacyOrdersLoading = true);
    try {
      final repository = Get.find<PharmacyRepository>();
      final language = apiLanguageCode();
      final first = await repository.fetchOrders(language: language);
      final orders = [...first.orders];
      var page = first.currentPage;
      var lastPage = first.lastPage;
      while (page < lastPage && page < 5) {
        page += 1;
        final next = await repository.fetchOrders(
          language: language,
          page: page,
        );
        orders.addAll(next.orders);
        lastPage = next.lastPage;
      }
      if (!mounted) return;
      setState(() => _pharmacyOrders = orders);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _pharmacyOrdersLoading = false);
    }
  }

  Widget _buildPharmacyOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => Get.to(() => const MyPrescriptionsScreen()),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDE6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'orders_my_prescriptions'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF5E00),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPharmacyOrderList(),
      ],
    );
  }

  Widget _buildPharmacyOrderList() {
    if (_pharmacyOrdersLoading && _pharmacyOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    }
    if (_pharmacyOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'orders_no_orders'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final order in _pharmacyOrders) _pharmacyOrderCard(order),
      ],
    );
  }

  Widget _pharmacyOrderCard(Map<String, dynamic> order) {
    final pharmacyName =
        '${order['pharmacyName'] ?? 'search_vertical_pharmacy'.tr}';
    final orderId = '${order['orderId'] ?? ''}';
    final statusText = '${order['statusText'] ?? ''}';
    if (order['isQuotation'] == true) {
      final seconds = order['expiresInSeconds'];
      return PharmacyQuotationReadyCard(
        pharmacyName: pharmacyName,
        orderId: orderId.isEmpty ? 'orders_prescription'.tr : orderId,
        amount: '${order['amount'] ?? ''}'.isEmpty
            ? 'mru'.trParams({'amount': '0'})
            : '${order['amount']}',
        expiresIn: Duration(seconds: seconds is int ? seconds : 0),
        prescriptionId:
            order['prescriptionId'] is int &&
                (order['prescriptionId'] as int) > 0
            ? order['prescriptionId'] as int
            : null,
        onChanged: _loadPharmacyOrders,
      );
    }
    final badge = _pharmacyStatusColors(
      statusText,
      order['isCancelled'] == true,
    );
    return PharmacyActiveOrderCard(
      pharmacyName: pharmacyName,
      statusText: statusText,
      statusColor: badge.$1,
      statusBgColor: badge.$2,
      detailsText: _pharmacyDetails(order),
      orderId: orderId,
      apiOrderId:
          order['numericOrderId'] is int && (order['numericOrderId'] as int) > 0
          ? order['numericOrderId'] as int
          : null,
      vendorId: order['vendorId'] is int && (order['vendorId'] as int) > 0
          ? order['vendorId'] as int
          : null,
      showPrescription:
          order['isPrescription'] == true &&
          '${order['fileName'] ?? ''}'.isNotEmpty,
      prescriptionName: '${order['fileName'] ?? ''}',
      showTrack:
          order['isCancelled'] != true && order['isPrescription'] != true,
    );
  }

  String _pharmacyDetails(Map<String, dynamic> order) {
    if (order['isPrescription'] == true) {
      final orderId = '${order['orderId'] ?? ''}';
      return orderId.isEmpty
          ? 'orders_prescription'.tr
          : '${'orders_prescription'.tr} • $orderId';
    }
    final total = '${order['totalText'] ?? ''}';
    final items = order['itemsCount'];
    final orderId = '${order['orderId'] ?? ''}';
    return [
      order['isSelfPickup'] == true
          ? 'orders_self_pickup'.tr
          : 'orders_delivery'.tr,
      if (total.isNotEmpty) total,
      if (items is int && items > 0)
        'orders_items_count'.trParams({'count': '$items'}),
      if (orderId.isNotEmpty) orderId,
    ].join(' • ');
  }

  (Color, Color) _pharmacyStatusColors(String status, bool cancelled) {
    final value = status.toLowerCase();
    if (cancelled || value.contains('cancel')) {
      return (const Color(0xFFE03A3A), const Color(0xFFFFECEC));
    }
    if (value.contains('pickup')) {
      return (const Color(0xFF007DFE), const Color(0xFFECF5FF));
    }
    return (const Color(0xFFFF8A00), const Color(0xFFFFF4EC));
  }

  Future<void> _loadWaterOrders() async {
    if (!Get.isRegistered<WaterRepository>()) return;
    setState(() => _waterOrdersLoading = true);
    try {
      final repository = Get.find<WaterRepository>();
      final language = apiLanguageCode();
      final first = await repository.fetchOrders(language: language);
      final orders = [...first.orders];
      var page = first.currentPage;
      var lastPage = first.lastPage;
      while (page < lastPage && page < 5) {
        page += 1;
        final next = await repository.fetchOrders(
          language: language,
          page: page,
        );
        orders.addAll(next.orders);
        lastPage = next.lastPage;
      }
      if (!mounted) return;
      setState(() => _waterOrders = orders);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _waterOrdersLoading = false);
    }
  }

  Widget _buildWaterOrders() {
    if (_waterOrdersLoading && _waterOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    }
    if (_waterOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'orders_no_orders'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [for (final order in _waterOrders) _waterOrderCard(order)],
    );
  }

  Widget _waterOrderCard(Map<String, dynamic> order) {
    final orderId = '${order['orderId']}';
    final statusText = '${order['statusText']}';
    final cancelled = order['isCancelled'] == true;
    final delivered = order['isDelivered'] == true;
    final (Color statusColor, Color statusBgColor) = cancelled
        ? (const Color(0xFFEF4444), const Color(0xFFFDECEC))
        : delivered
        ? (const Color(0xFF00B25C), const Color(0xFFE8F8EE))
        : (const Color(0xFFFF8A00), const Color(0xFFFFF4EC));
    return _buildOrderCard(
      restaurantName: '${order['vendorName']}',
      statusText: statusText.toUpperCase(),
      statusColor: statusColor,
      statusBgColor: statusBgColor,
      detailsText:
          '${'search_vertical_water'.tr} • ${order['total']} • '
          '${'orders_items_count'.trParams({'count': '${order['itemsCount']}'})} • #$orderId',
      buttons: [
        if (!cancelled)
          _buildGradientButton(
            text: 'orders_track_order_btn'.tr,
            onTap: () => Get.to(
              () => WaterTrackOrderScreen(
                orderId: '#$orderId',
                apiOrderId: order['numericOrderId'] as int?,
              ),
            ),
          ),
      ],
      onDetailsLink: () => Get.to(
        () => WaterOrderDetailsScreen(
          orderId: '#$orderId',
          apiOrderId: order['numericOrderId'] as int?,
        ),
      ),
    );
  }

  Future<void> _loadCourierOrders() async {
    if (!Get.isRegistered<CourierRepository>()) return;
    setState(() => _courierOrdersLoading = true);
    try {
      final repository = Get.find<CourierRepository>();
      final language = apiLanguageCode();
      final first = await repository.fetchOrders(language: language);
      final orders = [...first.orders];
      var page = first.currentPage;
      var lastPage = first.lastPage;
      while (page < lastPage && page < 5) {
        page += 1;
        final next = await repository.fetchOrders(
          language: language,
          page: page,
        );
        orders.addAll(next.orders);
        lastPage = next.lastPage;
      }
      if (!mounted) return;
      setState(() => _courierOrders = orders);
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _courierOrdersLoading = false);
    }
  }

  Widget _buildCourierOrders() {
    if (_courierOrdersLoading && _courierOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    }
    if (_courierOrders.isEmpty) return _buildUnloadedOrders();
    return Column(children: _courierOrders.map(_courierOrderCard).toList());
  }

  Widget _courierOrderCard(Map<String, dynamic> order) {
    final orderId = '${order['orderId']}';
    final cancelled = order['isCancelled'] == true;
    final delivered = order['isDelivered'] == true;
    final (Color statusColor, Color statusBgColor) = cancelled
        ? (const Color(0xFFEF4444), const Color(0xFFFDECEC))
        : delivered
        ? (const Color(0xFF00B25C), const Color(0xFFE8F8EE))
        : (const Color(0xFFFF8A00), const Color(0xFFFFF4EC));
    final dropoff = '${order['dropoffAddress']}'.trim();
    return _buildOrderCard(
      restaurantName: dropoff.isEmpty
          ? 'orders_courier_delivery'.tr
          : 'orders_to_address'.trParams({'address': dropoff}),
      statusText: '${order['statusText']}'.toUpperCase(),
      statusColor: statusColor,
      statusBgColor: statusBgColor,
      detailsText: [
        order['isExpress'] == true ? 'orders_express'.tr : 'orders_standard'.tr,
        '${order['total']}',
        '#$orderId',
      ].join(' • '),
      buttons: [
        if (!cancelled && !delivered)
          _buildGradientButton(
            text: 'orders_track_delivery'.tr,
            onTap: () => Get.to(
              () => CourierTrackOrderScreen(
                orderId: '#$orderId',
                apiOrderId: order['numericOrderId'] as int?,
              ),
            ),
          ),
      ],
      onDetailsLink: () => Get.to(
        () => CourierOrderDetailScreen(
          orderId: '#$orderId',
          apiOrderId: order['numericOrderId'] as int?,
          pickupAddress: '${order['pickupAddress']}',
          dropOffAddress: dropoff,
        ),
      ),
    );
  }

  /// Local Store orders (customer/orders/localStore), in the grocery cards.
  Widget _buildOtherCategoryOrders() {
    final onAllTab = selectedCategoryIndex == 0;
    if (_localStoreOrdersLoading && _localStoreOrders.isEmpty) {
      return onAllTab
          ? const SizedBox.shrink()
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
              ),
            );
    }
    if (_localStoreOrders.isEmpty) return _buildUnloadedOrders();
    return Column(
      children: [
        for (final order in _localStoreOrders) _groceryOrderCard(order),
      ],
    );
  }

  Widget _buildUnloadedOrders() {
    if (selectedCategoryIndex == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          'orders_no_orders'.tr,
          style: GoogleFonts.outfit(
            color: const Color(0xFFA59A94),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String restaurantName,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    required String detailsText,
    required List<Widget> buttons,
    VoidCallback? onDetailsLink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Restaurant Name and Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                restaurantName,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Details text
          Text(
            detailsText,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons
          Row(children: buttons),

          if (onDetailsLink != null || statusText != "DELIVERED") ...[
            const SizedBox(height: 12),
            // Bottom details link
            Center(
              child: GestureDetector(
                onTap:
                    onDetailsLink ??
                    () {
                      final parts = detailsText.split('#');
                      final orderId = parts.length > 1
                          ? '#${parts[1]}'
                          : '#22789002';
                      if (restaurantName.contains('Water')) {
                        Get.to(
                          () => WaterOrderDetailsScreen(
                            orderId: orderId,
                            isSelfPickup: statusText == "SELF PICKUP",
                          ),
                        );
                      } else {
                        Get.to(
                          () => OrderDetailScreen(
                            orderId: orderId,
                            isSelfPickup: statusText == "SELF PICKUP",
                          ),
                        );
                      }
                    },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'orders_view_status_details'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5E00),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EFEA),
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E00).withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a tracking response as key/value lines until a tracking design exists.
class _TrackingSheet extends StatelessWidget {
  final Map<String, dynamic> detail;

  const _TrackingSheet({required this.detail});

  @override
  Widget build(BuildContext context) {
    final data = detail['data'] is Map
        ? Map<String, dynamic>.from(detail['data'] as Map)
        : <String, dynamic>{};
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'orders_tracking_title'.tr,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Text(
              '${detail['message'] ?? 'orders_no_details'.tr}',
              style: GoogleFonts.outfit(fontSize: 13),
            )
          else
            for (final entry in data.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: GoogleFonts.outfit(fontSize: 13),
                ),
              ),
        ],
      ),
    );
  }
}
