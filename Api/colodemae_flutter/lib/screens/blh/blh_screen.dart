import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_palette.dart';
import '../../core/utils/location.dart';
import '../../core/utils/external_links.dart';
import '../../core/widgets/primary_cta_button.dart';
import '../../models/milk_bank.dart';
import '../../services/milk_bank_repository.dart';
import '../../services/milk_bank_controller.dart';
import '../../services/blh_demo_repository.dart';
import '../../services/blh_city_resolver.dart';
import 'bank_detail_screen.dart';
import 'widgets/bank_list_card.dart';
import 'widgets/donate_sheet.dart';

enum _LocateState { idle, locating, done, error }

/// Localização de Bancos de Leite Humano (BLH) — RF08.
class BlhScreen extends StatefulWidget {
  const BlhScreen(
      {super.key,
      this.repository,
      this.locationService,
      this.demoMode = blhDemoEnabled,
      this.cityResolver,
      this.launcher = launchExternalUrl});

  final MilkBankRepository? repository;
  final AppLocationService? locationService;
  final bool demoMode;
  final BlhCityResolver? cityResolver;
  final ExternalUrlLauncher launcher;

  @override
  State<BlhScreen> createState() => _BlhScreenState();
}

class _BlhScreenState extends State<BlhScreen> {
  late final MilkBankController _controller = MilkBankController(
    repository: widget.repository ??
        (widget.demoMode
            ? DemoMilkBankRepository()
            : FirestoreMilkBankRepository()),
    location: widget.locationService ?? AppLocationService(),
    demoMode: widget.demoMode,
    cityResolver: widget.cityResolver ?? AracajuCityResolver(),
  );
  _LocateState get _locate => _controller.busy
      ? _LocateState.locating
      : _controller.error != null
          ? _LocateState.error
          : _controller.located
              ? _LocateState.done
              : _LocateState.idle;
  String? get _errorMessage => _controller.error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLocate() => _controller.locate();

  void _openBank(MilkBankResult result) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BankDetailScreen(
            bank: result.bank,
            distanceKm: result.distanceKm,
            launcher: widget.launcher)));
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
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: palette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Encontre um Banco de Leite',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Encontre o ponto mais próximo para orientação ou doação de leite humano.',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.textMuted,
                height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _controller.busy
                ? null
                : _controller.error != null
                    ? _controller.retry
                    : _handleLocate,
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
                    color: _locate == _LocateState.error
                        ? const Color(0xFFD84315)
                        : palette.textFaint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_controller.busy &&
              _controller.error == null &&
              _controller.results.isEmpty)
            Text(
                _controller.searched
                    ? 'Nenhuma unidade verificada encontrada nesta cidade e estado.'
                    : 'Use sua localização.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMuted, fontSize: 13)),
          if (_controller.located &&
              _controller.results.any((r) => r.distanceKm != null)) ...[
            Text(
                'Distâncias estimadas em linha reta. Não representam a distância de deslocamento.',
                style: TextStyle(fontSize: 11, color: palette.textMuted)),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < _controller.results.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            BankListCard(
              bank: _controller.results[i].bank,
              onOpenDetails: () => _openBank(_controller.results[i]),
              distanceOverride: _controller.results[i].distanceLabel,
              nearest: _controller.located &&
                  i == 0 &&
                  _controller.results[i].distanceKm != null &&
                  _controller.results.every((r) =>
                      r.distanceKm == null ||
                      r.distanceKm! >= _controller.results[i].distanceKm!),
            ),
          ],
          if (_controller.hasMore)
            TextButton(
                onPressed: _controller.busy
                    ? null
                    : () => _controller.searchCity(
                        _controller.city!, _controller.state!,
                        more: true),
                child: const Text('Carregar mais unidades')),
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppPalette.button),
            ),
            const SizedBox(width: 10),
            Text(_controller.locating
                ? 'Localizando...'
                : 'Buscando unidades...'),
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
