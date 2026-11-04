import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_palette.dart';
import '../../core/widgets/connectivity_badge.dart';
import '../../core/widgets/primary_cta_button.dart';
import '../../models/connection_status.dart';
import '../../services/baby_controller.dart';
import '../../services/favorites_controller.dart';
import 'widgets/baby_card.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/tip_of_the_day_card.dart';

const String kDailyTipFavoriteId = 'tip-today';

/// Tela inicial: saudação, dados do bebê, dica do dia, acesso rápido e CTA de doação.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigateToTab});

  final void Function(int tabIndex) onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final baby = context.watch<BabyController>().baby;
    final favorites = context.watch<FavoritesController>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEM-VINDA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Olá, mamãe',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
              const ConnectivityBadge(status: ConnectionStatus.online),
            ],
          ),
          const SizedBox(height: 20),
          BabyCard(baby: baby),
          const SizedBox(height: 16),
          TipOfTheDayCard(
            isFavorite: favorites.isFavorite(kDailyTipFavoriteId),
            onToggleFavorite: () => favorites.toggle(kDailyTipFavoriteId),
          ),
          const SizedBox(height: 20),
          Text(
            'ACESSO RÁPIDO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          QuickAccessGrid(onTap: () => onNavigateToTab(1)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.lilacSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.cloudDownload, size: 20, color: palette.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Conteúdos disponíveis offline',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dicas e favoritos acessíveis sem internet',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryCtaButton(label: 'Onde doar leite', icon: LucideIcons.droplet, onPressed: () => onNavigateToTab(2)),
        ],
      ),
    );
  }
}
