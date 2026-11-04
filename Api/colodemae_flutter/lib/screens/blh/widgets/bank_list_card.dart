import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/pill.dart';
import '../../../models/milk_bank.dart';

const Color _acceptingColor = Color(0xFF388E3C);
const Color _acceptingBackground = Color(0xFFE8F5E9);

/// Cartão de resumo de um Banco de Leite Humano na listagem (RF08).
class BankListCard extends StatelessWidget {
  const BankListCard({super.key, required this.bank, required this.onOpenDetails, this.distanceOverride});

  final MilkBank bank;
  final VoidCallback onOpenDetails;

  /// Distância real calculada a partir da localização do usuário, quando disponível.
  final String? distanceOverride;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final acceptsDonation = bank.tags.contains('Doação');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (bank.tags.isNotEmpty)
                      Pill(label: bank.tags.first, color: palette.lilac, background: palette.lilacSoft),
                    if (acceptsDonation)
                      const Pill(label: '✓ Aceitando', color: _acceptingColor, background: _acceptingBackground),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DistanceBadge(distance: distanceOverride ?? bank.distance, palette: palette),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bank.name,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: palette.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            bank.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenDetails,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              child: const Text('Ver detalhes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.distance, required this.palette});

  final String distance;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: palette.roseSoft, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(
            distance,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: palette.rose),
          ),
          Text(
            'de você',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: palette.rose.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
