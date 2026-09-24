import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_back_button.dart';
import '../constants/text_styles.dart';
import '../controllers/home_controller.dart';
import '../controllers/car_wash_bookings_store.dart';
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
    'Plumbing',
    'Carpentry',
    'Electrical',
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': '22789002',
      'provider': 'CleanPro Elite',
      'category': 'Home Cleaning',
      'categoryColor': 0xFFFF5E00,
      'service': 'Regular Cleaning',
      'status': 'Confirmed',
      'datetime': 'Today, 15 Aug 2026, 2:00–4:00 PM',
      'slot': '15 Aug 2026, 2:00 PM – 4:00 PM',
      'location': 'Near Marhaba Supermarket,Nouakchott',
      'locationTitle': 'Sahara View Home',
      'rooms': '2 Bedrooms · 2 Bathrooms',
      'price': '750 MRU',
      'image': 'lib/assets/images/regular_cleaning.jpg',
    },
    {
      'id': '22789003',
      'provider': 'CleanRide Car Wash',
      'category': 'Car Wash',
      'categoryColor': 0xFF2B7DE9,
      'service': 'Full Wash',
      'status': 'Confirmed',
      'datetime': 'Today, 15 Aug 2026, 2:00–4:00 PM',
      'slot': '15 Aug 2026, 2:00 - 4:00 PM',
      'location': 'CleanRide Car Wash, Near Nouakchott, Mauritania',
      'locationTitle': 'CleanRide Car Wash',
      'rooms': 'Sedan',
      'price': '510 MRU',
      'vehicleLabel': 'Sedan',
      'vehicleImage': 'lib/assets/images/Sedan.png',
      'plateNumber': '1234 AB 01',
      'vehiclePrice': '1000 MRU',
      'servicePrice': '1000 MRU',
      'serviceDescription':
          'Complete interior & exterior detailing with premium ceramic tire gloss',
      'serviceImage':
          'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=300&h=300&fit=crop',
      'duration': '45 min',
      'image': 'lib/assets/images/Sedan.png',
      'washServices': [
        {
          'title': 'Full Wash',
          'description':
              'Complete interior & exterior detailing with premium ceramic tire gloss',
          'price': '1000 MRU',
          'image':
              'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=300&h=300&fit=crop',
        },
      ],
      'addons': [
        {
          'title': 'Engine Wash',
          'description':
              'Safe hydraulic degreasing and rinse for bay components without water damage.',
          'price': '+50 MRU',
          'image':
              'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=200&h=200&fit=crop',
        },
      ],
      'total': '1050 MRU',
      'redeemed': '-50 MRU',
      'tax': '10 MRU',
      'totalPaid': '1010 MRU',
    },
    {
      'id': '22789004',
      'provider': 'CleanPro Laundry',
      'category': 'Laundry',
      'categoryColor': 0xFF7B5CFF,
      'service': 'Wash & Fold',
      'status': 'Confirmed',
      'datetime': 'Today, 15 Aug 2026, 2:00–4:00 PM',
      'slot': '15 Aug 2026, 2:00 PM – 4:00 PM',
      'location': 'Near Marhaba Supermarket,Nouakchott',
      'locationTitle': 'Sahara View Home',
      'price': '450 MRU',
      'estimateLabel': 'Estimated 3 kg',
      'duration': '24 hour',
      'image': 'lib/assets/images/wash&fold_detail.png',
    },
    {
      'id': '22789005',
      'provider': 'CleanPro Laundry',
      'category': 'Laundry',
      'categoryColor': 0xFF7B5CFF,
      'service': 'Wash & Fold',
      'status': 'Confirmed',
      'datetime': 'Today, 15 Aug 2026, 2:00–4:00 PM',
      'slot': '15 Aug 2026, 2:00 PM – 4:00 PM',
      'location': 'Near Marhaba Supermarket,Nouakchott',
      'locationTitle': 'Sahara View Home',
      'price': '545 MRU',
      'estimateLabel': 'Estimated 3.0 kg',
      'estimatedPrice': '460 MRU',
      'actualWeight': '3.6 kg',
      'balanceDue': '85 MRU',
      'hasBalanceDue': true,
      'image': 'lib/assets/images/wash&fold_detail.png',
    },
    {
      'id': '22789006',
      'provider': 'QuickFix Plumbing',
      'category': 'Plumbing',
      'categoryColor': 0xFF00A896,
      'service': 'Pipe Repair & Leak Fix',
      'status': 'Confirmed',
      'datetime': 'Tomorrow, 16 Aug 2026, 10:00–12:00 PM',
      'slot': '16 Aug 2026, 10:00 AM – 12:00 PM',
      'location': 'Near Marhaba Supermarket,Nouakchott',
      'locationTitle': 'Sahara View Home',
      'price': '600 MRU',
    },
    {
      'id': '22789007',
      'provider': 'CraftWood Carpentry',
      'category': 'Carpentry',
      'categoryColor': 0xFFD97706,
      'service': 'Custom Cabinet Repair',
      'status': 'Confirmed',
      'datetime': 'Tomorrow, 16 Aug 2026, 2:00–4:00 PM',
      'slot': '16 Aug 2026, 2:00 PM – 4:00 PM',
      'location': 'Near Marhaba Supermarket,Nouakchott',
      'locationTitle': 'Sahara View Home',
      'price': '850 MRU',
    },
    {
      'id': '22789008',
      'provider': 'VoltMaster Electrical',
      'category': 'Electrical',
      'categoryColor': 0xFFEAB308,
      'service': 'Circuit Inspection & Wiring',
      'status': 'Confirmed',
      'datetime': '17 Aug 2026, 9:00–11:00 AM',
      'slot': '17 Aug 2026, 9:00 AM – 11:00 AM',
      'location': 'Near Marhaba Supermarket,Nouakchott',
      'locationTitle': 'Sahara View Home',
      'price': '500 MRU',
    },
  ];

  List<Map<String, dynamic>> get _allBookings => [
        ...CarWashBookingsStore.instance.bookings,
        ..._bookings,
      ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 0) return _allBookings;
    final key = _filters[_selectedFilter];
    return _allBookings.where((b) => b['category'] == key).toList();
  }

  void _payBalance(Map<String, dynamic> booking) {
    final balance = booking['balanceDue'] ?? '85 MRU';
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pay Balance Due',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2C2520),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount due after final weighing: $balance',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7A6A60),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Get.back();
                setState(() {
                  booking['hasBalanceDue'] = false;
                  booking['price'] = booking['estimatedPrice'] != null
                      ? '${booking['price']} (Paid)'
                      : booking['price'];
                });
                Get.snackbar(
                  'Payment Successful',
                  'Balance of $balance paid successfully!',
                  backgroundColor: const Color(0xFF2E7D32),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              },
              child: Container(
                width: double.infinity,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Confirm & Pay $balance',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
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
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          'No bookings found',
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildBookingCard(list[index]);
                        },
                      ),
              ),
            ],
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
            alignment: Alignment.centerLeft,
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
          Text(
            'My Bookings',
            style: AppTextStyles.heading(),
          ),
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
                _filters[index],
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
                  isCompleted ? 'Completed' : statusText.toUpperCase(),
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
                category,
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
                    onTap: () {},
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EBE3),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'Reorder',
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
                    onTap: () {},
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EBE3),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'Rate',
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
                            'BALANCE DUE',
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
                          'Estimated Weight: 3.0 kg',
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
                              const TextSpan(text: 'Actual Scale Weight: '),
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
                          'Balance Due',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Amount due after final weighing',
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
                onTap: () => _payBalance(booking),
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
                    'Pay ${booking['balanceDue'] ?? '85 MRU'}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () => showCancelBookingBottomSheet(
                  context,
                  bookingId: booking['id'] as String?,
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
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                        'View Booking Details',
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
