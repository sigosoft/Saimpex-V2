import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/onboarding_model.dart';
import '../views/login_screen.dart';
import '../utils/toast_helper.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentIndex = 0.obs;
  final selectedLanguage = 'English'.obs;

  final List<OnboardingModel> onboardingPages = [
    OnboardingModel(
      title: 'Order Anything,\nAnytime',
      description:
          'Food, groceries, pharmacy, water, courier, and local stores—all delivered fast from trusted nearby businesses',
      imagePath: 'lib/assets/images/Onboard1.png',
    ),
    OnboardingModel(
      title: 'Everything\ndelivered, fast',
      description:
          'Enjoy a seamless delivery experience with real-time tracking and trusted service',
      imagePath: 'lib/assets/images/Onboard2.png',
    ),
    OnboardingModel(
      title: 'Unlock\nExclusive Offers',
      description:
          'Save more on every order with exciting deals, special rewards, and exclusive offers made just for you',
      imagePath: 'lib/assets/images/Onboard3.png',
    ),
  ];

  bool get isLastPage => currentIndex.value == onboardingPages.length - 1;

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  void nextPage() {
    if (isLastPage) {
      Get.offAll(() => const LoginScreen(), transition: Transition.fadeIn);
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipPage() {
    Get.offAll(() => const LoginScreen(), transition: Transition.fadeIn);
  }

  void setLanguage(String language) {
    selectedLanguage.value = language;
    showAppToast(
      'Language switched to $language',
      backgroundColor: Colors.white.withOpacity(0.9),
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
