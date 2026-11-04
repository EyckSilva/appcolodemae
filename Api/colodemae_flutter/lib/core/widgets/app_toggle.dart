import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';

/// Interruptor customizado em formato de pílula, usado nas linhas de configuração.
class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged, this.accentColor});

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final activeColor = accentColor ?? palette.rose;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 48,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? activeColor : palette.border2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
