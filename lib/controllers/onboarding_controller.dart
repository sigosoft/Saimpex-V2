import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/network/api_exception.dart';
import '../models/general_repository.dart';
import '../models/onboarding_model.dart';
import '../views/login_screen.dart';
import '../utils/toast_helper.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentIndex = 0.obs;
  final selectedLanguage = 'English'.obs;
  final splashSlides = <Map<String, dynamic>>[].obs;

  static final List<OnboardingModel> localPages = [
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

  int get pageCount =>
      splashSlides.isEmpty ? localPages.length : splashSlides.length;

  bool get isLastPage => currentIndex.value == pageCount - 1;

  OnboardingModel pageAt(int index) {
    if (splashSlides.isEmpty) {
      return localPages[index.clamp(0, localPages.length - 1)];
    }
    final slide = splashSlides[index.clamp(0, splashSlides.length - 1)];
    final content = _localizedContent(slide);
    final parts = content.split(RegExp(r'\r?\n\s*\r?\n'));
    final title = parts.first.trim();
    final description = parts.length > 1
        ? parts.sublist(1).join('\n\n').trim()
        : '';
    final fallback = localPages[index % localPages.length];
    final image = slide['image']?.toString() ?? '';
    if (title.isEmpty && description.isEmpty && image.isEmpty) {
      return fallback;
    }
    return OnboardingModel(
      title: title.isEmpty ? fallback.title : title,
      description: description,
      imagePath: image.isEmpty ? fallback.imagePath : image,
    );
  }

  String _localizedContent(Map<String, dynamic> slide) {
    final language = _languageCode(selectedLanguage.value);
    for (final code in [language, 'en', 'fr', 'ar']) {
      final value = slide['content_$code']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _languageCode(String language) {
    final selected = language.trim().toLowerCase();
    if (selected == 'fr' || selected == 'français' || selected == 'francais') {
      return 'fr';
    }
    if (selected == 'ar' || selected == 'العربية') return 'ar';
    return 'en';
  }

  bool _splashRequested = false;

  @override
  void onInit() {
    super.onInit();
    loadSplash();
  }

  Future<void> loadSplash() async {
    if (_splashRequested || !Get.isRegistered<GeneralRepository>()) return;
    _splashRequested = true;
    try {
      final slides = await Get.find<GeneralRepository>().fetchSplash(
        _languageCode(selectedLanguage.value),
      );
      if (slides.isNotEmpty) splashSlides.assignAll(slides);
    } on ApiException catch (error) {
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

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
