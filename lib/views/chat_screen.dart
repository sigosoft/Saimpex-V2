import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/api_message.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_store.dart';
import '../models/chat_repository.dart';
import '../utils/api_language.dart';
import '../widgets/app_back_button.dart';

enum _ChatMessageType { text, voice }

class _ChatMessage {
  final _ChatMessageType type;
  final String? text;
  final String? audioPath;
  final Duration? duration;
  final String time;
  final bool isMine;

  const _ChatMessage.text({
    required this.text,
    required this.time,
    this.isMine = false,
  }) : type = _ChatMessageType.text,
       audioPath = null,
       duration = null;

  const _ChatMessage.voice({
    required this.audioPath,
    required this.duration,
    required this.time,
    this.isMine = true,
  }) : type = _ChatMessageType.voice,
       text = null;
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const ChatScreen({super.key, required this.restaurant});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isRecording = false;
  bool _isSending = false;
  bool _isLoadingMessages = false;
  dynamic _conversationId;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;
  String? _playingPath;
  StreamSubscription<void>? _playerCompleteSub;

  List<_ChatMessage> _messages = <_ChatMessage>[];

  ChatRepository _getChatRepo() {
    if (Get.isRegistered<ChatRepository>()) {
      return Get.find<ChatRepository>();
    }
    final session = Get.isRegistered<SessionStore>()
        ? Get.find<SessionStore>()
        : SessionStore();
    final dio = Get.isRegistered<DioClient>()
        ? Get.find<DioClient>()
        : Get.put(DioClient(session), permanent: true);
    return Get.put(ChatRepository(dio), permanent: true);
  }

  dynamic get _vendorId {
    final raw = widget.restaurant;
    final candidates = [
      raw['vendor_id'],
      raw['vendorId'],
      raw['restaurant_id'],
      raw['store_id'],
      raw['pharmacy_id'],
      raw['id'],
    ];
    for (final c in candidates) {
      if (c != null && '$c'.trim().isNotEmpty && '$c'.trim() != '0') {
        return c;
      }
    }
    if (raw['raw'] is Map) {
      final inner = raw['raw'] as Map;
      final innerCandidates = [
        inner['vendor_id'],
        inner['vendorId'],
        inner['restaurant_id'],
        inner['store_id'],
        inner['pharmacy_id'],
        inner['id'],
      ];
      for (final c in innerCandidates) {
        if (c != null && '$c'.trim().isNotEmpty && '$c'.trim() != '0') {
          return c;
        }
      }
    }
    return null;
  }

