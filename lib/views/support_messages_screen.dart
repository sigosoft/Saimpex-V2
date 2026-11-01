import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../core/network/api_exception.dart';
import '../models/support_repository.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';

import '../utils/app_fonts.dart';
/// Messages from SAIMPEX support, one thread per order (API §6.37).
class SupportMessagesScreen extends StatefulWidget {
  const SupportMessagesScreen({super.key});

  @override
  State<SupportMessagesScreen> createState() => _SupportMessagesScreenState();
}

class _SupportMessagesScreenState extends State<SupportMessagesScreen> {
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await SupportRepository.instance.threads(
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() => _threads = result.threads);
    } on ApiException catch (error) {
      if (mounted) showAppToast(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map<String, dynamic> thread) async {
    final orderId = int.tryParse('${thread['order_id']}');
    if (orderId == null) return;
    await Get.to(
      () => SupportThreadScreen(
        orderId: orderId,
        orderCode: '${thread['order_code'] ?? ''}',
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: _supportAppBar(context, 'orders_support_messages_title'.tr),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : RefreshIndicator(
              color: AppColors.primaryOrange,
              onRefresh: _load,
              child: _threads.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            'orders_support_messages_empty'.tr,
                            style: AppFonts.outfit(
                              color: const Color(0xFF7A6A60),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _threads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final thread = _threads[index];
                        final unread =
                            int.tryParse('${thread['unread'] ?? 0}') ?? 0;
                        final last = thread['last_message'] is Map
                            ? '${(thread['last_message'] as Map)['text'] ?? ''}'
                            : '';
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _open(thread),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFEAD8C9),
                              ),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xFFFFF0E6),
                                  child: Icon(
                                    Icons.support_agent_rounded,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'orders_support_order_label'.trParams({
                                          'code': '${thread['order_code']}',
                                        }),
                                        style: AppFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        last,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.outfit(
                                          color: const Color(0xFF7A6A60),
                                          fontSize: 12.5,
                                          fontWeight: unread > 0
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (unread > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unread',
                                      style: AppFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

/// One order's conversation with SAIMPEX support, with a reply box.
class SupportThreadScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;

  const SupportThreadScreen({
    super.key,
    required this.orderId,
    this.orderCode = '',
  });

  @override
  State<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends State<SupportThreadScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final messages = await SupportRepository.instance.messages(
        widget.orderId,
        apiLanguageCode(),
      );
      if (!mounted) return;
      setState(() => _messages = messages);
      _toBottom();
    } on ApiException catch (error) {
      if (mounted) showAppToast(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await SupportRepository.instance.reply(
        widget.orderId,
        text,
        apiLanguageCode(),
      );
      if (!mounted) return;
      _controller.clear();
      setState(
        () => _messages.add(message ?? {'from': 'customer', 'text': text}),
      );
      _toBottom();
    } on ApiException catch (error) {
      if (mounted) showAppToast(error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.orderCode.isEmpty
        ? 'orders_support_messages_title'.tr
        : 'orders_support_order_label'.trParams({'code': widget.orderCode});
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: _supportAppBar(context, title),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final mine = message['from'] == 'customer';
                      return Align(
                        alignment: mine
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppColors.primaryOrange
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!mine)
                                Text(
                                  'orders_support_from_saimpex'.tr,
                                  style: AppFonts.outfit(
                                    color: AppColors.primaryOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              Text(
                                '${message['text'] ?? ''}',
                                style: AppFonts.outfit(
                                  color: mine
                                      ? Colors.white
                                      : const Color(0xFF2C2520),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: AppFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'orders_support_reply_hint'.tr,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                    ),
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PreferredSizeWidget _supportAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: const Color(0xFFFAF6F0),
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    leading: Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: AppBackButton(onTap: () => Navigator.pop(context)),
    ),
    leadingWidth: 60,
    centerTitle: true,
    title: Text(
      title,
      style: AppFonts.outfit(
        color: const Color(0xFF2C2520),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
