import 'widgets/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../controllers/login_controller.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/language_selector.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final orientation = MediaQuery.of(context).orientation;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: orientation == Orientation.portrait
            ? _buildPortraitLayout(context, controller)
            : _buildLandscapeLayout(context, controller),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    LoginController controller,
  ) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // Background Collage Image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.35,
          child: Image.asset('lib/assets/images/Login.png', fit: BoxFit.cover),
        ),
        // Dark Overlay for background image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.35,
          child: Container(color: Colors.black.withOpacity(0.25)),
        ),
        // Language Selector on Background
        Positioned(
          top: padding.top + 16,
          left: 20,
          child: const LanguageSelector(),
        ),
        // Bottom White Sheet Content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          top: size.height * 0.28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // White Card
              Positioned.fill(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteSheet,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Title (Serif style matching the image)
                        Text(
                          'Please enter your phone number',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFF2C2520),
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Text(
                          "We'll send you a verification code to get started",
                          style: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Name Input
                        CustomTextField(
                          label: 'Name',
                          hintText: 'Enter your name',
                          controller: controller.nameController,
                        ),
                        const SizedBox(height: 20),
                        // WhatsApp Input
                        CustomTextField(
                          label: 'Whatsapp Number',
                          hintText: 'Enter your whatsapp number',
                          controller: controller.phoneController,
                          keyboardType: TextInputType.phone,
                          prefix: _buildCountrySelector(context, controller),
                        ),
                        const SizedBox(height: 32),
                        // Continue Button
                        _buildContinueButton(controller),
                        const SizedBox(height: 16),
                        // Guest Login Button
                        _buildGuestButton(controller),
                        // Dynamic bottom padding to handle keyboard comfortably
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -18,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryOrange,
                          AppColors.gradientYellow,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Text(
                      'LOGIN OR SIGN UP',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    LoginController controller,
  ) {
    final padding = MediaQuery.of(context).padding;

    return Row(
      children: [
        // Left Column: Background Collage Image (Adaptation)
        Expanded(
          flex: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('lib/assets/images/Onboard1.png', fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.3)),
              Positioned(
                top: padding.top + 16,
                left: 20,
                child: const LanguageSelector(),
              ),
            ],
          ),
        ),
        // Right Column: White Card Form (Adaptation)
        Expanded(
          flex: 6,
          child: Container(
            color: AppColors.whiteSheet,
            child: SafeArea(
              left: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Please enter your phone number',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFF2C2520),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryOrange,
                                AppColors.gradientYellow,
                              ],
                            ),
                          ),
                          child: Text(
                            'LOGIN',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We'll send you a verification code to get started",
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Name',
                      hintText: 'Enter your name',
                      controller: controller.nameController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Whatsapp Number',
                      hintText: 'Enter your whatsapp number',
                      controller: controller.phoneController,
                      keyboardType: TextInputType.phone,
                      prefix: _buildCountrySelector(context, controller),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildContinueButton(controller)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGuestButton(controller)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySelector(
    BuildContext context,
    LoginController controller,
  ) {
    return InkWell(
      onTap: () => _showCountryPicker(context, controller),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25),
        bottomLeft: Radius.circular(25),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.selectedCountryFlag.value,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Text(
                controller.selectedCountryCode.value,
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.black54,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(LoginController controller) {
    return Obx(() {
      final loading = controller.isLoading.value;
      return GestureDetector(
        onTap: loading ? null : controller.continueLogin,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [AppColors.primaryOrange, AppColors.gradientYellow],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Continue',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildGuestButton(LoginController controller) {
    return GestureDetector(
      onTap: controller.loginAsGuest,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.guestBg,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppColors.inputBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Guest Login',
            style: GoogleFonts.outfit(
              color: AppColors.guestText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context, LoginController controller) {
    showCountryCodePicker(onSelected: controller.setCountry);
  }
}
