import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  bool _pushNotifications = true;
  bool _whatsappNotifications = true;

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
                          'Notifications',
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
                          title: 'Push Notifications',
                          subtitle: 'Order updates and offers',
                          value: _pushNotifications,
                          onChanged: (v) =>
                              setState(() => _pushNotifications = v),
                        ),
                        const SizedBox(height: 18),
                        _buildToggleRow(
                          asset: 'lib/assets/images/whatsapp.png',
                          iconBg: const Color(0xFFFFF0E6),
                          title: 'WhatsApp Notifications',
                          subtitle: 'Delivery alerts via WhatsApp',
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
                          'Appearance',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF5E00),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNavRow(
                          icon: Icons.translate_rounded,
                          title: 'Language',
                          value: 'English',
                          showChevron: true,
                        ),
                        const SizedBox(height: 18),
                        _buildNavRow(
                          asset: 'lib/assets/images/currency.png',
                          title: 'Currency',
                          value: 'MRU',
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
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFFF5E00),
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'App Preferences',
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
            color: Colors.black.withOpacity(0.03),
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
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: asset != null
              ? Image.asset(
                  asset,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                )
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
  }) {
    return Row(
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
        Text(
          value,
          style: GoogleFonts.outfit(
            color: const Color(0xFFFF5E00),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showChevron) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFFF5E00),
            size: 22,
          ),
        ],
      ],
    );
  }
}
