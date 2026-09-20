import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/colors.dart';
import '../chatbot_ai_chat_screen.dart';
import 'chatbot_welcome_sheet.dart';

class ChatBotHead extends StatefulWidget {
  final Duration idleTimeoutDuration;

  const ChatBotHead({
    super.key,
    this.idleTimeoutDuration = const Duration(seconds: 5),
  });

  @override
  State<ChatBotHead> createState() => _ChatBotHeadState();
}

class _ChatBotHeadState extends State<ChatBotHead>
    with TickerProviderStateMixin {
  static const double _expandedSize = 55;
  static const double _shrunkSize = 38;
  static const double _dragThreshold = 8;

  /// App bottom nav stack (~109) + SafeArea padding gap (10) + margin.
  static const double _navBarClearance = 130;

  /// Space below the circle for the "How can I help you?" bubble.
  static const double _bubbleClearance = 48;

  bool _isShrunk = false;
  bool _hasPosition = false;
  bool _didDrag = false;

  /// Screen position of the avatar circle center — stays fixed on shrink/expand.
  Offset _center = Offset.zero;
  Offset _panStartGlobal = Offset.zero;

  Timer? _idleTimer;

  late AnimationController _sizeController;
  late AnimationController _bubbleController;
  late AnimationController _floatController;
  late AnimationController _glowController;

  late Animation<double> _sizeAnimation;
  late Animation<double> _bubbleAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _sizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sizeAnimation = Tween<double>(
      begin: _expandedSize,
      end: _shrunkSize,
    ).animate(
      CurvedAnimation(parent: _sizeController, curve: Curves.easeInOutBack),
    );

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bubbleAnimation = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOut,
    );
    _bubbleController.forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 2, end: 12).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startIdleTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPosition) {
      final screen = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context);
      // Bottom-right, fully above bottom nav + help bubble.
      // Extra left inset so the wide bubble isn't clipped on the right.
      _center = Offset(
        screen.width - 72 - (_expandedSize / 2),
        screen.height -
            padding.bottom -
            _navBarClearance -
            _bubbleClearance -
            (_expandedSize / 2),
      );
      _hasPosition = true;
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleTimeoutDuration, _shrink);
  }

  void _shrink() {
    if (!mounted || _isShrunk) return;
    setState(() {
      _isShrunk = true;
    });
    _bubbleController.reverse();
    _sizeController.forward();
    _floatController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  void _restore() {
    if (!mounted) return;
    setState(() {
      _isShrunk = false;
    });
    _sizeController.reverse();
    _bubbleController.forward();
    _floatController.stop();
    _glowController.stop();
    _startIdleTimer();
  }

  void _clampCenter(Size screen, EdgeInsets padding, double headSize) {
    final half = headSize / 2;
    // Keep room on the right for the help bubble (~half bubble width)
    const rightBubbleInset = 56.0;
    final minX = half + 8;
    final maxX = screen.width - half - 8 - rightBubbleInset;
    final minY = padding.top + half + 8;
    // Keep circle + bubble above the floating bottom nav
    final maxY = screen.height -
        padding.bottom -
        _navBarClearance -
        _bubbleClearance -
        half -
        8;

    _center = Offset(
      _center.dx.clamp(minX, math.max(minX, maxX)),
      _center.dy.clamp(minY, math.max(minY, maxY)),
    );
  }

  Future<void> _onTap() async {
    HapticFeedback.lightImpact();
    _idleTimer?.cancel();

    if (_isShrunk) {
      _restore();
      return;
    }

    if (!mounted) return;

    // Welcome / language bottom sheet first
    final languageCode = await showChatBotWelcomeSheet(context);
    if (!mounted) return;

    if (languageCode == null) {
      _restore();
      return;
    }

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatBotAiChatScreen(languageCode: languageCode),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.fastOutSlowIn;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    if (result == 'timeout') {
      _shrink();
    } else {
      _restore();
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _sizeController.dispose();
    _bubbleController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _sizeController,
        _bubbleController,
        _floatController,
        _glowController,
      ]),
      builder: (context, child) {
        final size = _sizeAnimation.value;
        final floatOffset = _isShrunk ? _floatAnimation.value : 0.0;
        final glowRadius = _isShrunk ? _glowAnimation.value : 0.0;

        // Keep circle center fixed while size / bubble change
        final left = _center.dx - (size / 2);
        final top = _center.dy - (size / 2) + floatOffset;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _didDrag = false;
                  _panStartGlobal = details.globalPosition;
                  _idleTimer?.cancel();
                  _floatController.stop();
                },
                onPanUpdate: (details) {
                  final distance =
                      (details.globalPosition - _panStartGlobal).distance;
                  if (distance > _dragThreshold) {
                    _didDrag = true;
                  }
                  setState(() {
                    _center += details.delta;
                    _clampCenter(screen, padding, size);
                  });
                },
                onPanEnd: (_) {
                  if (_didDrag) {
                    if (_isShrunk) {
                      _floatController.repeat(reverse: true);
                    }
                    _startIdleTimer();
                  } else {
                    _onTap();
                  }
                },
                child: RepaintBoundary(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryOrange.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                              if (_isShrunk)
                                BoxShadow(
                                  color: AppColors.primaryOrange
                                      .withOpacity(0.6),
                                  blurRadius: glowRadius,
                                  spreadRadius: glowRadius / 2,
                                ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(size * 0.12),
                            child: Image.asset(
                              'lib/assets/images/chatbot.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.white,
                                  size: size * 0.5,
                                );
                              },
                            ),
                          ),
                        ),
                        // Bubble hangs below without moving the circle
                        if (_bubbleAnimation.value > 0)
                          Positioned(
                            top: size + 8,
                            left: size / 2,
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, 0),
                              child: Opacity(
                                opacity: _bubbleAnimation.value,
                                child: Transform.scale(
                                  scale: _bubbleAnimation.value,
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryOrange
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'How can I help you?',
                                      style: GoogleFonts.rubik(
                                        color: Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
