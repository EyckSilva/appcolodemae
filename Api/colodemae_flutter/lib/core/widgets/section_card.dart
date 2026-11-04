import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';

/// Cartão com cabeçalho (ícone + título) usado nas Configurações.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.icon, required this.title, required this.children});

  final Widget icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: palette.border))),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.textPrimary),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
