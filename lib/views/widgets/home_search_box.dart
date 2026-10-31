import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../utils/toast_helper.dart';
import '../home_scanner_screen.dart';
import '../all_search_screen.dart';
import 'search_camera_button.dart';

class HomeSearchBox extends StatefulWidget {
  const HomeSearchBox({super.key});

  @override
  State<HomeSearchBox> createState() => _HomeSearchBoxState();
}

class _HomeSearchBoxState extends State<HomeSearchBox> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speech = SpeechToText();

  bool _listening = false;
  bool _scanning = false;
  bool _speechReady = false;
  bool _heardListening = false;

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search([String? keyword]) {
    final text = (keyword ?? _controller.text).trim();
    if (text.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Get.to(() => AllSearchScreen(initialKeyword: text));
  }

  void _stopListeningUi() {
    _heardListening = false;
    if (!mounted) return;
    setState(() => _listening = false);
  }

  Future<void> _toggleVoiceSearch() async {
    if (_listening) {
      _stopListeningUi();
      if (_speechReady) {
        await _speech.stop();
      }
      return;
    }

    setState(() => _listening = true);

    try {
      _speechReady = await _speech.initialize(
        onError: (error) {
          if (!mounted) return;
          _stopListeningUi();
          if (error.errorMsg == 'error_no_match' ||
              error.errorMsg == 'error_speech_timeout') {
            showAppToast('Didn\'t catch that. Try again.');
            return;
          }
          showAppToast('Voice search isn\'t available right now.');
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'listening') {
            _heardListening = true;
            setState(() => _listening = true);
            return;
          }
          if (_heardListening &&
              (status == 'done' || status == 'notListening')) {
            _stopListeningUi();
          }
        },
      );
    } on MissingPluginException {
      _stopListeningUi();
      showAppToast('Stop the app and run it again to use voice search.');
      return;
    } catch (_) {
      _stopListeningUi();
      showAppToast('Voice search isn\'t available right now.');
      return;
    }
    if (!_speechReady) {
      _stopListeningUi();
      showAppToast('Allow microphone access to use voice search.');
      return;
    }
    if (!mounted || !_listening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (!mounted) return;
          if (words.isNotEmpty) {
            final text = _titleCase(words);
            _controller.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
          }
          if (result.finalResult) {
            _stopListeningUi();
            _search();
            return;
          }
          setState(() => _listening = true);
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
          listenMode: ListenMode.search,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } on MissingPluginException {
      _stopListeningUi();
      showAppToast('Stop the app and run it again to use voice search.');
    } catch (_) {
      _stopListeningUi();
      showAppToast('Voice search isn\'t available right now.');
    }
  }

  Future<void> _scanImage() async {
    if (_scanning) return;
    final path = await Get.to<String>(() => const HomeScannerScreen());
    if (path == null || !mounted) return;

    setState(() => _scanning = true);
    try {
      final text = await labelScannedImage(path);
      if (!mounted || text == null) return;
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _search(text);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _searchField(),
          if (_listening) ...[
            const SizedBox(height: 10),
            const _RecordingBanner(),
          ],
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFFA59A94), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.outfit(color: Colors.black, fontSize: 13),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: _listening
                    ? 'Listening...'
                    : 'What do you need today?',
                hintStyle: GoogleFonts.outfit(
                  color: _listening
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFA59A94),
                  fontSize: 12.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: _scanning ? null : _scanImage,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 28,
              height: 32,
              child: Center(
                child: _scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF5E00),
                        ),
                      )
                    : Image.asset(
                        'lib/assets/images/Camera.png',
                        width: 20,
                        height: 20,
                        color: Colors.black,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _toggleVoiceSearch,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _listening
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFFFFF0E0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'lib/assets/images/Voice.png',
                width: 16,
                height: 16,
                color: _listening ? Colors.white : const Color(0xFFFF5E00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingBanner extends StatefulWidget {
  const _RecordingBanner();

  @override
  State<_RecordingBanner> createState() => _RecordingBannerState();
}

class _RecordingBannerState extends State<_RecordingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD7C2)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = 1 + (_pulse.value * 0.18);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFF5E00,
                    ).withValues(alpha: 0.18 + (_pulse.value * 0.25)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E00),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Listening... tap the mic to stop',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8A7E76),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
