import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Textured paint-brushstroke divider used at the bottom of the login
/// screen, separating the brand-colored header from the white footer.
class PaintSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);

    // Dynamic jagged brushstroke wave
    for (double x = 0; x <= size.width; x += 14) {
      final progress = x / size.width;
      final baseY = size.height * 0.55 - (progress * 18);
      final jitter = (math.sin(x * 0.12) * 5.0) + (math.cos(x * 0.28) * 3.0);
      path.lineTo(x, (baseY + jitter).clamp(0.0, size.height));
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Subtle paint fleck splatters
    final splatterPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 22; i++) {
      final sx = (i / 22) * size.width + random.nextDouble() * 12;
      final sy = size.height * 0.35 - (random.nextDouble() * 16);
      final radius = 1.0 + random.nextDouble() * 2.2;
      canvas.drawCircle(Offset(sx, sy), radius, splatterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
