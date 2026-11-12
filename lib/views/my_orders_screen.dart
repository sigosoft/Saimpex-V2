import '../widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'order_detail_screen.dart';
import 'order_updated_detail_screen.dart';
import 'water/water_order_details_screen.dart';
import 'courier/courier_order_detail_screen.dart';
import 'courier/courier_track_order_screen.dart';
import 'water/water_track_order_screen.dart';
import 'track_order_screen.dart';
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
import '../utils/rated_orders.dart';
import '../utils/toast_helper.dart';
import '../controllers/home_controller.dart';
import '../constants/text_styles.dart';
import '../widgets/app_back_button.dart';
import '../widgets/home_background_blend.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';

import '../utils/app_fonts.dart';
import '../utils/store_labels.dart';
import '../utils/order_flags.dart';

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
    RatedOrders.load().then((_) {
      if (mounted) setState(() {});
    });
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
      _checkOrderFlags(orders);
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
                // Clear of the bar, the raised Services button and the phone's
                // navigation area (the last card's link sat under the button).
                padding: EdgeInsets.only(
                  bottom: 140 + MediaQuery.of(context).padding.bottom,
                ),
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
                                    ? const Color(0xFFFF5216)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF5216)
                                      : const Color(0xFFEAD8C9),
                                  width: 0.8,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                categories[index].tr,
                                style: AppFonts.outfit(
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
        if (_noOrdersAtAll)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'orders_no_orders'.tr,
                style: AppFonts.outfit(
                  color: const Color(0xFFA59A94),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Every list loaded and empty: "All" shows a single "No orders".
  bool get _noOrdersAtAll =>
      !_restaurantOrdersLoading &&
      !_groceryOrdersLoading &&
      !_pharmacyOrdersLoading &&
      !_waterOrdersLoading &&
      !_courierOrdersLoading &&
      !_localStoreOrdersLoading &&
      _restaurantOrders.isEmpty &&
      _groceryOrders.isEmpty &&
      _pharmacyOrders.isEmpty &&
      _waterOrders.isEmpty &&
      _courierOrders.isEmpty &&
      _localStoreOrders.isEmpty;

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
      _checkOrderFlags(orders);
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
          child: CircularProgressIndicator(color: Color(0xFFFF5216)),
        ),
      );
    }
    // On "All" an empty section shows nothing; one message covers them all.
    if (_groceryOrders.isEmpty) return _buildUnloadedOrders();
    return Column(
      children: [
        for (final order in _groceryOrders)
          FadeSlideIn(child: _groceryOrderCard(order)),
      ],
    );
  }

  /// A grocery order card, laid out as in the design: store, status, one details
  /// line, Cancel and Track Order, and a link to the order details.
  Widget _groceryOrderCard(Map<String, dynamic> order) {
    final statusText = '${order['statusText'] ?? ''}';
    final cancelled = order['isCancelled'] == true;
    final delivered = order['isDelivered'] == true;
    final badge = _pharmacyStatusColors(
      statusText,
      cancelled,
      delivered: delivered,
    );
    final details = [
      order['isSelfPickup'] == true ? 'orders_pickup'.tr : 'orders_delivery'.tr,
      if ('${order['totalText'] ?? ''}'.isNotEmpty) '${order['totalText']}',
      if ((order['itemsCount'] is int) && (order['itemsCount'] as int) > 0)
        itemsCountLabel(order['itemsCount']),
      if ('${order['orderId'] ?? ''}'.isNotEmpty) '${order['orderId']}',
    ].join(' • ');

    return _buildOrderCard(
      restaurantName:
          '${order['restaurantName'] ?? 'search_vertical_grocery'.tr}',
      statusText: '${order['statusLabel'] ?? statusText}',
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
        ] else if (delivered && !RatedOrders.contains(_orderId(order)))
          _buildOrderButton(
            text: 'orders_rate'.tr,
            onTap: () => _rateOrder(_orderId(order)),
          ),
      ],
    );
  }

  static int? _orderId(Map<String, dynamic> order) =>
      order['numericOrderId'] as int?;

  /// How many orders of one list are checked per load: the newest ones,
  /// which are on screen first. Older orders are checked on later loads only
  /// if they come into this window.
  static const _flagCheckLimit = 20;

  /// The order lists don't send is_self_pickup (backend #166) or whether the
  /// customer already rated (backend #165). Until they do, ask once per order
  /// (`orderDetails`, `rating`), remember the answer on the phone
  /// ([OrderFlags], [RatedOrders]) and update the cards: "Pickup" and
  /// "Picked up" for self-pickup orders, no Rate button on rated ones.
  Future<void> _checkOrderFlags(List<Map<String, dynamic>> orders) async {
    if (!Get.isRegistered<OrderRepository>()) return;
    await Future.wait([RatedOrders.load(), OrderFlags.load()]);
    if (!mounted) return;
    setState(() => _applyOrderFlags(orders));

    final repository = Get.find<OrderRepository>();
    final language = apiLanguageCode();
    final tasks = <Future<void> Function()>[];
    for (final order in orders.take(_flagCheckLimit)) {
      final id = _orderId(order);
      if (id == null) continue;
      if (order['isSelfPickup'] != true &&
          OrderFlags.isSelfPickup(id) == null) {
        tasks.add(() async {
          final detail = await repository.orderDetails(
            orderId: id,
            language: language,
          );
          final pickup =
              detail['is_self_pickup'] == 1 ||
              detail['is_self_pickup'] == true ||
              '${detail['is_self_pickup']}' == '1';
          await OrderFlags.setSelfPickup(id, pickup);
        });
      }
      if (order['isDelivered'] == true &&
          !RatedOrders.contains(id) &&
          !OrderFlags.checkedNotRated(id)) {
        tasks.add(() async {
          final rating = await repository.rating(
            orderId: id,
            language: language,
          );
          if (rating['vendor_rating'] != null) {
            await RatedOrders.add(id);
          } else {
            OrderFlags.markNotRated(id);
          }
        });
      }
    }
    if (tasks.isEmpty) return;
    // Three at a time, so a long list doesn't flood the server.
    for (var i = 0; i < tasks.length; i += 3) {
      await Future.wait(
        tasks.skip(i).take(3).map((task) async {
          try {
            await task();
          } catch (_) {
            // Unknown stays unknown: the card keeps the list's values and
            // Rate still checks on tap.
          }
        }),
      );
    }
    if (!mounted) return;
    setState(() => _applyOrderFlags(orders));
  }

  /// Puts what [OrderFlags] knows into the cards' data.
  static void _applyOrderFlags(List<Map<String, dynamic>> orders) {
    for (final order in orders) {
      if (OrderFlags.isSelfPickup(_orderId(order)) != true) continue;
      order['isSelfPickup'] = true;
      if (order['isDelivered'] == true) {
        order['statusLabel'] = 'core_status_9_pickup'.tr;
      }
    }
  }

  /// Opens the rating form, unless the server already has this customer's
  /// rating for the order (rated earlier or on another phone): then it says
  /// so and the Rate button goes away.
  Future<void> _rateOrder(int? orderId) async {
    if (orderId != null && Get.isRegistered<OrderRepository>()) {
      try {
        final rating = await Get.find<OrderRepository>().rating(
          orderId: orderId,
          language: apiLanguageCode(),
        );
        if (rating['vendor_rating'] != null) {
          await RatedOrders.add(orderId);
          if (!mounted) return;
          setState(() {});
          showAppToast('orders_already_rated'.tr);
          return;
        }
      } on ApiException catch (_) {
        // The form handles its own errors; open it anyway.
      }
    }
    // A self-pickup order had no driver, so it has no delivery to rate. The
    // order lists don't send is_self_pickup yet (backend #166); the details
    // do.
    var selfPickup = false;
    if (orderId != null && Get.isRegistered<OrderRepository>()) {
      try {
        final detail = await Get.find<OrderRepository>().orderDetails(
          orderId: orderId,
          language: apiLanguageCode(),
        );
        selfPickup =
            '${detail['is_self_pickup']}' == '1' ||
            detail['is_self_pickup'] == true;
      } on ApiException catch (_) {
        // Unknown: keep the delivery card, as before.
      }
    }
    if (!mounted) return;
    await Get.to(
      () => RateOrderScreen(orderId: orderId, hasDelivery: !selfPickup),
    );
    if (mounted) setState(() {});
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
      _checkOrderFlags(orders);
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
          child: CircularProgressIndicator(color: Color(0xFFFF5216)),
        ),
      );
    }
    // On "All" an empty section shows nothing; one message covers them all.
    if (_restaurantOrders.isEmpty) return _buildUnloadedOrders();
    return Column(
      children: [
        for (final order in _restaurantOrders)
          FadeSlideIn(child: _restaurantOrderCard(order)),
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
    final badge = _pharmacyStatusColors(
      statusText,
      cancelled,
      delivered: delivered,
    );
    final details = [
      order['isSelfPickup'] == true ? 'orders_pickup'.tr : 'orders_delivery'.tr,
      if ('${order['totalText'] ?? ''}'.isNotEmpty) '${order['totalText']}',
      if ((order['itemsCount'] is int) && (order['itemsCount'] as int) > 0)
        itemsCountLabel(order['itemsCount']),
      if (orderId.isNotEmpty) orderId,
    ].join(' • ');

    return _buildOrderCard(
      restaurantName: '${order['restaurantName'] ?? 'orders_restaurant'.tr}',
      statusText: '${order['statusLabel'] ?? statusText}',
      statusColor: badge.$1,
      statusBgColor: badge.$2,
      detailsText: details,
      onDetailsLink: () => _showRestaurantOrderDetail(order),
      buttons: [
        if (delivered && !RatedOrders.contains(_orderId(order)))
          _buildOrderButton(
            text: 'orders_rate'.tr,
            onTap: () => _rateOrder(_orderId(order)),
          )
        else if (delivered)
          const SizedBox.shrink()
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

  void _trackRestaurantOrder(Map<String, dynamic> order) {
    final orderId = _restaurantOrderId(order);
    if (orderId == null) {
      showAppToast('orders_tracking_unavailable'.tr);
      return;
    }
    Get.to(
      () => TrackOrderScreen(
        orderId: '${order['orderId'] ?? ''}',
        apiOrderId: orderId,
      ),
    );
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
        backgroundColor: const Color(0xFFFF5216),
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
              style: AppFonts.outfit(
                color: const Color(0xFFFF5216),
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
          child: CircularProgressIndicator(color: Color(0xFFFF5216)),
        ),
      );
    }
    // On "All" an empty section shows nothing; one message covers them all.
    if (_pharmacyOrders.isEmpty) return _buildUnloadedOrders();
    return Column(
      children: [
        for (final order in _pharmacyOrders)
          FadeSlideIn(child: _pharmacyOrderCard(order)),
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
        hasExpiry: seconds is int,
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
      delivered: order['isDelivered'] == true,
    );
    return PharmacyActiveOrderCard(
      pharmacyName: pharmacyName,
      statusText: statusText,
      statusLabel: '${order['statusLabel'] ?? statusText}',
      canCancel: order['canCancel'] == true,
      delivered: order['isDelivered'] == true,
      prescriptionId:
          order['prescriptionId'] is int && (order['prescriptionId'] as int) > 0
          ? order['prescriptionId'] as int
          : null,
      onChanged: _loadPharmacyOrders,
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
      // Paid prescription orders carry the file too (Figma shows it on the
      // card); they opened the plain item-order screen without it.
      showPrescription: '${order['fileName'] ?? ''}'.isNotEmpty,
      prescriptionUrl: '${order['fileUrl'] ?? ''}',
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
      if (items is int && items > 0) itemsCountLabel(items),
      if (orderId.isNotEmpty) orderId,
    ].join(' • ');
  }

  (Color, Color) _pharmacyStatusColors(
    String status,
    bool cancelled, {
    bool delivered = false,
  }) {
    final value = status.toLowerCase();
    if (cancelled || value.contains('cancel')) {
      return (const Color(0xFFE03A3A), const Color(0xFFFFECEC));
    }
    // Figma: delivered orders have a green chip (was orange like the rest).
    if (delivered) {
      return (const Color(0xFF00B25C), const Color(0xFFE8F8EE));
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
      _checkOrderFlags(orders);
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
          child: CircularProgressIndicator(color: Color(0xFFFF5216)),
        ),
      );
    }
    // On "All" an empty section shows nothing; one message covers them all.
    if (_waterOrders.isEmpty) return _buildUnloadedOrders();
    return Column(
      children: [for (final order in _waterOrders) _waterOrderCard(order)],
    );
  }

  Widget _waterOrderCard(Map<String, dynamic> order) {
    // "ORD-001521" already reads as an order number; only a bare id gets "#".
    final rawId = '${order['orderId']}';
    final orderId = rawId.toUpperCase().startsWith('ORD') ? rawId : '#$rawId';
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
      statusText: '${order['statusLabel'] ?? statusText}'.toUpperCase(),
      statusColor: statusColor,
      statusBgColor: statusBgColor,
      detailsText:
          '${'search_vertical_water'.tr} • ${order['total']} • '
          '${itemsCountLabel(order['itemsCount'])} • $orderId',
      buttons: [
        if (!cancelled && !delivered)
          _buildGradientButton(
            text: 'orders_track_order_btn'.tr,
            onTap: () => Get.to(
              () => WaterTrackOrderScreen(
                orderId: orderId,
                apiOrderId: order['numericOrderId'] as int?,
              ),
            ),
          ),
      ],
      onDetailsLink: () => Get.to(
        () => WaterOrderDetailsScreen(
          orderId: orderId,
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
          child: CircularProgressIndicator(color: Color(0xFFFF5216)),
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
        // Isolated left to right: Arabic showed "CRBR1LK9XE#".
        '\u2066#$orderId\u2069',
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
                child: CircularProgressIndicator(color: Color(0xFFFF5216)),
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
          style: AppFonts.outfit(
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
            color: Colors.black.withValues(alpha: 0.02),
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
                style: AppFonts.outfit(
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
                  style: AppFonts.outfit(
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
            style: AppFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Action Buttons; a card without any (cancelled, rated) no longer
          // keeps an empty band above the details link.
          if (buttons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: buttons),
          ],

          if (onDetailsLink != null) ...[
            const SizedBox(height: 12),
            // Bottom details link
            Center(
              child: GestureDetector(
                onTap: onDetailsLink,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'orders_view_status_details'.tr,
                      style: AppFonts.outfit(
                        color: const Color(0xFFFF5216),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5216),
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
            style: AppFonts.outfit(
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
              colors: [Color(0xFFFF5216), Color(0xFFFFAE00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5216).withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppFonts.outfit(
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
