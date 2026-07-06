import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'track_order_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top-Left custom Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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

              const Spacer(),

              // 2. Centered success layout
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'lib/assets/images/Success.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Order Placed Successfully!',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Congratulations! You\'ve earned 10 points',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFEAD8C9),
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Back to Home',
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
                        Get.to(() => const TrackOrderScreen());
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5E00).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'View Order',
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
    );
  }
}
