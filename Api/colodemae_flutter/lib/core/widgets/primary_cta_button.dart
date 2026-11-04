import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';

/// Botão de destaque no rosa padrão do app, usado nas chamadas principais (ex.: doação de leite).
class PrimaryCtaButton extends StatelessWidget {
  const PrimaryCtaButton({super.key, required this.label, this.icon, this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.button,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      shadowColor: AppPalette.button.withValues(alpha: 0.45),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
