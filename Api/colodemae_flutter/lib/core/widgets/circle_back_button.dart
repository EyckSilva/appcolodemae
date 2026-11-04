import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';

/// Botão de voltar circular usado nos cabeçalhos das telas de detalhe.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.roseSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: palette.border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(LucideIcons.chevronLeft, color: context.palette.textPrimary, size: 22),
        ),
      ),
    );
  }
}
