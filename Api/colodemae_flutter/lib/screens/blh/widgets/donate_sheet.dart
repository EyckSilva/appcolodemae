import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/primary_cta_button.dart';

/// Abre a folha explicando como se tornar uma doadora de leite humano.
Future<void> showDonateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _DonateSheet(),
  );
}

class _DonateSheet extends StatelessWidget {
  const _DonateSheet();

  static const _eligibility = [
    'Estar amamentando ou ter excedente de leite já ordenhado',
    'Estar em boas condições de saúde',
    'Não fumar nem consumir bebidas alcoólicas',
    'Não usar medicamentos contraindicados durante a amamentação',
  ];

  static const _steps = [
    'Escolha um Banco de Leite Humano na lista',
    'Ligue para agendar sua visita ou a coleta domiciliar',
    'Leve o leite ordenhado, identificado e armazenado corretamente',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: palette.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: palette.border2,
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quero doar leite',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: palette.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Sua doação pode ajudar bebês prematuros ou internados que mais precisam do leite humano '
              'pasteurizado.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textMuted,
                  height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              'QUEM PODE DOAR',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: palette.textMuted),
            ),
            const SizedBox(height: 10),
            for (final item in _eligibility)
              _ChecklistRow(text: item, palette: palette),
            const SizedBox(height: 16),
            Text(
              'COMO FUNCIONA',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: palette.textMuted),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _steps.length; i++)
              _StepRow(index: i + 1, text: _steps[i], palette: palette),
            const SizedBox(height: 20),
            PrimaryCtaButton(
                label: 'Entendi',
                onPressed: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text, required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
                color: palette.textPrimary, shape: BoxShape.circle),
            child: Icon(LucideIcons.check, size: 12, color: palette.surface),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow(
      {required this.index, required this.text, required this.palette});

  final int index;
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
                color: AppPalette.button, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
