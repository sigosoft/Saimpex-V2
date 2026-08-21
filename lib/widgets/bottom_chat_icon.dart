import 'package:flutter/material.dart';

/// Outlined chat bubble with three dots — matches bottom-nav Chat design.
class BottomChatIcon extends StatelessWidget {
  final double size;
  final Color color;

  const BottomChatIcon({
    super.key,
    this.size = 22,
    this.color = const Color(0xFFFF5E00),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ChatBubblePainter(color: color),
      ),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  final Color color;

  _ChatBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Bubble body (rounded rect leaving room for tail)
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.04, w * 0.84, h * 0.72),
      Radius.circular(w * 0.28),
    );
    canvas.drawRRect(bubble, stroke);

    // Tail pointing down-left
    final tail = Path()
      ..moveTo(w * 0.28, h * 0.68)
      ..quadraticBezierTo(w * 0.22, h * 0.82, w * 0.18, h * 0.92)
      ..quadraticBezierTo(w * 0.32, h * 0.84, w * 0.42, h * 0.72);
    canvas.drawPath(tail, stroke);

    // Three dots
    final dotR = w * 0.055;
    final cy = h * 0.40;
    final spacing = w * 0.18;
    final startX = w * 0.5 - spacing;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(startX + spacing * i, cy), dotR, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatBubblePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
