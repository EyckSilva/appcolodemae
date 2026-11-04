import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_palette.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/location.dart';
import '../../core/widgets/primary_cta_button.dart';
import '../../models/milk_bank.dart';
import 'bank_detail_screen.dart';
import 'widgets/bank_list_card.dart';
import 'widgets/donate_sheet.dart';

enum _LocateState { idle, locating, done, error }

/// Localização de Bancos de Leite Humano (BLH) — RF08.
class BlhScreen extends StatefulWidget {
  const BlhScreen({super.key});

  @override
  State<BlhScreen> createState() => _BlhScreenState();
}

class _BlhScreenState extends State<BlhScreen> {
  _LocateState _locate = _LocateState.idle;
  String? _errorMessage;

  /// Bancos reordenados por proximidade real, uma vez que a localização é obtida.
  List<MilkBank> _orderedBanks = milkBanks;

  /// Distâncias reais calculadas a partir da posição do usuário, por nome do banco.
  Map<String, String> _realDistances = const {};

  Future<void> _handleLocate() async {
    setState(() {
      _locate = _LocateState.locating;
      _errorMessage = null;
    });

    try {
      final position = await resolveCurrentPosition();

      final withDistance = milkBanks
          .map((bank) => (bank: bank, km: haversineKm(position.latitude, position.longitude, bank.latitude, bank.longitude)))
          .toList()
        ..sort((a, b) => a.km.compareTo(b.km));

      if (!mounted) return;
      setState(() {
        _orderedBanks = [for (final entry in withDistance) entry.bank];
        _realDistances = {for (final entry in withDistance) entry.bank.name: formatDistanceKm(entry.km)};
        _locate = _LocateState.done;
      });
    } on AppLocationServiceDisabledException {
      _fail('Ative o serviço de localização do seu dispositivo e tente novamente.');
    } on AppLocationPermissionDeniedException {
      _fail('Permissão de localização negada. Habilite-a nas configurações do dispositivo.');
    } catch (_) {
      _fail('Não foi possível obter sua localização agora. Tente novamente.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _locate = _LocateState.error;
      _errorMessage = message;
    });
  }

  void _openBank(MilkBank bank) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BankDetailScreen(bank: bank)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'REDE BLH',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: palette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Encontre um Banco de Leite',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: palette.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Encontre o ponto mais próximo para orientação ou doação de leite humano.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _locate == _LocateState.locating ? null : _handleLocate,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.textPrimary,
              disabledForegroundColor: palette.textPrimary,
              backgroundColor: palette.surface,
              side: BorderSide(color: palette.border2, width: 1.5),
            ),
            child: _buildLocateContent(palette),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_locate != _LocateState.error) ...[
                Icon(LucideIcons.lock, size: 12, color: palette.textFaint),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  _locate == _LocateState.error && _errorMessage != null
                      ? _errorMessage!
                      : 'Localização com seu consentimento — nunca armazenada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _locate == _LocateState.error ? const Color(0xFFD84315) : palette.textFaint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _orderedBanks.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            BankListCard(
              bank: _orderedBanks[i],
              onOpenDetails: () => _openBank(_orderedBanks[i]),
              distanceOverride: _realDistances[_orderedBanks[i].name],
            ),
          ],
          const SizedBox(height: 20),
          PrimaryCtaButton(
            label: 'Quero doar leite',
            icon: LucideIcons.droplet,
            onPressed: () => showDonateSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLocateContent(AppPalette palette) {
    switch (_locate) {
      case _LocateState.idle:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.mapPin, size: 18),
            SizedBox(width: 8),
            Text('Usar minha localização'),
          ],
        );
      case _LocateState.locating:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.button),
            ),
            SizedBox(width: 10),
            Text('Localizando...'),
          ],
        );
      case _LocateState.done:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circleCheck, size: 18),
            SizedBox(width: 8),
            Text('Localização encontrada'),
          ],
        );
      case _LocateState.error:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.triangleAlert, size: 18),
            SizedBox(width: 8),
            Text('Tentar novamente'),
          ],
        );
    }
  }
}
