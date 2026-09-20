import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

class ChatBotAiChatScreen extends StatefulWidget {
  final String languageCode;

  const ChatBotAiChatScreen({
    super.key,
    this.languageCode = 'EN',
  });

  @override
  State<ChatBotAiChatScreen> createState() => _ChatBotAiChatScreenState();
}

class _ChatBotAiChatScreenState extends State<ChatBotAiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatItem> _messages = [];

  late String _languageCode;
  Timer? _idleTimer;
  static const Duration _idleTimeout = Duration(minutes: 2);

  static const _languages = [
    _LangOption(code: 'EN', label: 'English'),
    _LangOption(code: 'FR', label: 'Français'),
    _LangOption(code: 'AR', label: 'العربية'),
  ];

  bool get _hasChat => _messages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode;
    _resetIdleTimer();
  }

  String get _languageLabel => _languages
      .firstWhere(
        (l) => l.code == _languageCode,
        orElse: () => _languages.first,
      )
      .label;

  String get _greetingTitle {
    switch (_languageCode) {
      case 'FR':
        return 'Salut ! 👋';
      case 'AR':
        return 'مرحباً! 👋';
      default:
        return 'Hey there! 👋';
    }
  }

  String get _greetingSubtitle {
    switch (_languageCode) {
      case 'FR':
        return 'Je suis Saimpex. Comment puis-je vous aider aujourd\'hui ?';
      case 'AR':
        return 'أنا سيمبكس. كيف يمكنني مساعدتك اليوم؟';
      default:
        return "I'm Saimpex. How can I help you today?";
    }
  }

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

  void _sendMessage([String? preset, IconData? icon]) {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty) return;

    _resetIdleTimer();
    final now = DateTime.now();

    setState(() {
      _messages.add(
        _ChatItem.text(
          text: text,
          isUser: true,
          time: now,
          icon: icon ?? _iconForUserText(text),
        ),
      );
      _messageController.clear();
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _addBotReply(text);
    });
  }

  IconData? _iconForUserText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('track')) return Icons.delivery_dining_rounded;
    if (lower.contains('cancel')) return Icons.cancel_outlined;
    if (lower.contains('offer')) return Icons.percent_rounded;
    return null;
  }

  void _addBotReply(String userText) {
    final lower = userText.toLowerCase();
    final now = DateTime.now();

    if (lower.contains('track') || lower.contains('where is my order')) {
      if (lower.contains('where')) {
        setState(() {
          _messages.add(
            _ChatItem.text(
              text: 'Your order is arriving in 12 minutes!',
              isUser: false,
              time: now,
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            _ChatItem.text(
              text: 'Sure! Let me check that for you.',
              isUser: false,
              time: now,
            ),
          );
          _messages.add(_ChatItem.orderCard(time: now));
        });
      }
    } else if (lower.contains('cancel')) {
      setState(() {
        _messages.add(
          _ChatItem.text(
            text:
                'I can help cancel an order. Please share your order ID to continue.',
            isUser: false,
            time: now,
          ),
        );
      });
    } else if (lower.contains('offer')) {
      setState(() {
        _messages.add(
          _ChatItem.text(
            text:
                'Here are today\'s top offers near you. Want grocery, pharmacy, or water deals?',
            isUser: false,
            time: now,
          ),
        );
      });
    } else {
      String reply;
      switch (_languageCode) {
        case 'FR':
          reply =
              'Merci ! Je suis là pour vous aider avec les commandes et livraisons.';
          break;
        case 'AR':
          reply = 'شكراً! أنا هنا للمساعدة في الطلبات والتوصيل.';
          break;
        default:
          reply =
              'Thanks! I\'m here to help with orders, deliveries, and offers.';
      }
      setState(() {
        _messages.add(
          _ChatItem.text(text: reply, isUser: false, time: now),
        );
      });
    }
    _scrollToBottom();
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
              ..._languages.map((lang) {
                final selected = lang.code == _languageCode;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    lang.label,
                    style: GoogleFonts.outfit(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
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
          ),
        );
      },
    );

    if (selected != null && selected != _languageCode) {
      setState(() => _languageCode = selected);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
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
            colors: [
              Color(0xFFFFF4EE),
              Color(0xFFFAF6F0),
              Color(0xFFFFE8DC),
            ],
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
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryOrange.withOpacity(0.45),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primaryOrange,
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
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
                        color: AppColors.primaryOrange.withOpacity(0.45),
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
                          _languageLabel,
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
            _greetingTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF111111),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _greetingSubtitle,
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
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final item = _messages[index];
        if (item.type == _ChatItemType.orderCard) {
          return _OrderTrackingCard(timeLabel: _formatTime(item.time));
        }
        return _MessageBubble(
          message: item,
          timeLabel: _formatTime(item.time),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        label: 'Track my order',
        icon: Icons.delivery_dining_rounded,
        onTap: () => _sendMessage(
          'Track my order',
          Icons.delivery_dining_rounded,
        ),
      ),
      _QuickAction(
        label: 'Cancel order',
        icon: Icons.cancel_outlined,
        onTap: () => _sendMessage('Cancel order', Icons.cancel_outlined),
      ),
      _QuickAction(
        label: 'Offers',
        icon: Icons.percent_rounded,
        onTap: () => _sendMessage('Offers', Icons.percent_rounded),
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
              if (i > 0) const SizedBox(width: 8),
              _QuickActionChip(action: actions[i]),
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
                  Icon(Icons.add, color: Colors.grey.shade500, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) => _resetIdleTimer(),
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.35),
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

enum _ChatItemType { text, orderCard }

class _ChatItem {
  final _ChatItemType type;
  final String text;
  final bool isUser;
  final DateTime time;
  final IconData? icon;

  const _ChatItem._({
    required this.type,
    required this.text,
    required this.isUser,
    required this.time,
    this.icon,
  });

  factory _ChatItem.text({
    required String text,
    required bool isUser,
    required DateTime time,
    IconData? icon,
  }) {
    return _ChatItem._(
      type: _ChatItemType.text,
      text: text,
      isUser: isUser,
      time: time,
      icon: icon,
    );
  }

  factory _ChatItem.orderCard({required DateTime time}) {
    return _ChatItem._(
      type: _ChatItemType.orderCard,
      text: '',
      isUser: false,
      time: time,
    );
  }
}

class _LangOption {
  final String code;
  final String label;
  const _LangOption({required this.code, required this.label});
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionChip extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryOrange.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: AppColors.primaryOrange, size: 16),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1A1A1A),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
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

  const _MessageBubble({
    required this.message,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFDE8E1)
                    : const Color(0xFFFFF8F3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser && message.icon != null) ...[
                    Icon(
                      message.icon,
                      color: AppColors.primaryOrange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      message.text,
                      style: GoogleFonts.outfit(
                        color: isUser
                            ? const Color(0xFFE85A1A)
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
        ),
      ),
    );
  }
}