  bool _checkIsMine(Map<String, dynamic> m, dynamic customerId) {
    if (m['is_mine'] == true ||
        m['is_customer'] == true ||
        m['is_customer'] == 1) {
      return true;
    }
    final senderType = (m['sender_type'] ?? m['sender'] ?? m['type'] ?? '')
        .toString()
        .toLowerCase();
    if (senderType.contains('customer') || senderType.contains('user')) {
      return true;
    }
    if (senderType.contains('vendor') || senderType.contains('restaurant')) {
      return false;
    }
    if (customerId != null && m['sender_id'] != null) {
      return '${m['sender_id']}'.trim() == '$customerId'.trim();
    }
    return false;
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return _nowLabel();
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> _loadConversation() async {
    final vId = _vendorId;
    final cId = _conversationId;
    if (vId == null && cId == null) {
      return;
    }

    setState(() => _isLoadingMessages = true);
    try {
      final repo = _getChatRepo();
      final lang = currentApiLanguage();
      final res = await repo.getConversation(
        vendorId: vId,
        conversationId: cId,
        language: lang,
      );

      final conv = asJsonMap(res['conversation']) ?? res;
      if (conv['id'] != null) {
        _conversationId = conv['id'];
      }

      final customerId =
          conv['customer_id'] ??
          (conv['customer'] is Map ? conv['customer']['id'] : null);

      final rawList = conv['messages'];
      final List<_ChatMessage> parsed = [];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final isMine = _checkIsMine(m, customerId);
          final typeStr = (m['message_type'] ?? 'text')
              .toString()
              .toLowerCase();
          final timeStr = _formatTimestamp(m['created_at']);

          if (typeStr == 'voice' || m['voice_note'] != null) {
            final rawAudio =
                m['voice_note']?.toString() ?? m['attachment_url']?.toString();
            final vUrl = ApiConstants.mediaUrl(rawAudio) ?? rawAudio;
            final durSec = int.tryParse('${m['duration']}') ?? 0;
            parsed.add(
              _ChatMessage.voice(
                audioPath: vUrl,
                duration: Duration(seconds: durSec),
                time: timeStr,
                isMine: isMine,
              ),
            );
          } else {
            parsed.add(
              _ChatMessage.text(
                text: m['message']?.toString() ?? '',
                time: timeStr,
                isMine: isMine,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _messages = parsed;
        _isLoadingMessages = false;
      });
      _scrollToBottom();
      // The customer has now seen the vendor's messages: clear the unread
      // count. Best effort; the list just shows the old count if it fails.
      if (_conversationId != null) {
        unawaited(
          repo
              .markAsRead(conversationId: _conversationId, language: lang)
              .catchError((_) {}),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMessages = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final raw = widget.restaurant;
    _conversationId =
        raw['conversation_id'] ??
        raw['conversationId'] ??
        raw['chat_conversation_id'] ??
        (raw['raw'] is Map
            ? (raw['raw']['conversation_id'] ??
                  raw['raw']['conversationId'] ??
                  raw['raw']['chat_conversation_id'])
            : null);
    _loadConversation();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playingPath = null);
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerCompleteSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatClock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _nowLabel() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopAndSendRecording();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'core_chat_mic_permission'.tr,
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFFFF3E3E),
          ),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      _recordTimer?.cancel();
      setState(() {
        _isRecording = true;
        _recordElapsed = Duration.zero;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordElapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'core_chat_record_failed'.tr,
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFFFF3E3E),
        ),
      );
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _recorder.cancel();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordElapsed = Duration.zero;
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final elapsed = _recordElapsed;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordElapsed = Duration.zero;
    });

