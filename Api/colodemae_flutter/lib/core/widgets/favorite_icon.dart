import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_palette.dart';

/// Coração de favorito no estilo Lucide: contorno quando inativo e
/// selo rosa preenchido quando o item está salvo.
class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({super.key, required this.active, this.size = 20});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: active
          ? Container(
              key: const ValueKey(true),
              width: size + 10,
              height: size + 10,
              decoration: const BoxDecoration(color: AppPalette.button, shape: BoxShape.circle),
              child: Icon(LucideIcons.heart, size: size - 4, color: Colors.white),
            )
          : SizedBox(
              key: const ValueKey(false),
              width: size + 10,
              height: size + 10,
              child: Icon(LucideIcons.heart, size: size, color: context.palette.textPrimary),
            ),
    );
  }
}
