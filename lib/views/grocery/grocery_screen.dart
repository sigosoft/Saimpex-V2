import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/session_store.dart';
import '../../models/grocery_repository.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import 'grocery_stores_screen.dart';
import 'grocery_details_screen.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/see_all_button.dart';
import '../widgets/search_camera_button.dart';
import '../select_location_screen.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  int selectedSubcategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _searchAnchorKey = GlobalKey();
  bool _showStickySearch = false;

  /// search bar + subcategories row
  static const double _stickyExtent = 166;

  List<Map<String, dynamic>> subcategories = [
    {'id': 0, 'label': 'All', 'isAll': true},
  ];
  List<Map<String, dynamic>> topStores = [];
  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> fastDeliveryStores = [];
  List<Map<String, dynamic>> frequentlyBought = [];

  String _walletText = 'mru'.trParams({'amount': '0'});

  bool _groceryLoading = true;
  int? _activeCategoryId;

  GroceryRepository _getGroceryRepo() {
    if (Get.isRegistered<GroceryRepository>()) {
      return Get.find<GroceryRepository>();
    }
    final session = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>()
        : SessionStore();
    final dio = Get.isRegistered<DioClient>()
        ? Get.find<DioClient>()
        : Get.put(DioClient(session), permanent: true);
    return Get.put(GroceryRepository(dio), permanent: true);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadGroceryCategories();
    _loadGroceryHome();
    _loadWallet();
  }

  /// The SAIMPEX Wallet balance (loaded with home), as on the account screen.
  Future<void> _loadWallet() async {
    if (!Get.isRegistered<SessionStore>()) return;
    final token = Get.find<SessionStore>().token;
    if (token == null || token.isEmpty) return;
    final wallet = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().walletLabel.trim()
        : '';
    if (mounted) {
      setState(
        () => _walletText = wallet.isEmpty
            ? 'mru'.trParams({'amount': '0'})
            : wallet,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroceryCategories() async {
    try {
      final repo = _getGroceryRepo();
      final lang = currentApiLanguage();
      final lat = SelectLocationController.selectedLatitude;
      final lng = SelectLocationController.selectedLongitude;

      final fetched = await repo.fetchGroceryCategories(
        latitude: lat,
        longitude: lng,
        language: lang,
      );

      if (!mounted) return;
      if (fetched.isNotEmpty) {
        setState(() {
          final hasAll = fetched.any((c) => c['isAll'] == true || c['id'] == 0);
          if (!hasAll) {
            subcategories = [
              {'id': 0, 'label': 'All', 'isAll': true},
              ...fetched,
            ];
          } else {
            subcategories = fetched;
          }
        });
      }
    } catch (_) {
      // Keeps the categories already shown.
    }
  }

  Future<void> _loadGroceryHome({int? categoryId, String? keyword}) async {
    setState(() => _groceryLoading = true);
    try {
      final repo = _getGroceryRepo();
      final lang = currentApiLanguage();
      final lat = SelectLocationController.selectedLatitude;
      final lng = SelectLocationController.selectedLongitude;

      final result = await repo.fetchGroceryHomeV2(
        latitude: lat,
        longitude: lng,
        language: lang,
        categoryId: categoryId,
        keyword: keyword,
      );

      if (!mounted) return;

      setState(() {
        topStores = result.topStores;
        recentOrders = result.recentOrders;
        fastDeliveryStores = result.fastDeliveryStores;
        frequentlyBought = result.frequentlyBought;

        if (result.categories.isNotEmpty) {
          final hasAll = result.categories.any(
            (c) => c['isAll'] == true || c['id'] == 0,
          );
          if (!hasAll) {
            subcategories = [
              {'id': 0, 'label': 'All', 'isAll': true},
              ...result.categories,
            ];
          } else {
            subcategories = result.categories;
          }
        }
        _groceryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        topStores = [];
        recentOrders = [];
        fastDeliveryStores = [];
        frequentlyBought = [];
        _groceryLoading = false;
      });
      if (e is ApiException) {
        ToastHelper.showError(e.message);
      }
    }
  }

  Widget _buildNoDataPlaceholder(String title) {
    String message;
    final lower = title.toLowerCase();
    if (lower.contains('recent order')) {
      message = 'st_no_recent_orders'.tr;
    } else if (lower.contains('top store') || lower.contains('store')) {
      message = 'st_no_grocery_stores'.tr;
    } else if (lower.contains('delivery') || lower.contains('15-min')) {
      message = 'st_no_fast_delivery'.tr;
    } else if (lower.contains('frequently') ||
        lower.contains('bought') ||
        lower.contains('product')) {
      message = 'st_no_products'.tr;
    } else {
      message = 'st_no_data'.tr;
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/Nodata.png',
              width: 86,
              height: 86,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.outfit(
                color: const Color(0xFF7A6A60),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleScroll() {
    if (!mounted) return;
    final ctx = _searchAnchorKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final shouldShow = top <= MediaQuery.paddingOf(context).top;
    if (shouldShow != _showStickySearch) {
      setState(() => _showStickySearch = shouldShow);
    }
  }

  Widget _buildStickySearchSubcatsSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildSearchBar(), _buildSubcategoriesRow()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFDDCF), Color(0xFFFFEEE5), Color(0xFFFAF6F0)],
          stops: [0.0, 0.38, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'st_grocery'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _buildAIPredictiveCard(),
                    _buildAITipRow(),

                    // Pins when scrolled: search + subcategories
                    KeyedSubtree(
                      key: _searchAnchorKey,
                      child: _showStickySearch
                          ? const SizedBox(height: _stickyExtent)
                          : _buildStickySearchSubcatsSection(),
                    ),

                    _buildSectionHeader('st_top_stores'.tr, 'See All', () {
                      Get.to(() => const GroceryStoresScreen());
                    }),
                    _buildTopStoresList(),
                    _buildSectionHeader(
                      'st_recent_orders'.tr,
                      'st_view_orders',
                      () {},
                    ),
                    _buildRecentOrdersList(),
                    _buildSectionHeader(
                      'st_15_min_delivery'.tr,
                      'See All',
                      () {},
                    ),
                    _buildFastDeliveryList(),
                    _buildSectionHeader(
                      'st_frequently_bought'.tr,
                      'See All',
                      () {},
                    ),
                    _buildFrequentlyBoughtList(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            if (_showStickySearch)
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: const Color(0xFFFFEEE5),
                  child: _buildStickySearchSubcatsSection(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          AppBackButton(onTap: () => Get.back()),
          const SizedBox(width: 12),

          // Location details
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final result = await Get.to(() => const SelectLocationScreen());
                if (result == true || mounted) {
                  _loadGroceryCategories();
                  _loadGroceryHome();
                }
              },
              child: Row(
                children: [
                  Image.asset(
                    "lib/assets/images/Home.png",
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'st_deliver_to'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Obx(
                                () => Text(
                                  SelectLocationController.deliveryLabel.value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF2C2520),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          Container(
            height: 36,
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 6, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'lib/assets/images/wallet_home.png',
                    width: 16,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  _walletText,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // AI Predictive Card
  Widget _buildAIPredictiveCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'st_ai_predictive'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'st_ai_eggs_title'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'st_ai_eggs_body'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF6F655C),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'st_add_bundle'.tr,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AI Tip Row Banner
  Widget _buildAITipRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFF5E00), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'st_ai_tip'.tr,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0B7A4B),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(text: 'st_ai_tip_text'.tr),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'st_add'.tr,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFA59A94),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  _loadGroceryHome(
                    categoryId: _activeCategoryId,
                    keyword: value.trim().isNotEmpty ? value.trim() : null,
                  );
                },
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'st_search_hint'.tr,
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SearchCameraButton(
              controller: _searchController,
              child: Image.asset(
                "lib/assets/images/Camera.png",
                width: 18,
                height: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EA),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  "lib/assets/images/Voice.png",
                  width: 14,
                  height: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Subcategories
  Widget _buildSubcategoriesRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      padding: const EdgeInsets.only(top: 4),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: 86,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final sub = subcategories[index];
            final isSelected = selectedSubcategoryIndex == index;
            final isAll = sub['isAll'] == true;
            final imageStr = (sub['image'] ?? '').toString();

            return GestureDetector(
              onTap: () {
                final catId = sub['id'] is int
                    ? sub['id'] as int
                    : int.tryParse('${sub['id']}');
                setState(() {
                  selectedSubcategoryIndex = index;
                  _activeCategoryId = (catId != null && catId != 0)
                      ? catId
                      : null;
                });
                _loadGroceryHome(
                  categoryId: _activeCategoryId,
                  keyword: _searchController.text.trim().isNotEmpty
                      ? _searchController.text.trim()
                      : null,
                );
              },
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == subcategories.length - 1 ? 0 : 10,
                ),
                child: SizedBox(
                  width: 62,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Column(
                        children: [
                          (isAll || imageStr.isEmpty)
                              ? Container(
                                  width: 46,
                                  height: 46,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'lib/assets/images/All.png',
                                      width: 22,
                                      height: 22,
                                      color: const Color(0xFFFF5E00),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      imageStr,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 46,
                                                height: 46,
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            isAll
                                ? 'st_all'.tr
                                : (sub['label'] ?? '').toString(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? const Color(0xFFFF5E00)
                                  : const Color(0xFF3A312C),
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        Positioned(
                          bottom: 0,
                          child: Container(
                            height: 10,
                            width: 56,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Top Stores List
  Widget _buildTopStoresList() {
    if (_groceryLoading) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF5E00),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (topStores.isEmpty) {
      return _buildNoDataPlaceholder('Top Stores Near You');
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topStores.length,
        itemBuilder: (context, index) {
          final store = topStores[index];
          final homeController = Get.isRegistered<HomeController>()
              ? Get.find<HomeController>()
              : Get.put(HomeController());

          final discountText = (store['discount'] ?? '').toString();
          final hasDiscount = discountText.isNotEmpty;
          final ratingText = (store['rating'] ?? '4.5').toString();
          final pointsText = (store['points'] ?? '').toString();
          final hasPoints = pointsText.isNotEmpty;
          final nameText = (store['name'] ?? store['title'] ?? '').toString();
          final categoryText = (store['category'] ?? '').toString();
          final timeText = (store['time'] ?? '').toString();
          final distText = (store['dist'] ?? '').toString();
          final imageUrl = (store['image'] ?? '').toString();

          return GestureDetector(
            onTap: () {
              Get.to(() => GroceryDetailsScreen(store: store));
            },
            child: Container(
              width: 240,
              margin: const EdgeInsetsDirectional.only(end: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with overlays
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 120,
                                              width: double.infinity,
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.store,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  )
                                : Container(
                                    height: 120,
                                    width: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.store,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),

                        // Discount tag
                        if (hasDiscount)
                          PositionedDirectional(
                            top: 10,
                            start: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5E00),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                discountText,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // Rating badge
                        PositionedDirectional(
                          top: 10,
                          start: hasDiscount ? 62 : 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB300),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ratingText,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Favorite button
                        PositionedDirectional(
                          top: 10,
                          end: 10,
                          child: Obx(() {
                            final isLiked = homeController.isLiked(
                              (store['id'] ?? '').toString(),
                            );
                            return GestureDetector(
                              onTap: () => homeController.toggleLike(
                                (store['id'] ?? '').toString(),
                                store,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: const Color(0xFFE03A3A),
                                  size: 14,
                                ),
                              ),
                            );
                          }),
                        ),

                        // Points overlay bottom-left
                        if (hasPoints)
                          PositionedDirectional(
                            bottom: 8,
                            start: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    "lib/assets/images/Points.png",
                                    width: 12,
                                    height: 12,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              "lib/assets/images/Coin.png",
                                              width: 12,
                                              height: 12,
                                            ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pointsText,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Store details text
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (timeText.isNotEmpty) ...[
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFFFF5E00),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeText,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (distText.isNotEmpty) ...[
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFFFF5E00),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distText,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Recent Orders List
  Widget _buildRecentOrdersList() {
    if (_groceryLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF5E00),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (recentOrders.isEmpty) {
      return _buildNoDataPlaceholder('Recent Orders');
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recentOrders.length,
        itemBuilder: (context, index) {
          final order = recentOrders[index];
          final imageUrl = (order['image'] ?? '').toString();
          final nameText = (order['name'] ?? '').toString();
          final ratingText = (order['rating'] ?? '4.5').toString();
          final itemsText = (order['items'] ?? '').toString();
          final dateText = (order['date'] ?? '').toString();
          final countText = (order['count'] ?? '').toString();

          return Container(
            width: 250,
            margin: const EdgeInsetsDirectional.only(end: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product circle image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 44,
                                height: 44,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.fastfood,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.fastfood,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 10),

                // Order Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nameText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB300),
                            size: 10,
                          ),
                          Text(
                            ratingText,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        itemsText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFFFF5E00),
                            size: 9,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateText,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Reorder action side
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      countText,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFF5E00),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFFFF5E00),
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'st_reorder'.tr,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 15-Min Delivery List
  Widget _buildFastDeliveryList() {
    if (_groceryLoading) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF5E00),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (fastDeliveryStores.isEmpty) {
      return _buildNoDataPlaceholder('15-Min Delivery');
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fastDeliveryStores.length,
        itemBuilder: (context, index) {
          final store = fastDeliveryStores[index];
          final homeController = Get.isRegistered<HomeController>()
              ? Get.find<HomeController>()
              : Get.put(HomeController());

          final discountText = (store['discount'] ?? '').toString();
          final hasDiscount = discountText.isNotEmpty;
          final ratingText = (store['rating'] ?? '4.5').toString();
          final pointsText = (store['points'] ?? '').toString();
          final hasPoints = pointsText.isNotEmpty;
          final timeText = (store['time'] ?? '15m').toString();
          final nameText = (store['name'] ?? store['title'] ?? '').toString();
          final categoryText = (store['category'] ?? '').toString();
          final imageUrl = (store['image'] ?? '').toString();

          return GestureDetector(
            onTap: () {
              Get.to(() => GroceryDetailsScreen(store: store));
            },
            child: Container(
              width: 240,
              margin: const EdgeInsetsDirectional.only(end: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with overlays
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 120,
                                              width: double.infinity,
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.store,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  )
                                : Container(
                                    height: 120,
                                    width: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.store,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),

                        // Discount tag
                        if (hasDiscount)
                          PositionedDirectional(
                            top: 10,
                            start: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5E00),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                discountText,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // Rating badge
                        PositionedDirectional(
                          top: 10,
                          start: hasDiscount ? 62 : 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFB300),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ratingText,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C2520),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Favorite button
                        PositionedDirectional(
                          top: 10,
                          end: 10,
                          child: Obx(() {
                            final isLiked = homeController.isLiked(
                              (store['id'] ?? '').toString(),
                            );
                            return GestureDetector(
                              onTap: () => homeController.toggleLike(
                                (store['id'] ?? '').toString(),
                                store,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: const Color(0xFFE03A3A),
                                  size: 14,
                                ),
                              ),
                            );
                          }),
                        ),

                        // Points + Time badge overlay bottom-left
                        PositionedDirectional(
                          bottom: 8,
                          start: 10,
                          child: Row(
                            children: [
                              if (hasPoints) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        "lib/assets/images/Points.png",
                                        width: 12,
                                        height: 12,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Image.asset(
                                                  "lib/assets/images/Coin.png",
                                                  width: 12,
                                                  height: 12,
                                                ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        pointsText,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeText,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Store details text
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Frequently Bought List
  Widget _buildFrequentlyBoughtList() {
    if (_groceryLoading) {
      return const SizedBox(
        height: 195,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF5E00),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (frequentlyBought.isEmpty) {
      return _buildNoDataPlaceholder('Frequently Bought');
    }

    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: frequentlyBought.length,
        itemBuilder: (context, index) {
          final prod = frequentlyBought[index];
          final imageUrl = (prod['image'] ?? '').toString();
          final ratingText = (prod['rating'] ?? '4.5').toString();
          final nameText = (prod['name'] ?? '').toString();
          final storeText = (prod['store'] ?? '').toString();
          final priceText = (prod['price'] ?? '').toString();

          return Container(
            width: 150,
            margin: const EdgeInsetsDirectional.only(end: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 100,
                                        width: double.infinity,
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 30,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                              : Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),

                      // Rating badge
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB300),
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                ratingText,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Details Row
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        storeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              priceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5E00),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'st_add'.tr,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Section Header
Widget _buildSectionHeader(
  String title,
  String actionText,
  VoidCallback onTap,
) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        actionText == 'See All'
            ? SeeAllButton(onTap: onTap)
            : GestureDetector(
                onTap: onTap,
                child: Row(
                  children: [
                    Text(
                      actionText.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5E00),
                      size: 16,
                    ),
                  ],
                ),
              ),
      ],
    ),
  );
}
