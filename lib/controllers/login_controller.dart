import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/otp_screen.dart';
import '../utils/toast_helper.dart';
import '../constants/colors.dart';

class LoginController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final selectedCountryCode = '+222'.obs;
  final selectedCountryFlag = '🇲🇷'.obs; // Mauritania flag as per mockup

  void setCountry(String code, String flag) {
    selectedCountryCode.value = code;
    selectedCountryFlag.value = flag;
  }

  void continueLogin() {
    final phone = phoneController.text.trim();
    final fullNumber = '${selectedCountryCode.value} $phone';

    // Success login mock with toast
    showAppToast(
      'Verification code sent to $fullNumber',
      backgroundColor: AppColors.primaryOrange,
    );

    Get.to(() => const OtpScreen(), arguments: fullNumber);
  }

  void loginAsGuest() {
    showAppToast(
      'Logged in as Guest successfully',
      backgroundColor: const Color(0xFF333333),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
