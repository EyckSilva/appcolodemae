import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/account_settings_service.dart';
import '../services/baby_controller.dart';
import '../services/settings_controller.dart';

/// Descarta os dados e assinaturas ao sair ou trocar o UID da sessão.
class AccountDataScope extends StatefulWidget {
  const AccountDataScope(
      {super.key,
      required this.uid,
      required this.service,
      required this.child});
  final String uid;
  final AccountSettingsService service;
  final Widget child;
  @override
  State<AccountDataScope> createState() => _AccountDataScopeState();
}

class _AccountDataScopeState extends State<AccountDataScope> {
  late final BabyController _baby =
      BabyController(uid: widget.uid, service: widget.service);
  late final SettingsController _settings =
      SettingsController(uid: widget.uid, service: widget.service);
  Object? _lastBabyError;
  Object? _lastSettingsError;

  @override
  void initState() {
    super.initState();
    _baby.addListener(_onError);
    _settings.addListener(_onError);
    _onError();
  }

  void _onError() {
    final settingsError = _settings.profileError ?? _settings.preferencesError;
    if ((_baby.error != null && !identical(_lastBabyError, _baby.error)) ||
        (settingsError != null &&
            !identical(_lastSettingsError, settingsError))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Não foi possível carregar todos os dados da conta. Verifique sua conexão.'),
        ));
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    _lastBabyError = _baby.error;
    _lastSettingsError = settingsError;
  }

  @override
  void dispose() {
    _baby.removeListener(_onError);
    _settings.removeListener(_onError);
    _baby.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(providers: [
        ChangeNotifierProvider<BabyController>.value(value: _baby),
        ChangeNotifierProvider<SettingsController>.value(value: _settings),
      ], child: widget.child);
}
