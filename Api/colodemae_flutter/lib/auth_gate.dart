import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'navigation/root_shell.dart';
import 'screens/auth/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/account_settings_service.dart';
import 'app/account_data_scope.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService = context.read<AuthService>();
  late final Stream<User?> _session = _authService.usuarioLogado;

  @override
  void initState() {
    super.initState();
    _authService.falhaPerfil.addListener(_onProfileFailure);
  }

  void _onProfileFailure() {
    final failure = _authService.falhaPerfil.value;
    if (failure == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_authService.falhaPerfil.value, failure)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Sua conta está ativa, mas não foi possível salvar seu perfil.'),
          action: SnackBarAction(
            label: 'Tentar novamente',
            onPressed: () => unawaited(_authService.sincronizarPerfil()),
          ),
        ),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _authService.falhaPerfil.removeListener(_onProfileFailure);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Não foi possível verificar sua sessão.',
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return Provider<User?>.value(
            value: snapshot.data,
            child: AccountDataScope(
              key: ValueKey(snapshot.data!.uid),
              uid: snapshot.data!.uid,
              service: context.read<AccountSettingsService>(),
              child: const RootShell(),
            ),
          );
        }

        return AuthScreen(authService: _authService);
      },
    );
  }
}
