import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../core/network/api_exception.dart';
import '../core/storage/session_store.dart';
import '../models/auth_repository.dart';
import '../utils/toast_helper.dart';
import '../views/select_location_screen.dart';

class OtpArgs {
  const OtpArgs({
    required this.countryCode,
    required this.mobile,
    required this.language,
    required this.displayNumber,
  });

  final String countryCode;
  final String mobile;
  final String language;
  final String displayNumber;
}

class OtpController extends GetxController {
  late final OtpArgs args;

  final List<TextEditingController> codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  final secondsRemaining = 45.obs;
  final isLoading = false.obs;
  Timer? _timer;

  String get phoneNumber => args.displayNumber;

  AuthRepository get _auth => Get.find<AuthRepository>();
  SessionStore get _session => Get.find<SessionStore>();

  @override
  void onInit() {
    super.onInit();
    args = _readArgs();
    startTimer();
  }

  OtpArgs _readArgs() {
    final raw = Get.arguments;
    if (raw is OtpArgs) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      return OtpArgs(
        countryCode: '+222',
        mobile: raw.replaceAll(RegExp(r'\D'), ''),
        language: 'en',
        displayNumber: raw,
      );
    }
    return const OtpArgs(
      countryCode: '+222',
      mobile: '',
      language: 'en',
      displayNumber: '',
    );
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

  Future<void> resendCode() async {
    if (secondsRemaining.value > 0 || isLoading.value) return;
    if (args.mobile.isEmpty) {
      showAppToast('Phone number is missing. Go back and try again.');
      return;
    }

    isLoading.value = true;
    try {
      final message = await _auth.sendOtp(
        countryCode: args.countryCode,
        mobile: args.mobile,
        language: args.language,
      );

      for (final controller in codeControllers) {
        controller.clear();
      }
      focusNodes.first.requestFocus();
      startTimer();
      showAppToast(message, backgroundColor: AppColors.primaryOrange);
    } on ApiException catch (error) {
      showAppToast(error.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (isLoading.value) return;

    final code = codeControllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      showAppToast('Please enter the 6-digit verification code');
      return;
    }
    if (args.mobile.isEmpty) {
      showAppToast('Phone number is missing. Go back and try again.');
      return;
    }

    isLoading.value = true;
    try {
      final result = await _auth.verifyOtp(
        countryCode: args.countryCode,
        mobile: args.mobile,
        otp: code,
        language: args.language,
      );
      await _session.saveSession(token: result.token, user: result.user);
      showAppToast(result.message, backgroundColor: AppColors.primaryOrange);
      Get.to(() => const SelectLocationScreen());
    } on ApiException catch (error) {
      showAppToast(error.message);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    for (final node in focusNodes) {
      node.dispose();
    }
    for (final controller in codeControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
