import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


/// Shows the AI chatbot welcome / language bottom sheet.
/// Returns the selected language code (`EN`, `FR`, `AR`) or `null` if closed.
Future<String?> showChatBotWelcomeSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (context) => const ChatBotWelcomeSheet(),
  );
}

class ChatBotWelcomeSheet extends StatefulWidget {
  const ChatBotWelcomeSheet({super.key});

  @override
  State<ChatBotWelcomeSheet> createState() => _ChatBotWelcomeSheetState();
}

class _ChatBotWelcomeSheetState extends State<ChatBotWelcomeSheet> {
  int _selectedIndex = 0;

  static const _languages = [
    _LangOption(code: 'EN', label: 'English'),
    _LangOption(code: 'FR', label: 'Français'),
    _LangOption(code: 'AR', label: 'العربية'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating close button above the sheet
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              color: Color(0xFFE53935),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // White modal body
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            child: Stack(
              children: [
                // Soft peach radial glow behind robot
                Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 260,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFDCC8).withOpacity(0.95),
                            const Color(0xFFFFE8DA).withOpacity(0.55),
                            Colors.white.withOpacity(0),
                          ],
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 22 + bottomPad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Robot character (full body for modal)
                      Image.asset(
                        'lib/assets/images/chatbot_screen.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'lib/assets/images/chatbot.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Hey there! 👋',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF111111),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "I'm Saimpex. How can I help you today?",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2A2A2A),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 28),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Let's chat in your language",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF111111),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Language chips
                      Row(
                        children: List.generate(_languages.length, (index) {
                          final lang = _languages[index];
                          final selected = _selectedIndex == index;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < _languages.length - 1 ? 8 : 0,
                              ),
                              child: _LanguageChip(
                                code: lang.code,
                                label: lang.label,
                                selected: selected,
                                onTap: () {
                                  setState(() => _selectedIndex = index);
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Continue button — orange → yellow gradient
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pop(_languages[_selectedIndex].code);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF5E00),
                                Color(0xFFFFAE00),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5E00).withOpacity(0.38),
                                blurRadius: 16,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Continue',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LangOption {
  final String code;
  final String label;

  const _LangOption({required this.code, required this.label});
}

class _LanguageChip extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3EC) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF7043)
                : const Color(0xFFE6E0DB),
            width: selected ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFF5E00)
                    : const Color(0xFFBDBDBD),
                shape: BoxShape.circle,
              ),
              child: Text(
                code,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            if (selected)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              )
            else
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC8C2BC),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
