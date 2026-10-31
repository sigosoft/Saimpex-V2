import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'chat_screen.dart';
import '../constants/text_styles.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_store.dart';
import '../models/chat_repository.dart';
import '../navigation/bottom_nav_router.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/home_background_blend.dart';

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurant;
  final bool showBottomNav;

  const MessagesScreen({super.key, this.restaurant, this.showBottomNav = true});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int activeChipIndex = 0;
  final List<String> chips = ['All', 'Food', 'Grocery', 'Pharmacy'];
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = false;

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

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  /// Asks first, then deletes the conversation on the server
  /// (chat/deleteConversation) and only then removes it from the list.
  Future<void> _deleteChat(Map<String, dynamic> chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('core_messages_delete_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('core_messages_keep'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('core_addresses_delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _getChatRepo().deleteConversation(
        conversationId: chat['id'],
        language: currentApiLanguage(),
      );
      if (!mounted) return;
      setState(() => _chats.removeWhere((c) => c['id'] == chat['id']));
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final repo = _getChatRepo();
      final lang = currentApiLanguage();
      final list = await repo.getAllConversations(language: lang);

      final List<Map<String, dynamic>> parsedChats = [];
      for (final conv in list) {
        final convId = conv['id']?.toString() ?? '';
        final vendorId = conv['vendor_id']?.toString();
        final vendor = (conv['vendor'] is Map)
            ? Map<String, dynamic>.from(conv['vendor'] as Map)
            : (conv['restaurant'] is Map)
            ? Map<String, dynamic>.from(conv['restaurant'] as Map)
            : (conv['store'] is Map)
            ? Map<String, dynamic>.from(conv['store'] as Map)
            : conv;

        final title =
            vendor['name']?.toString() ??
            vendor['title']?.toString() ??
            vendor['name_en']?.toString() ??
            vendor['name_ar']?.toString() ??
            (vendorId != null
                ? 'core_messages_vendor_id'.trParams({'id': vendorId})
                : 'core_messages_vendor'.tr);

        final rawImg =
            vendor['image']?.toString() ??
            vendor['logo']?.toString() ??
            vendor['profile_image']?.toString() ??
            vendor['banner']?.toString();
        final imgUrl = (rawImg != null && rawImg.isNotEmpty)
            ? (ApiConstants.mediaUrl(rawImg) ?? rawImg)
            : 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=150&auto=format&fit=crop';

        final lastMsg = (conv['last_message'] is Map)
            ? Map<String, dynamic>.from(conv['last_message'] as Map)
            : (conv['latest_message'] is Map)
            ? Map<String, dynamic>.from(conv['latest_message'] as Map)
            : (conv['messages'] is List &&
                  (conv['messages'] as List).isNotEmpty)
            ? Map<String, dynamic>.from((conv['messages'] as List).last as Map)
            : null;

        final subtitle =
            lastMsg?['message']?.toString() ??
            (lastMsg?['message_type'] == 'voice'
                ? 'core_messages_voice_note'.tr
                : 'core_messages_conversation_started'.tr);

        final timeStr = _formatTimestamp(
          lastMsg?['created_at'] ?? conv['updated_at'] ?? conv['created_at'],
        );

        final unreadCount =
            int.tryParse(
              '${conv['unread_count'] ?? conv['unreadCount'] ?? 0}',
            ) ??
            0;

        final rawCat =
            (vendor['category'] ?? vendor['type'] ?? conv['category'] ?? '')
                .toString()
                .toLowerCase();

        String category = 'Food';
        if (rawCat.contains('grocery') ||
            rawCat.contains('market') ||
            rawCat.contains('store')) {
          category = 'Grocery';
        } else if (rawCat.contains('pharmacy')) {
          category = 'Pharmacy';
        } else if (rawCat.contains('food') || rawCat.contains('restaurant')) {
          category = 'Food';
        }

        parsedChats.add({
          'id': convId,
          'title': title,
          'subtitle': subtitle,
          'image': imgUrl,
          'time': timeStr,
          'isOnline': vendor['is_online'] == true || vendor['is_online'] == 1,
          'unreadCount': unreadCount,
          'category': category,
          'restaurantData': {
            'id': vendorId ?? convId,
            'vendor_id': vendorId ?? vendor['id'] ?? convId,
            'conversation_id': convId,
            'title': title,
            'image': imgUrl,
            'raw': conv,
          },
        });
      }

      if (!mounted) return;
      setState(() {
        _chats = parsedChats;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _chats = <Map<String, dynamic>>[];
    _loadConversations();
  }

  List<Map<String, dynamic>> get _filteredChats {
    if (activeChipIndex == 0) return _chats;
    final category = chips[activeChipIndex];
    return _chats.where((c) => c['category'] == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chats = _filteredChats;

    return HomeBackgroundBlend(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: widget.showBottomNav
                        ? AppBackButton(onTap: () => Navigator.pop(context))
                        : const SizedBox(width: 38),
                  ),
                  Text(
                    'core_messages_title'.tr,
                    style: AppTextStyles.heading(),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final isSelected = activeChipIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => activeChipIndex = index);
                        },
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(end: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF5E00)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF5E00)
                                  : const Color(0xFFEAD8C9),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            // Internal value stays English (used to filter);
                            // only the label is translated.
                            'core_messages_chip_${chips[index].toLowerCase()}'
                                .tr,
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2C2520),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: (_isLoading && _chats.isEmpty)
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5E00),
                            strokeWidth: 2.5,
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFFF5E00),
                          onRefresh: _loadConversations,
                          child: chats.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.4,
                                      child: Center(
                                        child: Text(
                                          'core_messages_empty'.tr,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFA59A94),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  itemCount: chats.length,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    110,
                                  ),
                                  itemBuilder: (context, index) {
                                    final chat = chats[index];
                                    return _MessageCard(
                                      chat: chat,
                                      onTap: () async {
                                        await Get.to(
                                          () => ChatScreen(
                                            restaurant:
                                                Map<String, dynamic>.from(
                                                  chat['restaurantData'] as Map,
                                                ),
                                          ),
                                        );
                                        _loadConversations();
                                      },
                                      onDelete: () => _deleteChat(chat),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
            if (widget.showBottomNav)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNavBar(
                  selectedIndex: 1,
                  onTap: BottomNavRouter.go,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Map<String, dynamic> chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.chat,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unread = (chat['unreadCount'] as int?) ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipOval(
                  child: Image.network(
                    chat['image'] as String,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFF3EFEA),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFFFF5E00),
                      ),
                    ),
                  ),
                ),
                if (chat['isOnline'] == true)
                  PositionedDirectional(
                    bottom: 1,
                    end: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B25C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['title'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title(),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    chat['subtitle'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle(
                      color: const Color(0xFF8A7F77),
                    ).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(start: 8, bottom: 4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF5E00),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (unread > 0)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5E00),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$unread',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFFA59A94),
                    size: 16,
                  ),
                const SizedBox(height: 4),
                Text(
                  chat['time'] as String,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
