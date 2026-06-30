import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/onboarding_controller.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          controller.onboardingPages.length,
          (index) {
            final isActive = controller.currentIndex.value == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 6),
              height: 6,
              width: isActive ? 24 : 6,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFF5E00)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        ),
      ),
    );
  }
}
