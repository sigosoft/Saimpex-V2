import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/toast_helper.dart';
import '../views/select_location_screen.dart';

class OtpController extends GetxController {
  final String phoneNumber = Get.arguments ?? '+222 45 12 34 56';

  final List<TextEditingController> codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  final secondsRemaining = 45.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    secondsRemaining.value = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  void resendCode() {
    if (secondsRemaining.value == 0) {
      // Clear inputs on resend
      for (var controller in codeControllers) {
        controller.clear();
      }
      // Refocus first field
      focusNodes[0].requestFocus();

      startTimer();
      showAppToast(
        'OTP code resent successfully',
        backgroundColor: const Color(0xFFFF5E00),
      );
    }
  }

  void verifyOtp() {
    final code = codeControllers.map((c) => c.text).join();

    // Process verify mock
    showAppToast(
      'OTP verified successfully: $code',
      backgroundColor: const Color(0xFFFF5E00),
    );
    Get.to(() => const SelectLocationScreen());
  }

  @override
  void onClose() {
    _timer?.cancel();
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in codeControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
