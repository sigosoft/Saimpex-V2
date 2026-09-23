import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../widgets/app_back_button.dart';
import '../navigation/bottom_nav_router.dart';

/// Shown after a user confirms cancelling an order.
class OrderCancelledSuccessScreen extends StatelessWidget {
  final String? orderId;

  const OrderCancelledSuccessScreen({
    super.key,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

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
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBackButton(
                  onTap: () => _goHome(context),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'lib/assets/images/Success.png',
                        width: 88,
                        height: 88,
                        errorBuilder: (_, _, _) => Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5E00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Order Cancelled',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your order has been cancelled\n'
                        'successfully.\n'
                        'The paid amount has been refunded to\n'
                        'your SAIMPEX Wallet.',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8C7D73),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _goHome(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFE8DED6),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goHome(BuildContext context) {
    if (Get.isRegistered<HomeController>()) {
      BottomNavRouter.returnToShell(tabIndex: HomeController.navHome);
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
