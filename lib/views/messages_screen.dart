import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'chat_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../navigation/bottom_nav_router.dart';

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic>? restaurant;
  final bool showBottomNav;

  const MessagesScreen({
    super.key,
    this.restaurant,
    this.showBottomNav = true,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int activeChipIndex = 0;
  final List<String> chips = ['All', 'Food', 'Grocery', 'Pharmacy'];
  late List<Map<String, dynamic>> _chats;

  @override
  void initState() {
    super.initState();
    final incoming = widget.restaurant;
    _chats = [
      {
        'id': 'c1',
        'title': incoming?['title'] ?? 'Al Fantasia Restaurant',
        'subtitle': "Sure! We're adding the finest Moroccan ....",
        'image': incoming?['image'] ??
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=150&auto=format&fit=crop',
        'time': '12:45 PM',
        'isOnline': true,
        'unreadCount': 1,
        'category': 'Food',
        'restaurantData': incoming ??
            {
              'title': 'Al Fantasia Restaurant',
              'image':
                  'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=150&auto=format&fit=crop',
            },
      },
      {
        'id': 'c2',
        'title': 'Salam Supermarket',
        'subtitle': 'Etiam cursus velit non eros eleifenddic',
        'image':
            'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&auto=format&fit=crop',
        'time': 'Just now',
        'isOnline': false,
        'unreadCount': 0,
        'category': 'Grocery',
        'restaurantData': {
          'title': 'Salam Supermarket',
          'image':
              'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&auto=format&fit=crop',
        },
      },
      {
        'id': 'c3',
        'title': 'Pharmacy Nasr',
        'subtitle': 'Your quotation is ready for review.',
        'image':
            'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=150&auto=format&fit=crop',
        'time': '10:20 AM',
        'isOnline': true,
        'unreadCount': 2,
        'category': 'Pharmacy',
        'restaurantData': {
          'title': 'Pharmacy Nasr',
          'image':
              'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=150&auto=format&fit=crop',
        },
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredChats {
    if (activeChipIndex == 0) return _chats;
    final category = chips[activeChipIndex];
    return _chats.where((c) => c['category'] == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chats = _filteredChats;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFAF6F0),
            Color(0xFFFFEEE5),
            Color(0xFFFFDDCF),
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
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
                    alignment: Alignment.centerLeft,
                    child: widget.showBottomNav
                        ? CustomBackButton(
                            onTap: () => Navigator.pop(context),
                          )
                        : const SizedBox(width: 38),
                  ),
                  Text(
                    'Messages',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
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
                          margin: const EdgeInsets.only(right: 10),
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
                            chips[index],
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
                  child: chats.isEmpty
                      ? Center(
                          child: Text(
                            'No conversations yet',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFA59A94),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: chats.length,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            return _MessageCard(
                              chat: chat,
                              onTap: () {
                                Get.to(
                                  () => ChatScreen(
                                    restaurant: Map<String, dynamic>.from(
                                      chat['restaurantData'] as Map,
                                    ),
                                  ),
                                );
                              },
                              onDelete: () {
                                setState(() {
                                  _chats.removeWhere(
                                    (c) => c['id'] == chat['id'],
                                  );
                                });
                              },
                            );
                          },
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
                    errorBuilder: (_, __, ___) => Container(
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
                  Positioned(
                    bottom: 1,
                    right: 1,
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
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    chat['subtitle'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8A7F77),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
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
                    padding: EdgeInsets.only(left: 8, bottom: 4),
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

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CustomBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD4B8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFFFF5E00),
          size: 15,
        ),
      ),
    );
  }
}
