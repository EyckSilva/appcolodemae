import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/maps_launcher.dart';
import '../../core/utils/phone_launcher.dart';
import '../../core/utils/external_links.dart';
import '../../core/widgets/circle_back_button.dart';
import '../../core/widgets/pill.dart';
import '../../core/widgets/primary_cta_button.dart';
import '../../models/milk_bank.dart';
import 'widgets/donate_sheet.dart';

/// Detalhes de um Banco de Leite Humano: endereço, horário, contato e orientações (RF09).
class BankDetailScreen extends StatelessWidget {
  const BankDetailScreen(
      {super.key,
      required this.bank,
      this.distanceKm,
      this.launcher = launchExternalUrl});
  final double? distanceKm;
  final ExternalUrlLauncher launcher;

  final MilkBank bank;

  Future<void> _launch(
      BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Não foi possível abrir o aplicativo. Tente novamente.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                CircleBackButton(
                    onPressed: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bank.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                        height: 1.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
                icon: LucideIcons.mapPin,
                label: 'Endereço',
                value: bank.formattedAddress),
            const SizedBox(height: 12),
            _InfoRow(
                icon: LucideIcons.clock,
                label: 'Horário',
                value:
                    bank.hours.isEmpty ? 'Horário não informado' : bank.hours),
            const SizedBox(height: 12),
            _InfoRow(
                icon: LucideIcons.headphones,
                label: 'Contato',
                value: bank.phone.isEmpty
                    ? 'Telefone não informado'
                    : bank.contactText),
            if (distanceKm != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                      '${distanceKm!.toStringAsFixed(1)} km em linha reta (estimativa).',
                      style:
                          TextStyle(color: palette.textMuted, fontSize: 12))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in bank.tags)
                  Pill(
                      label: tag,
                      color: palette.rose,
                      background: palette.roseSoft),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.lilacSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.shield,
                          size: 18, color: palette.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Orientação para doação',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: palette.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A doadora deve estar em boas condições de saúde, não fumar, não consumir bebidas alcoólicas '
                    'e não tomar medicamentos contraindicados. Ligue antes para agendar sua visita.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: palette.peachSoft,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Icon(LucideIcons.lock, size: 16, color: palette.textPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sua localização é usada somente com seu consentimento e nunca armazenada.',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !bank.hasCoordinates &&
                            !bank.canUseAddressForDirections
                        ? null
                        : () => _launch(
                            context,
                            () => bank.canUseAddressForDirections
                                ? openMapsAddressDirections(
                                    '${bank.address}, ${bank.city}, ${bank.state}, Brasil',
                                    launcher: launcher)
                                : openMapsDirections(
                                    latitude: bank.latitude!,
                                    longitude: bank.longitude!,
                                    launcher: launcher)),
                    icon: const Icon(LucideIcons.navigation, size: 18),
                    label: const Text('Iniciar Rota'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: bank.phone.isEmpty
                        ? null
                        : () => _launch(context,
                            () => callPhone(bank.phone, launcher: launcher)),
                    icon: const Icon(LucideIcons.phone, size: 18),
                    label: const Text('Ligar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryCtaButton(
              label: 'Quero doar leite',
              icon: LucideIcons.droplet,
              onPressed: () => showDonateSheet(context),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.lilacSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.lock, size: 18, color: palette.textPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                              text:
                                  'Sua localização é usada apenas para encontrar BLHs próximos e é '),
                          TextSpan(
                            text: 'criptografada e não armazenada',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: palette.textSecondary),
                          ),
                          const TextSpan(
                            text:
                                '. Seus dados de saúde nunca são compartilhados sem consentimento explícito.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: palette.roseSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: palette.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: palette.textMuted),
                ),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                        color: palette.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
