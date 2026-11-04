import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';

/// Ilustração principal (mãe e bebê) exibida no cartão do bebê na Home.
class MomBabyIllustration extends StatelessWidget {
  const MomBabyIllustration({super.key, this.size = 128});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MomBabyPainter(palette: palette)),
    );
  }
}

class _MomBabyPainter extends CustomPainter {
  _MomBabyPainter({required this.palette});

  final AppPalette palette;
  static const double _viewBox = 200;
  static const Color _hair = AppPalette.illustrationHair;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    canvas.save();
    canvas.scale(scale, scale);

    // Halo de fundo.
    canvas.drawCircle(const Offset(100, 108), 78, Paint()..color = palette.lilacSoft);
    canvas.drawCircle(const Offset(100, 105), 62, Paint()..color = palette.roseSoft.withValues(alpha: 0.6));

    // Corpo da mãe.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(86, 148), width: 72, height: 60),
      Paint()..color = palette.lilacMid,
    );
    final wrap = Path()
      ..moveTo(62, 142)
      ..quadraticBezierTo(56, 155, 62, 165)
      ..quadraticBezierTo(68, 175, 80, 172)
      ..lineTo(110, 162)
      ..quadraticBezierTo(124, 155, 118, 143)
      ..quadraticBezierTo(112, 132, 100, 136)
      ..close();
    canvas.drawPath(wrap, Paint()..color = palette.lilacMid);

    // Pescoço e cabeça da mãe.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(80, 102, 12, 18), const Radius.circular(6)),
      Paint()..color = palette.peachMid,
    );
    canvas.drawCircle(const Offset(86, 90), 26, Paint()..color = palette.peachMid);
    canvas.drawOval(Rect.fromCenter(center: const Offset(86, 74), width: 52, height: 36), Paint()..color = _hair);
    canvas.drawOval(Rect.fromCenter(center: const Offset(62, 88), width: 18, height: 36), Paint()..color = _hair);
    canvas.drawOval(Rect.fromCenter(center: const Offset(110, 88), width: 18, height: 36), Paint()..color = _hair);

    final hairStroke = Paint()
      ..color = _hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(60, 96)..quadraticBezierTo(58, 108, 62, 116), hairStroke);
    canvas.drawPath(Path()..moveTo(112, 96)..quadraticBezierTo(114, 108, 110, 116), hairStroke);

    // Rosto da mãe.
    final eyePaint = Paint()..color = palette.textPrimary;
    canvas.drawOval(Rect.fromCenter(center: const Offset(79, 90), width: 7, height: 8), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(93, 90), width: 7, height: 8), eyePaint);
    canvas.drawCircle(const Offset(80.5, 88.5), 1.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(94.5, 88.5), 1.2, Paint()..color = Colors.white);

    final blush = Paint()..color = palette.peach.withValues(alpha: 0.45);
    canvas.drawOval(Rect.fromCenter(center: const Offset(72, 97), width: 12, height: 8), blush);
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 97), width: 12, height: 8), blush);

    final smileStroke = Paint()
      ..color = palette.rose
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(78, 97)..quadraticBezierTo(86, 104, 94, 97), smileStroke);

    // Bebê.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(118, 150), width: 40, height: 32),
      Paint()..color = palette.peachSoft,
    );
    canvas.drawCircle(const Offset(124, 132), 17, Paint()..color = palette.peachMid);

    final babyHairStroke = Paint()
      ..color = _hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(118, 118)..quadraticBezierTo(124, 112, 130, 118), babyHairStroke);

    final babyFeatureStroke = Paint()
      ..color = palette.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(118, 130)..quadraticBezierTo(120.5, 127, 123, 130), babyFeatureStroke);
    canvas.drawPath(Path()..moveTo(126, 130)..quadraticBezierTo(128.5, 127, 131, 130), babyFeatureStroke);

    final babySmileStroke = Paint()
      ..color = palette.rose
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(120, 136)..quadraticBezierTo(124, 140, 128, 136), babySmileStroke);

    final babyBlush = Paint()..color = palette.peach.withValues(alpha: 0.5);
    canvas.drawOval(Rect.fromCenter(center: const Offset(116, 135), width: 8, height: 6), babyBlush);
    canvas.drawOval(Rect.fromCenter(center: const Offset(132, 135), width: 8, height: 6), babyBlush);

    // Coração decorativo.
    final heart = Path()
      ..moveTo(100, 50)
      ..cubicTo(100, 50, 95, 44, 91, 46.5)
      ..cubicTo(87, 49, 87, 54, 91, 57.5)
      ..lineTo(100, 67)
      ..lineTo(109, 57.5)
      ..cubicTo(113, 54, 113, 49, 109, 46.5)
      ..cubicTo(105, 44, 100, 50, 100, 50)
      ..close();
    canvas.drawPath(heart, Paint()..color = palette.rose);

    // Confetes decorativos.
    final lilacDot = Paint()..color = palette.lilac.withValues(alpha: 0.7);
    for (final dot in const [Offset(46, 60), Offset(44, 145)]) {
      canvas.drawCircle(dot, 3, lilacDot);
    }
    canvas.drawCircle(const Offset(155, 70), 2.5, lilacDot);
    canvas.drawCircle(const Offset(148, 48), 2, lilacDot);
    canvas.drawCircle(const Offset(160, 138), 2.5, lilacDot);

    final peachDot = Paint()..color = palette.peach.withValues(alpha: 0.6);
    canvas.drawCircle(const Offset(58, 45), 2, peachDot);
    canvas.drawCircle(const Offset(163, 110), 2, peachDot);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MomBabyPainter oldDelegate) => oldDelegate.palette != palette;
}
