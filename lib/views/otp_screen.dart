import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../controllers/otp_controller.dart';
import 'widgets/otp_input_box.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<OtpController>()) {
      Get.delete<OtpController>();
    }
    final controller = Get.put(OtpController());
    final orientation = MediaQuery.of(context).orientation;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.otpBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.otpBg,
        body: SafeArea(
          child: orientation == Orientation.portrait
              ? _buildPortraitLayout(context, controller)
              : _buildLandscapeLayout(context, controller),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, OtpController controller) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button top left
          Align(alignment: Alignment.centerLeft, child: _buildBackButton()),
          const Spacer(flex: 1),
          // Shield graphic
          _buildShieldGraphic(),
          const SizedBox(height: 36),
          // Heading
          Text(
            'OTP Verification',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF2C2520),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "We've sent a 6-digit verification code to your WhatsApp number ${controller.phoneNumber}",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 36),
          // Row of 6 OTP input boxes
          _buildOtpInputs(controller),
          const SizedBox(height: 24),
          // Resend Timer Row
          _buildResendTimer(controller),
          const Spacer(flex: 3),
          // Action button
          _buildContinueButton(controller),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, OtpController controller) {
    return Row(
      children: [
        // Left Column: Branding / Graphic
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBackButton(),
                ),
                const SizedBox(height: 16),
                _buildShieldGraphic(size: 80),
                const SizedBox(height: 16),
                Text(
                  'OTP Verification',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFF2C2520),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We've sent a 6-digit verification code to your WhatsApp number ${controller.phoneNumber}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Column: Form Fields
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.white.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  _buildOtpInputs(controller),
                  const SizedBox(height: 24),
                  _buildResendTimer(controller),
                  const SizedBox(height: 36),
                  _buildContinueButton(controller),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_arrow_left,
          color: AppColors.primaryOrange,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildShieldGraphic({double size = 110}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "lib/assets/images/Otp.png",
              width: size * 0.45,
              height: size * 0.45,
            ),
            Positioned(
              top: size * 0.38,
              child: Icon(
                Icons.check,
                size: size * 0.22,
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInputs(OtpController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => OtpInputBox(
          controller: controller.codeControllers[index],
          focusNode: controller.focusNodes[index],
          nextFocusNode: index < 5 ? controller.focusNodes[index + 1] : null,
          prevFocusNode: index > 0 ? controller.focusNodes[index - 1] : null,
        ),
      ),
    );
  }

  Widget _buildResendTimer(OtpController controller) {
    return Obx(() {
      final isTimerActive = controller.secondsRemaining.value > 0;
      final timeStr =
          '00:${controller.secondsRemaining.value.toString().padLeft(2, '0')}';

      return Column(
        children: [
          Text(
            "Didn't receive the code?",
            style: GoogleFonts.outfit(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: isTimerActive ? null : controller.resendCode,
            child: Text(
              isTimerActive ? 'Resend Code ($timeStr)' : 'Resend Code',
              style: GoogleFonts.outfit(
                color: AppColors.primaryOrange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: isTimerActive
                    ? TextDecoration.none
                    : TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContinueButton(OtpController controller) {
    return GestureDetector(
      onTap: controller.verifyOtp,
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
          child: Text(
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
  }
}
