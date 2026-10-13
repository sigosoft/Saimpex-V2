import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';

/// Maps the language chosen in the app to the API language code.
String apiLanguageCode() {
  if (!Get.isRegistered<OnboardingController>()) return 'en';

  final selected = Get.find<OnboardingController>().selectedLanguage.value
      .trim()
      .toLowerCase();

  if (selected == 'fr' || selected == 'français' || selected == 'francais') {
    return 'fr';
  }
  if (selected == 'ar' || selected == 'العربية') {
    return 'ar';
  }
  return 'en';
}