class _OrderTrackingCard extends StatelessWidget {
  final String timeLabel;

  const _OrderTrackingCard({required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TrackStep(
        label: 'Your order has been received',
        icon: Icons.check_rounded,
        done: true,
      ),
      _TrackStep(
        label: 'The restaurant is preparing your food',
        icon: Icons.soup_kitchen_outlined,
        done: true,
      ),
      _TrackStep(
        label: 'Your order has been picked up for delivery',
        icon: Icons.delivery_dining_rounded,
        done: true,
      ),
      _TrackStep(
        label: 'Your order has been delivered',
        icon: Icons.check_circle_outline,
        done: false,
      ),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: MediaQuery.sizeOf(context).width * 0.86,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'lib/assets/images/Fish.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFFFFE0CC),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Al Fantasia',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#22789000',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF7A6A60),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '22 OCT 2025,\n10:00 AM',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF7A6A60),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0E6DE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    _TimelineRow(
                      step: steps[i],
                      isLast: i == steps.length - 1,
                    ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFE6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arriving 12 mins',
                          style: GoogleFonts.outfit(
                            color: AppColors.primaryOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your order has been received',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF7A6A60),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              child: Text(
                timeLabel,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF9A9088),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackStep {
  final String label;
  final IconData icon;
  final bool done;

  const _TrackStep({
    required this.label,
    required this.icon,
    required this.done,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TrackStep step;
  final bool isLast;

  const _TimelineRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final active = step.done;
    final color =
        active ? AppColors.primaryOrange : const Color(0xFFD0C6BE);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primaryOrange
                        : const Color(0xFFECE4DD),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, color: Colors.white, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: color.withOpacity(0.55),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
              child: Text(
                step.label,
                style: GoogleFonts.outfit(
                  color: active
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFF9A9088),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
