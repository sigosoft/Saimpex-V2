import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown in place of the payment options when Admin has switched off every
/// method this checkout offers.
class NoPaymentMethodNote extends StatelessWidget {
  const NoPaymentMethodNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        'payment_no_method'.tr,
        style: GoogleFonts.outfit(
          color: const Color(0xFFEF4444),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
