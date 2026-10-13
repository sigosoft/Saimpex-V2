import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../core/network/api_exception.dart';
import '../core/storage/session_store.dart';
import '../models/auth_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../views/otp_screen.dart';
import 'otp_controller.dart';

class LoginController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final selectedCountryCode = '+222'.obs;
  final selectedCountryFlag = '🇲🇷'.obs;
  final isLoading = false.obs;

  AuthRepository get _auth => Get.find<AuthRepository>();

  void setCountry(String code, String flag) {
    selectedCountryCode.value = code;
    selectedCountryFlag.value = flag;
  }

  Future<void> continueLogin() async {
    if (isLoading.value) return;

    final mobile = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (mobile.isEmpty) {
      showAppToast('Please enter your WhatsApp number');
      return;
    }

    final language = apiLanguageCode();
    final countryCode = selectedCountryCode.value;

    isLoading.value = true;
    try {
      final message = await _auth.sendOtp(
        countryCode: countryCode,
        mobile: mobile,
        language: language,
      );
      showAppToast(message, backgroundColor: AppColors.primaryOrange);

      if (Get.isRegistered<OtpController>()) {
        await Get.delete<OtpController>(force: true);
      }

      Get.to(
        () => const OtpScreen(),
        arguments: OtpArgs(
          countryCode: countryCode,
          mobile: mobile,
          language: language,
          displayNumber: '$countryCode $mobile',
        ),
      );
    } on ApiException catch (error) {
      showAppToast(error.message);
    } finally {
      isLoading.value = false;
    }
  }

  void loginAsGuest() {
    Get.find<SessionStore>().clear();
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
