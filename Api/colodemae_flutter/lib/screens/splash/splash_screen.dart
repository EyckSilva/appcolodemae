import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../core/painters/splash_illustration.dart';

/// Tela de boas-vindas exibida durante o carregamento do app (RF01).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), widget.onDone);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.peachSoft, palette.lilacSoft, palette.roseSoft],
          stops: const [0, 0.6, 1],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final dy = -6 * Curves.easeInOut.transform(_floatController.value);
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: const SplashIllustration(size: 128),
          ),
          const SizedBox(height: 32),
          Text(
            'Colo de Mãe',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: palette.textPrimary, height: 1),
          ),
          const SizedBox(height: 6),
          Text(
            'apoio, amor e amamentação',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulseDot(controller: _pulseController, delay: 0, color: palette.rose),
              const SizedBox(width: 10),
              _PulseDot(controller: _pulseController, delay: 150, color: palette.lilac),
              const SizedBox(width: 10),
              _PulseDot(controller: _pulseController, delay: 300, color: palette.peach),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.controller, required this.delay, required this.color});

  final AnimationController controller;
  final int delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shift = delay / 1400;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval((shift).clamp(0.0, 1.0), 1.0, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final opacity = 1 - (0.4 * animation.value);
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
