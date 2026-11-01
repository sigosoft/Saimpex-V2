import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/general_repository.dart';
import '../utils/api_language.dart';
import '../widgets/app_back_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _phone = '';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContact();
  }

  Future<void> _fetchContact() async {
    if (!Get.isRegistered<GeneralRepository>()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final contact = await Get.find<GeneralRepository>().fetchContact(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _phone = contact.phone;
        _email = contact.email;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E00),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Column(
                        children: [
                          _buildContactCard(
                            icon: Icons.phone_in_talk_rounded,
                            label: 'core_help_call_us'.tr,
                            value: _phone,
                            buttonLabel: 'core_help_call_now'.tr,
                            onTap: () {},
                          ),
                          const SizedBox(height: 14),
                          _buildContactCard(
                            icon: Icons.email_rounded,
                            label: 'core_help_email_us'.tr,
                            value: _email,
                            buttonLabel: 'core_help_send_mail'.tr,
                            onTap: () {},
                          ),
                          const SizedBox(height: 14),
                          _buildSupportInfoCard(),
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
              'core_help_title'.tr,
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

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String value,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFFFF5E00), size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
        children: [
          Text(
            'core_help_support_info'.tr,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            title: 'core_help_business_hours'.tr,
            subtitle: 'core_help_hours_value'.tr,
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.phone_in_talk_rounded,
            title: 'core_help_call_support'.tr,
            subtitle: _phone,
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.email_rounded,
            title: 'core_help_support_email'.tr,
            subtitle: _email,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF5E00), size: 22),
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
                  color: const Color(0xFF6B625C),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
