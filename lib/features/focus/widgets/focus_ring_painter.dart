import 'dart:math' as math;

import 'package:flutter/material.dart';

class FocusRingPainter extends CustomPainter {
  const FocusRingPainter({
    required this.progress,
    required this.ringColor,
    required this.progressArcColor,
    required this.glowColor,
    required this.centerSurface,
  });

  final double progress;
  final Color ringColor;
  final Color progressArcColor;
  final Color glowColor;
  final Color centerSurface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 18;

    // Soft outer pastel glow matching Focus mockup
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.34),
          glowColor.withValues(alpha: 0.14),
          glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.58, 0.78, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 24));
    canvas.drawCircle(center, radius + 24, glowPaint);

    // Inner clean circle
    final fillPaint = Paint()..color = centerSurface;
    canvas.drawCircle(center, radius - 4, fillPaint);

    // Base ring track
    final trackPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active mint progress arc starting at 12 o'clock
    final sweep = (progress <= 0 ? 0.08 : progress.clamp(0.02, 1.0)) * 2 * math.pi;
    final arcPaint = Paint()
      ..color = progressArcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FocusRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.progressArcColor != progressArcColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.centerSurface != centerSurface;
  }
}
