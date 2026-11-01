import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/network/api_exception.dart';
import '../models/profile_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'widgets/language_selector.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  bool _pushNotifications = true;
  bool _whatsappNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPushPreference();
  }

  /// Reads the saved push setting from the server.
  Future<void> _loadPushPreference() async {
    if (!Get.isRegistered<ProfileRepository>()) return;
    try {
      final enabled = await Get.find<ProfileRepository>()
          .fetchNotificationPreference(apiLanguageCode());
      if (mounted) setState(() => _pushNotifications = enabled);
    } on ApiException {
      // Keep the default; the switch still works.
    }
  }

  /// Saves a push change; the switch goes back if the server rejects it.
  Future<void> _setPushNotifications(bool enabled) async {
    final previous = _pushNotifications;
    setState(() => _pushNotifications = enabled);
    try {
      await Get.find<ProfileRepository>().updateNotificationPreference(
        enabled: enabled,
        language: apiLanguageCode(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _pushNotifications = previous);
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAF6F0),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF6F0),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard(
                      children: [
                        Text(
                          'core_prefs_notifications'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildToggleRow(
                          icon: Icons.notifications_active_outlined,
                          iconBg: const Color(0xFFFFF0E6),
                          iconColor: const Color(0xFFFF5E00),
                          title: 'core_prefs_push'.tr,
                          subtitle: 'core_prefs_push_hint'.tr,
                          value: _pushNotifications,
                          onChanged: (v) => _setPushNotifications(v),
                        ),
                        const SizedBox(height: 18),
                        _buildToggleRow(
                          asset: 'lib/assets/images/whatsapp.png',
                          iconBg: const Color(0xFFFFF0E6),
                          title: 'core_prefs_whatsapp'.tr,
                          subtitle: 'core_prefs_whatsapp_hint'.tr,
                          value: _whatsappNotifications,
                          onChanged: (v) =>
                              setState(() => _whatsappNotifications = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      children: [
                        Text(
                          'core_prefs_appearance'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNavRow(
                          icon: Icons.translate_rounded,
                          title: 'core_prefs_language'.tr,
                          value: languageController().selectedLanguage.value,
                          showChevron: true,
                          onTap: () => openLanguageSelection(context),
                        ),
                        const SizedBox(height: 18),
                        _buildNavRow(
                          asset: 'lib/assets/images/currency.png',
                          title: 'core_prefs_currency'.tr,
                          value: 'core_prefs_mru'.tr,
                          showChevron: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              'core_prefs_title'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildToggleRow({
    IconData? icon,
    String? asset,
    required Color iconBg,
    Color? iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: asset != null
              ? Image.asset(asset, width: 22, height: 22, fit: BoxFit.contain)
              : Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8A7E76),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFFFF5E00),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE8DFD6),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildNavRow({
    IconData? icon,
    String? asset,
    required String title,
    required String value,
    required bool showChevron,
    VoidCallback? onTap,
  }) {
    final row = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0E6),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: asset != null
              ? Image.asset(
                  asset,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  color: const Color(0xFFFF5E00),
                )
              : Icon(icon, color: const Color(0xFFFF5E00), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        onTap == null
            ? Text(
                value,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Obx(
                () => Text(
                  languageController().selectedLanguage.value,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        const SizedBox(width: 4),
        SizedBox(
          width: 22,
          child: showChevron
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFF5E00),
                  size: 22,
                )
              : null,
        ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: row,
    );
  }
}