    if (path == null || path.isEmpty) return;
    if (elapsed.inSeconds < 1) {
      try {
        await File(path).delete();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'core_chat_hold_longer'.tr,
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFFFF5E00),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage.voice(
          audioPath: path,
          duration: elapsed,
          time: _nowLabel(),
        ),
      );
    });
    _scrollToBottom();

    try {
      final repo = _getChatRepo();
      final lang = currentApiLanguage();
      final res = await repo.sendMessage(
        conversationId: _conversationId,
        vendorId: _vendorId,
        messageType: 'voice',
        voiceNotePath: path,
        duration: elapsed.inSeconds,
        language: lang,
      );
      if (res['conversation_id'] != null) {
        _conversationId = res['conversation_id'];
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e is ApiException
          ? e.message
          : 'core_chat_voice_send_failed'.tr;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFFF3E3E),
        ),
      );
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(
        _ChatMessage.text(text: text, time: _nowLabel(), isMine: true),
      );
      _textController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final repo = _getChatRepo();
      final lang = currentApiLanguage();
      final res = await repo.sendMessage(
        conversationId: _conversationId,
        vendorId: _vendorId,
        message: text,
        messageType: 'text',
        language: lang,
      );
      if (res['conversation_id'] != null) {
        _conversationId = res['conversation_id'];
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e is ApiException
          ? e.message
          : 'core_chat_send_failed'.tr;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFFF3E3E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _togglePlayback(_ChatMessage message) async {
    final path = message.audioPath;
    if (path == null || path.isEmpty) return;

    if (_playingPath == path) {
      await _player.stop();
      setState(() => _playingPath = null);
      return;
    }

    await _player.stop();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      await _player.play(UrlSource(path));
    } else {
      await _player.play(DeviceFileSource(path));
    }
    setState(() => _playingPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.restaurant['title'] as String? ?? 'Pharmacy Nasr';
    final image =
        widget.restaurant['image'] as String? ??
        'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=150&auto=format&fit=crop';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFAF6F0), Color(0xFFFFEEE5), Color(0xFFFFDDCF)],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  ClipOval(
                    child: image.isEmpty
                        ? Container(
                            width: 40,
                            height: 40,
                            color: const Color(0xFFF3EFEA),
                            child: const Icon(
                              Icons.local_pharmacy_rounded,
                              color: Color(0xFFFF5E00),
                              size: 22,
                            ),
                          )
                        : Image.network(
                            image,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 40,
                              height: 40,
                              color: const Color(0xFFF3EFEA),
                              child: const Icon(
                                Icons.local_pharmacy_rounded,
                                color: Color(0xFFFF5E00),
                                size: 22,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2C2520),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'core_chat_online'.tr,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFA59A94),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: (_isLoadingMessages && _messages.isEmpty)
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5E00),
                        strokeWidth: 2.5,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E9E1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'core_chat_today'.tr,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF8A7F77),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        final message = _messages[index - 1];
                        if (message.type == _ChatMessageType.voice) {
                          return _VoiceOutgoingBubble(
                            time: message.time,
                            durationLabel: _formatClock(
                              message.duration ?? Duration.zero,
                            ),
                            isPlaying:
                                _playingPath != null &&
                                _playingPath == message.audioPath,
                            canPlay: message.audioPath != null,
                            isMine: message.isMine,
                            onPlay: () => _togglePlayback(message),
                          );
                        }

                        if (message.isMine) {
                          return _OutgoingTextBubble(
                            text: message.text ?? '',
                            time: message.time,
                          );
                        }

                        return _IncomingBubble(
                          text: message.text ?? '',
                          time: message.time,
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _isRecording
                    ? _RecordingBar(
                        elapsedLabel: _formatClock(_recordElapsed),
                        onCancel: _cancelRecording,
                        onSend: _stopAndSendRecording,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EFEA),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: Color(0xFF2C2520),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _textController,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => _sendText(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: const Color(0xFF2C2520),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'core_chat_type_message'.tr,
                                        hintStyle: GoogleFonts.outfit(
                                          color: const Color(0xFFA59A94),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _toggleRecording,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mic_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _sendText,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5E00),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF5E00,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
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
}

class _RecordingBar extends StatelessWidget {
  final String elapsedLabel;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _RecordingBar({
    required this.elapsedLabel,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onCancel,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFFF3E3E),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3E3E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'core_chat_recording'.tr,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  elapsedLabel,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onSend,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _IncomingBubble extends StatelessWidget {
  final String text;
  final String time;

  const _IncomingBubble({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 18),
            child: Text(
              time,
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutgoingTextBubble extends StatelessWidget {
  final String text;
  final String time;

  const _OutgoingTextBubble({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E00),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4, bottom: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  color: Color(0xFFFF5E00),
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceOutgoingBubble extends StatelessWidget {
  final String time;
  final String durationLabel;
  final bool isPlaying;
  final bool canPlay;
  final bool isMine;
  final VoidCallback onPlay;

  const _VoiceOutgoingBubble({
    required this.time,
    required this.durationLabel,
    required this.isPlaying,
    required this.canPlay,
    required this.onPlay,
    this.isMine = true,
  });

  @override
  Widget build(BuildContext context) {
    const heights = <double>[
      10,
      16,
      12,
      20,
      14,
      22,
      18,
      24,
      16,
      20,
      12,
      18,
      14,
      22,
      16,
      12,
    ];

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: canPlay ? onPlay : null,
            child: Container(
              width: 220,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isMine ? Colors.black : const Color(0xFF2C2520),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3A3A3A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFFFF5E00),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final h in heights) WaveformBar(height: h),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    durationLabel,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: isMine ? 0 : 4,
              end: isMine ? 4 : 0,
              bottom: 18,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFFFF5E00),
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformBar extends StatelessWidget {
  final double height;

  const WaveformBar({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.5,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
