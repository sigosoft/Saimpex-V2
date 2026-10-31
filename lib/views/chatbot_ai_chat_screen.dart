import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../constants/colors.dart';
import '../controllers/select_location_controller.dart';
import '../core/network/api_exception.dart';
import '../models/chatbot_repository.dart';
import '../utils/api_language.dart';
import '../widgets/app_back_button.dart';

/// The SAIMPEX assistant (Claude, via the backend; API §6.19). The customer
/// types or speaks; the server answers about SAIMPEX and their own orders,
/// wallet and points. It is read-only: it never changes a cart or places an
/// order. [languageCode] (EN/FR/AR, from the welcome sheet) sets the greeting
/// and the voice input language; the server replies in the message's language.
class ChatBotAiChatScreen extends StatefulWidget {
  final String languageCode;

  const ChatBotAiChatScreen({super.key, this.languageCode = 'EN'});

  @override
  State<ChatBotAiChatScreen> createState() => _ChatBotAiChatScreenState();
}

class _ChatBotAiChatScreenState extends State<ChatBotAiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatItem> _messages = [];
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  late String _languageCode;
  Timer? _idleTimer;
  static const Duration _idleTimeout = Duration(minutes: 2);

  /// Returned by the first reply; sent with every later message.
  int? _conversationId;
  bool _sending = false;
  bool _speechReady = false;
  bool _listening = false;

  static const _languages = [
    _LangOption(code: 'EN', label: 'English', speechLocale: 'en_US'),
    _LangOption(code: 'FR', label: 'Français', speechLocale: 'fr_FR'),
    _LangOption(code: 'AR', label: 'العربية', speechLocale: 'ar_SA'),
  ];

  bool get _hasChat => _messages.isNotEmpty || _sending;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode;
    _resetIdleTimer();
  }

  _LangOption get _language => _languages.firstWhere(
    (l) => l.code == _languageCode,
    orElse: () => _languages.first,
  );

  /// [key] in the chat language picked on the welcome sheet.
  String _inChatLanguage(String key) =>
      Get.translations[_languageCode.toLowerCase()]?[key] ?? key.tr;

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      if (mounted) Navigator.of(context).pop('timeout');
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _sendMessage({
    String? preset,
    String? iconAsset,
    bool viaVoice = false,
  }) async {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty || _sending) return;
    if (!Get.isRegistered<ChatbotRepository>()) return;

    _resetIdleTimer();
    unawaited(_tts.stop());
    setState(() {
      _messages.add(
        _ChatItem(
          text: text,
          isUser: true,
          time: DateTime.now(),
          iconAsset: iconAsset,
        ),
      );
      _messageController.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      // The delivery location lets the assistant find stores near the customer.
      final answer = await Get.find<ChatbotRepository>().sendMessage(
        message: text,
        conversationId: _conversationId,
        latitude: SelectLocationController.selectedLatitude,
        longitude: SelectLocationController.selectedLongitude,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      final reply = answer.reply.isEmpty
          ? 'core_chatbot_error'.tr
          : answer.reply;
      setState(() {
        _conversationId = answer.conversationId ?? _conversationId;
        _messages.add(
          _ChatItem(text: reply, isUser: false, time: DateTime.now()),
        );
      });
      // Admin decides whether replies may be read aloud; only do it when
      // the customer spoke, so a typed chat stays silent.
      if (viaVoice && answer.voiceOutput && answer.reply.isNotEmpty) {
        unawaited(_speak(answer.reply));
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatItem(
            text: error.message,
            isUser: false,
            time: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _resetIdleTimer();
      _scrollToBottom();
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage(_language.speechLocale.replaceAll('_', '-'));
      await _tts.speak(text);
    } catch (_) {
      // Reading aloud is optional; the reply is on screen anyway.
    }
  }

  Future<void> _toggleListening() async {
    _resetIdleTimer();
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    unawaited(_tts.stop());
    try {
      if (!_speechReady) {
        _speechReady = await _speech.initialize(
          onError: (_) {
            if (mounted) setState(() => _listening = false);
          },
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'done' || status == 'notListening') {
              setState(() => _listening = false);
            }
          },
        );
      }
    } catch (_) {
      _speechReady = false;
    }
    if (!mounted) return;
    if (!_speechReady) {
      _showSnack('core_home_search_allow_mic'.tr);
      return;
    }
    setState(() => _listening = true);
    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          _messageController.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
          if (result.finalResult) {
            setState(() => _listening = false);
            if (words.isNotEmpty) _sendMessage(viaVoice: true);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: _language.speechLocale,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _listening = false);
      _showSnack('core_home_search_voice_unavailable'.tr);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.outfit())),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _showLanguagePicker() async {
    _resetIdleTimer();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SheetFrame(
          children: [
            ..._languages.map((lang) {
              final selected = lang.code == _languageCode;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  lang.label,
                  style: GoogleFonts.outfit(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryOrange
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryOrange,
                      )
                    : null,
                onTap: () => Navigator.pop(context, lang.code),
              );
            }),
          ],
        );
      },
    );

    if (selected != null && selected != _languageCode) {
      setState(() => _languageCode = selected);
    }
  }

  /// Earlier conversations (chatbot/conversations); picking one shows its
  /// transcript and continues it. "New chat" starts a fresh conversation.
  Future<void> _showHistory() async {
    _resetIdleTimer();
    if (!Get.isRegistered<ChatbotRepository>()) return;
    final repository = Get.find<ChatbotRepository>();
    final language = apiLanguageCode();
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SheetFrame(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.add_comment_outlined,
              color: AppColors.primaryOrange,
            ),
            title: Text(
              'core_chatbot_new_chat'.tr,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange,
              ),
            ),
            onTap: () => Navigator.pop(context, 0),
          ),
          const Divider(height: 1, color: Color(0xFFF0E6DE)),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: repository.conversations(language),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryOrange,
                  ),
                );
              }
              final rows = snapshot.data ?? const [];
              if (snapshot.hasError || rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'core_chatbot_no_history'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: const Color(0xFF7A6A60)),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final row in rows)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${row['title'] ?? ''}'.trim().isEmpty
                              ? 'core_chatbot_untitled'.tr
                              : '${row['title']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        subtitle: Text(
                          _dateLabel(row['updated_at'] ?? row['created_at']),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF9A9088),
                          ),
                        ),
                        selected: '${row['id']}' == '$_conversationId',
                        onTap: () => Navigator.pop(
                          context,
                          int.tryParse('${row['id']}'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
    if (!mounted || picked == null) return;
    if (picked == 0) {
      setState(() {
        _conversationId = null;
        _messages.clear();
      });
      return;
    }
    await _openConversation(picked);
  }

  Future<void> _openConversation(int id) async {
    setState(() => _sending = true);
    try {
      final rows = await Get.find<ChatbotRepository>().transcript(
        conversationId: id,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _messages
          ..clear()
          ..addAll([
            for (final row in rows)
              if ('${row['text'] ?? ''}'.trim().isNotEmpty)
                _ChatItem(
                  text: '${row['text']}'.trim(),
                  isUser: row['from'] == 'customer',
                  time: _parseTime(row['at']) ?? DateTime.now(),
                ),
          ]);
      });
    } on ApiException catch (error) {
      if (mounted) _showSnack(error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  DateTime? _parseTime(dynamic value) =>
      DateTime.tryParse('${value ?? ''}')?.toLocal();

  String _dateLabel(dynamic value) {
    final time = _parseTime(value);
    if (time == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)}/${time.year} '
        '${_formatTime(time)}';
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _speech.cancel();
    _tts.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4EE), Color(0xFFFAF6F0), Color(0xFFFFE8DC)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Stack(
                    children: [
                      // Faint robot watermark behind chat
                      if (_hasChat)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Opacity(
                                opacity: 0.07,
                                child: Image.asset(
                                  'lib/assets/images/chatbot_screen.png',
                                  width: 260,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      _hasChat ? _buildChatList() : _buildEmptyState(),
                    ],
                  ),
                ),
                _buildQuickActions(),
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/assets/images/chatbot.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  'Saimpex Ai',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                AppBackButton(onTap: () => Navigator.of(context).pop()),
                const Spacer(),
                GestureDetector(
                  onTap: _sending ? null : _showHistory,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.45),
                        width: 1.1,
                      ),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.primaryOrange,
                      size: 18,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showLanguagePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.45),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.translate_rounded,
                          color: AppColors.primaryOrange,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _language.label,
                          style: GoogleFonts.outfit(
                            color: AppColors.primaryOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryOrange,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
          Image.asset(
            'lib/assets/images/chatbot_screen.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            _inChatLanguage('core_chatbot_greeting'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF111111),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _inChatLanguage('core_chatbot_intro'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF3A3A3A),
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _MessageBubble(
            message: _ChatItem(
              text: _inChatLanguage('core_chatbot_thinking'),
              isUser: false,
              time: DateTime.now(),
            ),
            timeLabel: '',
            pending: true,
          );
        }
        final item = _messages[index];
        return _MessageBubble(message: item, timeLabel: _formatTime(item.time));
      },
    );
  }

  Widget _buildQuickActions() {
    // Sent as ordinary questions in the chat language; the assistant answers
    // from the customer's real orders and offers.
    final actions = [
      _QuickAction(
        label: _inChatLanguage('core_chatbot_track_order'),
        iconAsset: 'lib/assets/images/track_order.png',
      ),
      _QuickAction(
        label: _inChatLanguage('core_chatbot_cancel_order'),
        iconAsset: 'lib/assets/images/close.png',
      ),
      _QuickAction(
        label: _inChatLanguage('core_chatbot_offers'),
        iconAsset: 'lib/assets/images/offers.png',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _QuickActionChip(
                action: actions[i],
                onTap: () => _sendMessage(
                  preset: actions[i].label,
                  iconAsset: actions[i].iconAsset,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        10 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F1EA),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _sending ? null : _toggleListening,
                    child: Icon(
                      _listening ? Icons.stop_circle_rounded : Icons.mic_none,
                      color: _listening
                          ? AppColors.primaryOrange
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_listening,
                      maxLength: 2000,
                      onChanged: (_) => _resetIdleTimer(),
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: _listening
                            ? 'core_chatbot_listening'.tr
                            : 'core_chatbot_type_message'.tr,
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : () => _sendMessage(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _sending
                    ? AppColors.primaryOrange.withValues(alpha: 0.5)
                    : AppColors.primaryOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? iconAsset;

  /// A translated error from the server (limit reached, switched off, ...).
  final bool isError;

  const _ChatItem({
    required this.text,
    required this.isUser,
    required this.time,
    this.iconAsset,
    this.isError = false,
  });
}

class _LangOption {
  final String code;
  final String label;
  final String speechLocale;
  const _LangOption({
    required this.code,
    required this.label,
    required this.speechLocale,
  });
}

/// White rounded bottom sheet with a drag handle.
class _SheetFrame extends StatelessWidget {
  final List<Widget> children;
  const _SheetFrame({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0D8D2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final String iconAsset;
  const _QuickAction({required this.label, required this.iconAsset});
}

class _QuickActionChip extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback onTap;
  const _QuickActionChip({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconSize = action.iconAsset == 'lib/assets/images/close.png'
        ? 20.0
        : 16.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1E8),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                action.iconAsset,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatItem message;
  final String timeLabel;

  /// The "thinking" placeholder while the reply is on its way.
  final bool pending;

  const _MessageBubble({
    required this.message,
    required this.timeLabel,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final iconSize = message.iconAsset == 'lib/assets/images/close.png'
        ? 22.0
        : 18.0;

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFDE8E1)
                    : message.isError
                    ? const Color(0xFFFFECEC)
                    : const Color(0xFFFFF8F3),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(18),
                  topEnd: const Radius.circular(18),
                  bottomStart: Radius.circular(isUser ? 18 : 6),
                  bottomEnd: Radius.circular(isUser ? 6 : 18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser && message.iconAsset != null) ...[
                    Image.asset(
                      message.iconAsset!,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (pending) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: SelectableText(
                      message.text,
                      style: GoogleFonts.outfit(
                        color: isUser
                            ? const Color(0xFFE85A1A)
                            : message.isError
                            ? const Color(0xFFD32F2F)
                            : pending
                            ? const Color(0xFF9A9088)
                            : const Color(0xFF2A2A2A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (timeLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeLabel,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF9A9088),
                        fontSize: 11,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: AppColors.primaryOrange,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
