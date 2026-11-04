import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';

class _QuickAccessItem {
  const _QuickAccessItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const _items = [
  _QuickAccessItem(icon: LucideIcons.mouth, label: 'Pega'),
  _QuickAccessItem(icon: LucideIcons.droplets, label: 'Ordenha'),
  _QuickAccessItem(icon: LucideIcons.refrigerator, label: 'Armazenamento'),
];

/// Grade de acesso rápido às áreas de Pega, Ordenha e Armazenamento (RF05).
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // No modo noturno o pêssego vira marrom e destoa dos outros cartões,
    // então o Armazenamento usa o mesmo tom lilás.
    final backgrounds = [palette.roseSoft, palette.lilacSoft, isDark ? palette.lilacSoft : palette.peachSoft];

    return Row(
      children: List.generate(_items.length, (i) {
        final item = _items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == _items.length - 1 ? 0 : 12),
            child: Material(
              color: backgrounds[i],
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: palette.border, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 26, color: palette.textPrimary),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
