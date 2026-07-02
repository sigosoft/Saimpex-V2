import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const MessagesScreen({Key? key, required this.restaurant}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int activeChipIndex = 0;
  final List<String> chips = ['All', 'Food', 'Grocery', 'Pharmacy'];

  @override
  Widget build(BuildContext context) {
    // Generate chat list item data using dynamic details passed down and static ones
    final List<Map<String, dynamic>> chats = [
      {
        'id': 'c1',
        'title': widget.restaurant['title'] ?? 'Al Fantasia Restaurant',
        'subtitle': 'Sure! We\'re adding the finest Moroccan .....',
        'image':
            widget.restaurant['image'] ??
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=150&auto=format&fit=crop',
        'time': '12:45 PM',
        'isOnline': true,
        'unreadCount': 1,
        'restaurantData': widget.restaurant,
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
        'restaurantData': {
          'title': 'Salam Supermarket',
          'image':
              'https://images.unsplash.com/photo-1542838132-92c53300491e?w=150&auto=format&fit=crop',
        },
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const CustomBackButton(),
                Expanded(
                  child: Center(
                    child: Text(
                      'Messages',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 38), // spacer to center the title
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Horizontal Selection Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final chip = chips[index];
                final isSelected = activeChipIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      activeChipIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF5E00)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFEAD8C9),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      chip,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF2C2520),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 2. Chat Conversation Cards List
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final chat = chats[index];

                return GestureDetector(
                  onTap: () {
                    Get.to(
                      () => ChatScreen(restaurant: chat['restaurantData']),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFEAD8C9).withOpacity(0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar block with green online dot indicator
                        Stack(
                          children: [
                            ClipOval(
                              child: Image.network(
                                chat['image']!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (chat['isOnline'] == true)
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B25C),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Middle title/subtitle section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat['title']!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF2C2520),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat['subtitle']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7A6A60),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right side metadata column (Trash icon top-right, unread/tick middle-right, time bottom-right)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Deleting chat with ${chat['title']}...',
                                      style: GoogleFonts.outfit(),
                                    ),
                                    backgroundColor: const Color(0xFFFF5E00),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFFF5E00),
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (chat['unreadCount'] > 0)
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5E00),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  chat['unreadCount'].toString(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.done_all_rounded,
                                color: Color(0xFFA59A94),
                                size: 14,
                              ),
                            const SizedBox(height: 6),
                            Text(
                              chat['time']!,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA59A94),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CustomBackButton({Key? key, this.onTap}) : super(key: key);

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
