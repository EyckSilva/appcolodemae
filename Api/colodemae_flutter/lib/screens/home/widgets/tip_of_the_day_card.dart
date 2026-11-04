import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/favorite_icon.dart';

const String kDailyTip = 'Uma pega adequada ajuda o bebê a mamar melhor e pode evitar desconforto durante a '
    'amamentação. Lembre-se: a barriga do bebê deve estar voltada para a sua.';

/// Dica diária expansível, sem qualquer elemento visual associado à IA (RF04).
class TipOfTheDayCard extends StatefulWidget {
  const TipOfTheDayCard({super.key, required this.isFavorite, required this.onToggleFavorite});

  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  State<TipOfTheDayCard> createState() => _TipOfTheDayCardState();
}

class _TipOfTheDayCardState extends State<TipOfTheDayCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DICA DO DIA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: palette.textMuted,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onToggleFavorite,
                visualDensity: VisualDensity.compact,
                icon: FavoriteIcon(active: widget.isFavorite),
              ),
            ],
          ),
          if (!_open) ...[
            const SizedBox(height: 4),
            Text(
              '${kDailyTip.substring(0, 72)}…',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _open = true),
                child: const Text('Ver dica do dia'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              kDailyTip,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textSecondary, height: 1.5),
            ),
            if (widget.isFavorite) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.cloudDownload, size: 16, color: palette.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Salvo — disponível offline',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textMuted),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
