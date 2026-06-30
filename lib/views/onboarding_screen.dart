import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/onboarding_controller.dart';
import 'widgets/language_selector.dart';
import 'widgets/next_button.dart';
import 'widgets/page_indicator.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller using Get.put
    final controller = Get.put(OnboardingController());
    final orientation = MediaQuery.of(context).orientation;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: orientation == Orientation.portrait
            ? _buildPortraitLayout(context, controller)
            : _buildLandscapeLayout(context, controller),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    OnboardingController controller,
  ) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // PageView for screens content
        PageView.builder(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          itemCount: controller.onboardingPages.length,
          itemBuilder: (context, index) {
            final page = controller.onboardingPages[index];
            return Stack(
              children: [
                // Top Collage Image
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.66,
                  child: Image.asset(page.imagePath, fit: BoxFit.cover),
                ),
                // Premium gradient overlay to blend image into the dark bottom area
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.66,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                          const Color(0xFF0E0E0E),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Heading & Description Text
                Positioned(
                  bottom:
                      size.height * 0.16 +
                      20, // Perfectly above indicator controls
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.description,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        // Top Navigation Header (Language selector + SKIP button)
        Positioned(
          top: padding.top + 16,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LanguageSelector(),
              GestureDetector(
                onTap: controller.skipPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'SKIP',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom Action Controls (Indicators + Next Button)
        Positioned(
          bottom: padding.bottom + 24,
          left: 24,
          right: 24,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [PageIndicator(), NextButton()],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    OnboardingController controller,
  ) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // PageView with landscape row adaptation
        PageView.builder(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          itemCount: controller.onboardingPages.length,
          itemBuilder: (context, index) {
            final page = controller.onboardingPages[index];
            return Row(
              children: [
                // Left Collage Column
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(page.imagePath, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              const Color(0xFF0E0E0E),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Text Column
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      32,
                      padding.top + 80,
                      32,
                      padding.bottom + 80,
                    ),
                    color: const Color(0xFF0E0E0E),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page.title.replaceAll('\n', ' '),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Shared Top Navigation
        Positioned(
          top: padding.top + 12,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LanguageSelector(),
              GestureDetector(
                onTap: controller.skipPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'SKIP',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Shared Bottom Navigation Overlay
        Positioned(
          bottom: padding.bottom + 16,
          right: 32,
          left: size.width * 0.5 + 32,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [PageIndicator(), NextButton()],
          ),
        ),
      ],
    );
  }
}
