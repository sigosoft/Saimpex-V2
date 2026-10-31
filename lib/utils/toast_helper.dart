import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void showAppToast(
  String message, {
  Color backgroundColor = const Color(0xFF2C2520),
}) {
  Get.closeAllSnackbars(); // Dismiss any active toast immediately

  Get.showSnackbar(
    GetSnackBar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: backgroundColor.computeLuminance() > 0.5
              ? Colors.black87
              : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor.withValues(alpha: 0.95),
      borderRadius: 25,
      margin: const EdgeInsets.only(bottom: 70, left: 40, right: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      animationDuration: const Duration(milliseconds: 250),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
  );
}

class ToastHelper {
  static void showError(String message) {
    showAppToast(
      message,
      backgroundColor: const Color(0xFFEF4444),
    );
  }

  static void showSuccess(String message) {
    showAppToast(
      message,
      backgroundColor: const Color(0xFF00B25C),
    );
  }

  static void show(String message) {
    showAppToast(message);
  }
}
