import 'package:material_ui/material_ui.dart';

/// Decorative background watermarks (clock dial, calendar check, flight arc)
/// used behind the dashboard content. Pure painting, no state.
class AttendanceWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B9BBF).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // 1. Clock dial watermark in top-right corner
    final clockCenter = Offset(size.width * 0.88, size.height * 0.16);
    canvas.drawCircle(clockCenter, 55, paint);
    canvas.drawCircle(clockCenter, 44, paint);
    // Clock hands
    canvas.drawLine(clockCenter, Offset(clockCenter.dx, clockCenter.dy - 26), paint);
    canvas.drawLine(clockCenter, Offset(clockCenter.dx + 18, clockCenter.dy + 8), paint);

    // 2. Attendance Checkmark Calendar watermark in mid-left
    final calRect = Rect.fromLTWH(size.width * 0.04, size.height * 0.42, 60, 50);
    final rrect = RRect.fromRectAndRadius(calRect, const Radius.circular(8));
    canvas.drawRRect(rrect, paint);
    canvas.drawLine(
      Offset(calRect.left, calRect.top + 14),
      Offset(calRect.right, calRect.top + 14),
      paint,
    );
    // Small check mark inside
    final checkPath = Path()
      ..moveTo(calRect.left + 18, calRect.top + 30)
      ..lineTo(calRect.left + 26, calRect.top + 38)
      ..lineTo(calRect.left + 42, calRect.top + 22);
    canvas.drawPath(checkPath, paint);

    // 3. Flight leave trajectory arc at bottom-right
    final flightPath = Path()
      ..moveTo(size.width * 0.65, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.76,
        size.width * 0.92,
        size.height * 0.88,
      );
    canvas.drawPath(flightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
