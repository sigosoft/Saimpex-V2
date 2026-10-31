import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../controllers/onboarding_controller.dart';
import '../../core/storage/session_store.dart';
import '../../models/profile_repository.dart';
import '../../utils/toast_helper.dart';

class AppLanguage {
  final String code;
  final String label;

  const AppLanguage({required this.code, required this.label});
}

const List<AppLanguage> appLanguages = [
  AppLanguage(code: 'EN', label: 'English'),
  AppLanguage(code: 'FR', label: 'Français'),
  AppLanguage(code: 'AR', label: 'العربية'),
];

OnboardingController languageController() {
  if (Get.isRegistered<OnboardingController>()) {
    return Get.find<OnboardingController>();
  }
  return Get.put(OnboardingController());
}

Future<void> openLanguageSelection(BuildContext context) async {
  final controller = languageController();
  final selected = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (context) => LanguageSelectionSheet(
      currentLanguage: controller.selectedLanguage.value,
    ),
  );

  if (selected != null && selected != controller.selectedLanguage.value) {
    controller.setLanguage(selected);
  }
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = languageController();

    return GestureDetector(
      onTap: () => openLanguageSelection(context),
      child: Obx(
        () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                controller.selectedLanguage.value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageSelectionSheet extends StatefulWidget {
  final String currentLanguage;

  const LanguageSelectionSheet({super.key, required this.currentLanguage});

  @override
  State<LanguageSelectionSheet> createState() => _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<LanguageSelectionSheet> {
  late int _selectedIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final index = appLanguages.indexWhere(
      (lang) => lang.label == widget.currentLanguage,
    );
    _selectedIndex = index < 0 ? 0 : index;
  }

  Future<void> _handleContinue() async {
    if (_isSaving) return;
    final selectedLang = appLanguages[_selectedIndex];

    if (Get.isRegistered<SessionStore>() &&
        Get.find<SessionStore>().token != null &&
        Get.find<SessionStore>().token!.isNotEmpty &&
        Get.isRegistered<ProfileRepository>()) {
      setState(() => _isSaving = true);
      try {
        final code = selectedLang.code.toLowerCase();
        final message = await Get.find<ProfileRepository>().updateLanguage(
          code,
        );
        showAppToast(
          message.isNotEmpty ? message : 'core_language_updated'.tr,
          backgroundColor: AppColors.primaryOrange,
        );
      } catch (e) {
        showAppToast(e.toString());
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }

    if (mounted) {
      Navigator.of(context).pop(selectedLang.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 28, 20, 8 + bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'core_language_select_title'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'core_language_select_subtitle'.tr,
              style: GoogleFonts.outfit(
                color: const Color(0xFF8A7E76),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < appLanguages.length; i++) ...[
              _LanguageOptionCard(
                language: appLanguages[i],
                selected: _selectedIndex == i,
                onTap: () => setState(() => _selectedIndex = i),
              ),
              if (i < appLanguages.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 28),
            _SheetActionButton(
              label: _isSaving
                  ? 'core_language_updating'.tr
                  : 'core_continue'.tr,
              onTap: _isSaving ? () {} : _handleContinue,
            ),
            const SizedBox(height: 12),
            _SheetActionButton(
              label: 'cancel'.tr,
              filled: false,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _SheetActionButton({
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: filled ? null : const Color(0xFFE8E8E8),
          gradient: filled
              ? const LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.gradientYellow],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: filled ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4EF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFF5E00) : const Color(0xFFF3DDD2),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                language.code,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                language.label,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5E00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD5CDC6),
                    width: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
