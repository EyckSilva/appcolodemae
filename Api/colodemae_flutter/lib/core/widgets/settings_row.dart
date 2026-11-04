import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';

/// Linha padrão de configuração: rótulo + descrição opcional à esquerda, controle à direita.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.label, this.description, required this.trailing, this.isLast = false});

  final String label;
  final String? description;
  final Widget trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
