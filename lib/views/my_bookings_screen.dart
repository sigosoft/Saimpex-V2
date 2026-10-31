import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_back_button.dart';
import '../widgets/home_background_blend.dart';
import '../constants/text_styles.dart';
import '../controllers/home_controller.dart';
import '../core/network/api_exception.dart';
import '../models/service_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import 'rate_order_screen.dart';
import 'services/car_wash_screen.dart';
import 'services/home_cleaning_screen.dart';
import 'services/laundry_services_screen.dart';
import 'services/gas_screen.dart';
import '../widgets/cancel_booking_bottom_sheet.dart';
import 'services/car_wash_booking_detail_screen.dart';
import 'services/home_cleaning_booking_detail_screen.dart';
import 'services/laundry_booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  final bool showBottomNav;

  const MyBookingsScreen({super.key, this.showBottomNav = true});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedFilter = 0;

  static const _filters = [
    'All',
    'Home Cleaning',
    'Car Wash',
    'Laundry',
    'Gas',
  ];

  /// Shown text for a category value (the values stay English for matching).
  static String _categoryLabel(String category) => switch (category) {
    'All' => 'orders_filter_all'.tr,
    'Home Cleaning' => 'orders_cat_home_cleaning'.tr,
    'Car Wash' => 'orders_cat_car_wash'.tr,
    'Laundry' => 'orders_cat_laundry'.tr,
    'Gas' => 'orders_cat_gas'.tr,
    'Service' => 'orders_cat_service'.tr,
    _ => category,
  };

  List<Map<String, dynamic>> _bookings = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Get.isRegistered<ServiceRepository>()) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final repository = Get.find<ServiceRepository>();
      final language = apiLanguageCode();
      final first = await repository.fetchBookings(language: language);
      final rows = [...first.bookings];
      var page = first.currentPage;
      var lastPage = first.lastPage;
      while (page < lastPage && page < 5) {
        page += 1;
        final next = await repository.fetchBookings(
          language: language,
          page: page,
        );
        rows.addAll(next.bookings);
        lastPage = next.lastPage;
      }
      if (!mounted) return;
      setState(() => _bookings = rows.map(_fromApi).toList());
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _categoryByVertical = {
    ServiceRepository.homeCleaning: ('Home Cleaning', 0xFFFF5E00),
    ServiceRepository.carWash: ('Car Wash', 0xFF2B7DE9),
    ServiceRepository.laundry: ('Laundry', 0xFF7B4FD6),
    ServiceRepository.gas: ('Gas', 0xFF00A86B),
  };

  /// A service/bookings row shaped for the booking cards and detail screens.
  Map<String, dynamic> _fromApi(Map<String, dynamic> row) {
    String text(dynamic value) => '${value ?? ''}'.trim();
    final category =
        _categoryByVertical[text(row['vertical'])] ?? ('Service', 0xFFFF5E00);
    final status = int.tryParse(text(row['status'])) ?? 0;
    final code = text(row['order_code']);
    final total = double.tryParse(text(row['total'])) ?? 0;
    final location = text(row['location']).isEmpty
        ? text(row['address'])
        : text(row['location']);
    final slot = text(row['slot']).isEmpty
        ? text(row['scheduled_for'])
        : text(row['slot']);
    return {
      'id': code.isEmpty ? text(row['id']) : code,
      'apiOrderId': int.tryParse(text(row['id'])),
      'provider': text(row['provider_name']).isEmpty
          ? 'orders_service_provider'.tr
          : text(row['provider_name']),
      'category': category.$1,
      'categoryColor': category.$2,
      'service': text(row['service_name_en']).isEmpty
          ? category.$1
          : text(row['service_name_en']),
      // 9 is delivered/completed in the order status codes.
      'status': status == 9 ? 'Completed' : text(row['status_label']),
      'datetime': slot,
      'slot': text(row['slot_window']).isEmpty
          ? slot
          : text(row['slot_window']),
      'location': location,
      'locationTitle': location,
      'rooms': text(row['summary']),
      'price': 'mru'.trParams({'amount': '${total.round()}'}),
      'canCancel': row['can_cancel'] == true,
      'notes': text(row['notes']),
      'payment': text(row['payment_type_label']),
    };
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 0) return _bookings;
    final key = _filters[_selectedFilter];
    return _bookings.where((b) => b['category'] == key).toList();
  }

  void _reorder(Map<String, dynamic> booking) {
    switch (booking['category']) {
      case 'Car Wash':
        Get.to(() => const CarWashScreen());
      case 'Laundry':
        Get.to(() => const LaundryServicesScreen());
      case 'Gas':
        Get.to(() => const GasScreen());
      default:
        Get.to(() => const HomeCleaningScreen());
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'upcoming':
      case 'completed':
        return const Color(0xFFE8F8EE);
      case 'cancelled':
        return const Color(0xFFFFE8E8);
      default:
        return const Color(0xFFE8F8EE);
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'upcoming':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final list = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFDDCC9),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: HomeBackgroundBlend(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildFilters(),
                const SizedBox(height: 14),
                Expanded(
                  child: _loading && _bookings.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5E00),
                          ),
                        )
                      : list.isEmpty
                      ? Center(
                          child: Text(
                            'orders_no_bookings'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9A8E86),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            120 + bottomInset,
                          ),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildBookingCard(list[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: widget.showBottomNav
                ? AppBackButton(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Get.back();
                      } else if (Get.isRegistered<HomeController>()) {
                        Get.find<HomeController>().selectNavigation(
                          HomeController.navHome,
                        );
                      }
                    },
                  )
                : const SizedBox(width: 38),
          ),
          Text('orders_my_bookings'.tr, style: AppTextStyles.heading()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF5E00) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF5E00)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                _categoryLabel(_filters[index]),
                style: GoogleFonts.outfit(
                  color: selected ? Colors.white : const Color(0xFF2C2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final statusText = booking['status'] as String? ?? '';
    final status = statusText.toLowerCase();
    final isCompleted = status == 'completed';
    final category = booking['category'] as String? ?? '';
    final categoryColor = Color(booking['categoryColor'] as int? ?? 0xFFFF5E00);
    final hasBalanceDue = booking['hasBalanceDue'] == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Provider Name & Status Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  booking['provider'] as String? ?? 'CleanPro Elite',
                  style: AppTextStyles.title(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(statusText),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted
                      ? 'orders_status_completed'.tr
                      : statusText.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: _statusFg(statusText),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _categoryLabel(category),
                style: GoogleFonts.outfit(
                  color: categoryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEDE6DF)),
          const SizedBox(height: 10),

          if (isCompleted) ...[
            Text(
              '${booking['service']} · ${booking['price']} · #${booking['id']}',
              style: AppTextStyles.subtitle().copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _reorder(booking),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EBE3),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'orders_reorder'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.to(
                      () => RateOrderScreen(
                        orderId: booking['apiOrderId'] as int?,
                      ),
                    ),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EBE3),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'orders_rate'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              booking['service'] as String? ?? 'Regular Cleaning',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFFF5E00),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking['datetime'] as String? ??
                        'Today, 15 Aug 2026, 2:00–4:00 PM',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF5A5048),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFFF5E00),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking['location'] as String? ??
                        'Near Marhaba Supermarket,Nouakchott',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF5A5048),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasBalanceDue) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8DD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5E00),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'orders_balance_due_badge'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'orders_estimated_weight'.trParams({'weight': '3.0'}),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '460 MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(text: 'orders_actual_weight'.tr),
                              TextSpan(
                                text: '3.6 kg',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '545 MRU',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'orders_balance_due'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'orders_balance_due_hint'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '85 MRU',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                // Balance payments aren't in the service API yet.
                onTap: () => showAppToast('orders_balance_unavailable'.tr),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    ),
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'orders_pay_amount'.trParams({
                      'amount': '${booking['balanceDue'] ?? '85 MRU'}',
                    }),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (booking['canCancel'] == true)
                GestureDetector(
                  onTap: () => showCancelBookingBottomSheet(
                    context,
                    bookingId: booking['id'] as String?,
                    apiOrderId: booking['apiOrderId'] as int?,
                    onCancelled: _load,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EBE3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (booking['canCancel'] == true) const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () {
                    final category = booking['category'] as String?;
                    if (category == 'Car Wash') {
                      Get.to(
                        () => CarWashBookingDetailScreen(booking: booking),
                      );
                    } else if (category == 'Laundry') {
                      Get.to(
                        () => LaundryBookingDetailScreen(booking: booking),
                      );
                    } else {
                      Get.to(
                        () => HomeCleaningBookingDetailScreen(booking: booking),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'orders_view_booking_details'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFFF5E00),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
