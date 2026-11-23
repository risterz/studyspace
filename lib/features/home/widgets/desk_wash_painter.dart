import 'package:flutter/material.dart';

class DeskWashPainter extends CustomPainter {
  const DeskWashPainter({
    required this.washColor,
    required this.lineColor,
  });

  final Color washColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft pastel radial wash on the top-right corner matching Home mockup
    final washPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.45),
        radius: 1.05,
        colors: [
          washColor.withValues(alpha: 0.55),
          washColor.withValues(alpha: 0.18),
          washColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

    // Subtle minimal desk-lamp + stacked books vector accent on right
    final stroke = Paint()
      ..color = lineColor.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final baseY = 148.0;
    final rightX = size.width - 18;

    // Desk surface line
    canvas.drawLine(
      Offset(rightX - 132, baseY),
      Offset(rightX, baseY),
      stroke,
    );

    // Stacked books
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightX - 108, baseY - 12, 46, 12),
        const Radius.circular(3),
      ),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightX - 102, baseY - 22, 38, 10),
        const Radius.circular(3),
      ),
      stroke,
    );

    // Minimal study lamp
    canvas.drawLine(
      Offset(rightX - 38, baseY),
      Offset(rightX - 18, baseY),
      stroke,
    );
    canvas.drawLine(
      Offset(rightX - 28, baseY),
      Offset(rightX - 24, baseY - 36),
      stroke,
    );
    canvas.drawLine(
      Offset(rightX - 24, baseY - 36),
      Offset(rightX - 48, baseY - 48),
      stroke,
    );
    final lampShade = Path()
      ..moveTo(rightX - 58, baseY - 40)
      ..lineTo(rightX - 42, baseY - 54)
      ..lineTo(rightX - 36, baseY - 44)
      ..close();
    canvas.drawPath(lampShade, stroke);
  }

  @override
  bool shouldRepaint(covariant DeskWashPainter oldDelegate) {
    return oldDelegate.washColor != washColor ||
        oldDelegate.lineColor != lineColor;
  }
}
