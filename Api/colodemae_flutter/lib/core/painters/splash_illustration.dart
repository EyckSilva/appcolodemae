import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';

/// Logo ilustrado exibido na splash screen (RF01).
class SplashIllustration extends StatelessWidget {
  const SplashIllustration({super.key, this.size = 128});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SplashPainter(palette: palette)),
    );
  }
}

class _SplashPainter extends CustomPainter {
  _SplashPainter({required this.palette});

  final AppPalette palette;
  static const double _viewBox = 128;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    canvas.save();
    canvas.scale(scale, scale);

    canvas.drawCircle(const Offset(64, 64), 62, Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawCircle(const Offset(64, 64), 52, Paint()..color = palette.roseSoft);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(58, 84), width: 44, height: 36),
      Paint()..color = palette.lilacMid,
    );
    canvas.drawCircle(const Offset(58, 56), 16, Paint()..color = palette.peachMid);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(58, 46), width: 32, height: 22),
      Paint()..color = AppPalette.illustrationHair,
    );
    canvas.drawCircle(const Offset(76, 78), 12, Paint()..color = palette.peachSoft);
    canvas.drawCircle(const Offset(82, 67), 10, Paint()..color = palette.peachMid);

    final heart = Path()
      ..moveTo(64, 32)
      ..cubicTo(64, 32, 60, 27, 57, 29.5)
      ..cubicTo(54, 32, 54, 37, 57, 40)
      ..lineTo(64, 47)
      ..lineTo(71, 40)
      ..cubicTo(74, 37, 74, 32, 71, 29.5)
      ..cubicTo(68, 27, 64, 32, 64, 32)
      ..close();
    canvas.drawPath(heart, Paint()..color = palette.rose);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => oldDelegate.palette != palette;
}
