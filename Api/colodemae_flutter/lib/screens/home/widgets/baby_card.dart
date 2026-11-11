import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/painters/mom_baby_illustration.dart';
import '../../../core/widgets/pill.dart';
import '../../../models/baby.dart';

/// Cartão de destaque com os dados do bebê e a fase atual (RF02/RF03).
class BabyCard extends StatelessWidget {
  const BabyCard({super.key, required this.baby});

  final Baby? baby;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final info = baby == null ? null : babyPhaseInfo[baby!.phase];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border, width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.lilacSoft, palette.roseSoft],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SEU BEBÊ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  baby?.name ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: palette.textPrimary,
                      height: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  baby == null ? '—' : '${baby!.daysSinceBirth} dias de vida',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: palette.textSecondary),
                ),
                const SizedBox(height: 12),
                Pill(
                    label: info == null ? '—' : '${info.emoji} ${info.label}',
                    color: Colors.white,
                    background: palette.rose),
                const SizedBox(height: 8),
                Text(
                  info?.message ?? '—',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const MomBabyIllustration(size: 120),
        ],
      ),
    );
  }
}
