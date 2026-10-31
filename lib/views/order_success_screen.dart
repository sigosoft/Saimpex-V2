import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_back_button.dart';
import 'my_orders_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  /// Store points this order will earn once delivered (0 hides the line).
  final int pointsToEarn;

  const OrderSuccessScreen({super.key, this.pointsToEarn = 0});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFFF7F2),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top-Left custom Back Button
                AppBackButton(onTap: () => Navigator.pop(context)),

                const Spacer(),

                // 2. Centered success layout matching reference image
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success Icon Badge
                      Image.asset(
                        'lib/assets/images/Success.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5E00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'orders_placed_title'.tr,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (pointsToEarn > 0) ...[
                        const SizedBox(height: 8),
                        // Points are credited only after delivery (scope §4).
                        Text(
                          'orders_earn_points_on_delivery'.trParams({
                            'points': '$pointsToEarn',
                          }),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF8C7D73),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // 3. Action Buttons (Back to Home and View Order side by side)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Pop all screens and return to HomeScreen
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFFEAD8C9),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'orders_back_to_home'.tr,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFF5E00),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.to(() => const MyOrdersScreen());
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF5E00,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'orders_view_order'.tr,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
