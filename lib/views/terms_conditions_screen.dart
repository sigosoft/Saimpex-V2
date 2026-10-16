import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/general_repository.dart';
import '../utils/api_language.dart';
import '../widgets/app_back_button.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({
    super.key,
    this.title = 'Terms & Conditions',
    this.isAboutUs = false,
    this.isPrivacyPolicy = false,
    this.isTermsAndConditions = false,
  });

  final String title;
  final bool isAboutUs;
  final bool isPrivacyPolicy;
  final bool isTermsAndConditions;

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  late String _pageTitle;
  List<String> _paragraphs = [];
  bool _isLoading = false;

  bool get _shouldFetchAbout =>
      widget.isAboutUs || widget.title.toLowerCase().trim() == 'about us';

  bool get _shouldFetchPrivacyPolicy =>
      widget.isPrivacyPolicy ||
      widget.title.toLowerCase().contains('privacy');

  bool get _shouldFetchTerms =>
      widget.isTermsAndConditions ||
      widget.title.toLowerCase().contains('terms');

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.title;
    if (_shouldFetchAbout) {
      _isLoading = true;
      _fetchAbout();
    } else if (_shouldFetchPrivacyPolicy) {
      _isLoading = true;
      _fetchPrivacyPolicy();
    } else if (_shouldFetchTerms) {
      _isLoading = true;
      _fetchTerms();
    }
  }

  Future<void> _fetchTerms() async {
    if (!Get.isRegistered<GeneralRepository>()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final terms = await Get.find<GeneralRepository>().fetchTermsAndConditions(
        apiLanguageCode(),
      );
      if (!mounted) return;
      final parsed = _parseHtmlToParagraphs(terms.content);
      setState(() {
        _isLoading = false;
        if (terms.title.isNotEmpty) _pageTitle = terms.title;
        _paragraphs = parsed;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAbout() async {
    if (!Get.isRegistered<GeneralRepository>()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final about = await Get.find<GeneralRepository>().fetchAbout(
        apiLanguageCode(),
      );
      if (!mounted) return;
      final parsed = _parseHtmlToParagraphs(about.content);
      setState(() {
        _isLoading = false;
        if (about.title.isNotEmpty) _pageTitle = about.title;
        _paragraphs = parsed;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPrivacyPolicy() async {
    if (!Get.isRegistered<GeneralRepository>()) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final policy = await Get.find<GeneralRepository>().fetchPrivacyPolicy(
        apiLanguageCode(),
      );
      if (!mounted) return;
      final parsed = _parseHtmlToParagraphs(policy.content);
      setState(() {
        _isLoading = false;
        if (policy.title.isNotEmpty) _pageTitle = policy.title;
        _paragraphs = parsed;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _parseHtmlToParagraphs(String html) {
    if (html.trim().isEmpty) return const [];
    final text = html
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|h[1-6]|div)>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"');

    return text
        .split(RegExp(r'\n{2,}|\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < _paragraphs.length; i++) ...[
                            if (i > 0) const SizedBox(height: 18),
                            Text(
                              _paragraphs[i],
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.55,
                              ),
                            ),
                          ],
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
              _pageTitle,
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
}
