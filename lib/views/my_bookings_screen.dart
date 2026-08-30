import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import 'services/car_wash_booking_detail_screen.dart';
import 'services/home_cleaning_booking_detail_screen.dart';
import 'services/laundry_booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedFilter = 0;

  static const _filters = ['All', 'Home Cleaning', 'Car Wash', 'Laundry'];

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
      'location': 'Near Marhaba Supermarket, Nouakchott',
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
      'service': 'Basic Wash x2',
      'status': 'Confirmed',
      'datetime': 'Today, 15 Aug 2026, 2:00–4:00 PM',
      'slot': '15 Aug 2026, 2:00 PM – 4:00 PM',
      'location': 'CleanRide Car Wash, Near Nouakchott, Mauritania',
      'locationTitle': 'CleanRide Car Wash',
      'rooms': 'Sedan · SUV',
      'price': '550 MRU',
      'vehicleLabel': 'Sedan',
      'vehiclePrice': '550 MRU',
      'duration': '30 min',
      'vehicleImage':
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400&h=280&fit=crop',
      'image':
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=400&h=280&fit=crop',
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
      'location': 'Near Marhaba Supermarket, Nouakchott',
      'locationTitle': 'Sahara View Home',
      'price': '450 MRU',
      'estimateLabel': 'Estimated 3 kg',
      'duration': '24 hour',
      'image': 'lib/assets/images/wash&fold_detail.png',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 0) return _bookings;
    final key = _filters[_selectedFilter];
    return _bookings.where((b) => b['category'] == key).toList();
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFE6F6EC);
      case 'completed':
        return const Color(0xFFE8F1FF);
      case 'cancelled':
        return const Color(0xFFFFE8E8);
      default:
        return const Color(0xFFFFF3EB);
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF1B7A3E);
      case 'completed':
        return const Color(0xFF2B5A9E);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFFF5E00);
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
            child: GestureDetector(
              onTap: () {
                if (Get.isRegistered<HomeController>()) {
                  Get.find<HomeController>()
                      .selectNavigation(HomeController.navHome);
                  return;
                }
                Get.back();
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF5E00),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFFF5E00),
                  size: 15,
                ),
              ),
            ),
          ),
          Text(
            'My Bookings',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
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
    final status = booking['status'] as String;
    final categoryColor = Color(booking['categoryColor'] as int);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  booking['provider'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: _statusFg(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                booking['category'] as String,
                style: GoogleFonts.outfit(
                  color: categoryColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEDE6DF)),
          const SizedBox(height: 12),
          Text(
            booking['service'] as String,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1B2B4A),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
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
                  booking['datetime'] as String,
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
                  booking['location'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF5A5048),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (status.toLowerCase() != 'cancelled' &&
              status.toLowerCase() != 'completed') ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EBE3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1B2B4A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () {
                final category = booking['category'] as String?;
                if (category == 'Car Wash') {
                  Get.to(() => CarWashBookingDetailScreen(booking: booking));
                } else if (category == 'Laundry') {
                  Get.to(() => LaundryBookingDetailScreen(booking: booking));
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFF5E00),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
