import 'dart:async';

import 'package:colodemae_flutter/app/app.dart';
import 'package:colodemae_flutter/app/theme/app_theme.dart';
import 'package:colodemae_flutter/screens/auth/auth_screen.dart';
import 'package:colodemae_flutter/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colodemae_flutter/core/widgets/app_toggle.dart';
import 'package:colodemae_flutter/models/baby.dart';
import 'package:colodemae_flutter/services/account_settings_service.dart';
import 'support/memory_account_settings.dart';

void main() {
  late MemoryAccountSettings settingsService;
  setUp(() {
    settingsService = MemoryAccountSettings();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => settingsService.dispose());

  Future<void> openAuth(WidgetTester tester,
      {bool dark = false, AuthService? authService}) async {
    await tester.pumpWidget(
      MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: AuthScreen(authService: authService ?? _TestAuthService())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, -250,
          scrollable: find.byType(Scrollable).last);
    }
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('Splash opens login', (tester) async {
    await tester.pumpWidget(ColoDeMaeApp(
        authService: _TestAuthService(), settingsService: settingsService));
    expect(find.text('Colo de Mãe'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Que bom ter você aqui!'), findsOneWidget);
  });

  testWidgets(
      'Session changes open main navigation and logout returns to login',
      (tester) async {
    final sessions = StreamController<User?>();
    addTearDown(sessions.close);
    final service = _TestAuthService()
      ..sessionStream = sessions.stream
      ..onLogout = () => sessions.add(null);
    await tester.pumpWidget(
        ColoDeMaeApp(authService: service, settingsService: settingsService));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    sessions.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Que bom ter você aqui!'), findsOneWidget);
    sessions.add(_TestUser());
    await tester.pumpAndSettle();
    expect(find.text('Olá, mamãe'), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    await tap(tester, 'Sair da conta');
    expect(service.logoutCalls, 1);
    expect(find.text('Que bom ter você aqui!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Session errors show a message instead of protected content',
      (tester) async {
    final sessions = StreamController<User?>();
    addTearDown(sessions.close);
    final service = _TestAuthService()..sessionStream = sessions.stream;
    await tester.pumpWidget(
        ColoDeMaeApp(authService: service, settingsService: settingsService));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    sessions.addError(Exception('session unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível verificar sua sessão.'), findsOneWidget);
    expect(find.text('Olá, mamãe'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Profile failure keeps the main screen and retries only the profile',
      (tester) async {
    final service = _ProfileRetryAuthService()
      ..sessionStream = Stream<User?>.value(_TestUser());
    addTearDown(service.failure.dispose);
    await tester.pumpWidget(
        ColoDeMaeApp(authService: service, settingsService: settingsService));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    service.failure.value =
        ProfileSyncFailure(uid: 'test-user', cause: Exception('unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, mamãe'), findsOneWidget);
    expect(
        find.text(
            'Sua conta está ativa, mas não foi possível salvar seu perfil.'),
        findsOneWidget);
    await tap(tester, 'Tentar novamente');
    expect(service.profileRetries, 1);
    expect(service.calls, 0);
    expect(find.text('Olá, mamãe'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Settings preserve edits and preferences after logout and login',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = StreamController<User?>();
    addTearDown(sessions.close);
    final service = _TestAuthService()
      ..sessionStream = sessions.stream
      ..onLogout = () => sessions.add(null);
    settingsService.profiles['test-user'] = {
      'nome': 'Ana no Firestore',
      'email': 'ana@example.com'
    };
    settingsService.babies['test-user'] = [
      SavedBaby(
          'existing-baby', Baby(name: 'Bia', birthDate: DateTime(2026, 10, 1)))
    ];
    await tester.pumpWidget(
        ColoDeMaeApp(authService: service, settingsService: settingsService));
    await tester.pump(const Duration(seconds: 3));
    sessions.add(_TestUser());
    await tester.pumpAndSettle();
    Future<void> openSettings() async {
      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();
    }

    await openSettings();
    expect(find.text('Ana no Firestore'), findsOneWidget);
    expect(find.text('Bia'), findsOneWidget);
    await tap(tester, 'Editar informações');
    await tester.enterText(find.byType(TextField).first, 'Beatriz');
    await tap(tester, 'Salvar');
    expect(find.text('Beatriz'), findsOneWidget);
    expect(settingsService.babies['test-user']!.single.id, 'existing-baby');
    final toggles = find.byType(AppToggle);
    await Scrollable.ensureVisible(tester.element(toggles.at(1)),
        alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(toggles.at(1));
    await tester.pumpAndSettle();
    await tap(tester, 'Sair da conta');
    expect(find.byType(AuthScreen), findsOneWidget);
    sessions.add(_TestUser());
    await tester.pumpAndSettle();
    await openSettings();
    expect(find.text('Beatriz'), findsOneWidget);
    expect(
        tester.widget<AppToggle>(find.byType(AppToggle).at(1)).value, isFalse);
    expect(
        tester.widget<AppToggle>(find.byType(AppToggle).at(2)).value, isTrue);
    await tap(tester, 'Sair da conta');
    sessions.add(_OtherTestUser());
    await tester.pumpAndSettle();
    await openSettings();
    expect(find.text('Beatriz'), findsNothing);
    expect(
        tester.widget<AppToggle>(find.byType(AppToggle).at(1)).value, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Failed baby save keeps the existing editor and data',
      (tester) async {
    settingsService.failWrites = true;
    settingsService.babies['test-user'] = [
      SavedBaby('old', Baby(name: 'Bia', birthDate: DateTime(2026, 10, 1)))
    ];
    final service = _TestAuthService()
      ..sessionStream = Stream<User?>.value(_TestUser());
    await tester.pumpWidget(
        ColoDeMaeApp(authService: service, settingsService: settingsService));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();
    await tap(tester, 'Editar informações');
    await tester.enterText(find.byType(TextField).first, 'Beatriz');
    await tap(tester, 'Salvar');
    expect(
        find.text(
            'Não foi possível salvar as informações do bebê. Tente novamente.'),
        findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(settingsService.babies['test-user']!.single.baby.name, 'Bia');
    settingsService.failWrites = false;
    await tap(tester, 'Salvar');
    expect(settingsService.babies['test-user']!.single.baby.name, 'Beatriz');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Login validates fields and rejects wrong password',
      (tester) async {
    final service = _TestAuthService()
      ..error = FirebaseAuthException(code: 'invalid-credential');
    await openAuth(tester, authService: service);
    await tap(tester, 'Entrar');
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'errada');
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse);
    await tap(tester, 'Entrar');
    expect(service.loginCalls, 1);
    expect(find.textContaining('E-mail ou senha incorretos'), findsOneWidget);
  });

  testWidgets('Registration validates confirmation and calls AuthService',
      (tester) async {
    final service = _TestAuthService();
    await openAuth(tester, authService: service);
    await tap(tester, 'Cadastre-se');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana Silva');
    await tester.enterText(fields.at(1), 'ana@example.com');
    await tester.enterText(fields.at(2), 'senha123');
    await tester.enterText(fields.at(3), 'diferente');
    await tap(tester, 'Criar minha conta');
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(service.calls, 0);
    await tester.enterText(fields.at(3), 'senha123');
    await tap(tester, 'Criar minha conta');
    expect(service.calls, 1);
    expect(service.name, 'Ana Silva');
    expect(service.email, 'ana@example.com');
    expect(service.password, 'senha123');
    expect(find.text('Conta criada com sucesso!'), findsOneWidget);
    expect(find.text('Crie sua conta'), findsOneWidget);
  });

  testWidgets('Registration shows Firebase error and allows retry',
      (tester) async {
    final service = _TestAuthService()
      ..error = FirebaseAuthException(code: 'email-already-in-use');
    await openAuth(tester, authService: service);
    await tap(tester, 'Cadastre-se');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), 'ana@example.com');
    await tester.enterText(fields.at(2), 'senha123');
    await tester.enterText(fields.at(3), 'senha123');
    await tap(tester, 'Criar minha conta');
    expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
    expect(find.text('Crie sua conta'), findsOneWidget);
    service.error = null;
    await tap(tester, 'Criar minha conta');
    expect(service.calls, 2);
    expect(find.text('Conta criada com sucesso!'), findsOneWidget);
  });

  testWidgets('Recovery validates e-mail and calls the service',
      (tester) async {
    final service = _TestAuthService();
    await openAuth(tester, authService: service);
    await tap(tester, 'Esqueci minha senha');
    await tester.enterText(find.byType(TextFormField), 'invalido');
    await tap(tester, 'Enviar instruções');
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'ana@example.com');
    await tap(tester, 'Enviar instruções');
    expect(find.text('Confira seu e-mail'), findsOneWidget);
    expect(service.recoveryEmail, 'ana@example.com');
    expect(find.text('Esta é uma simulação. Nenhum e-mail foi enviado.'),
        findsNothing);
    await tap(tester, 'Voltar para o login');
    expect(find.text('Que bom ter você aqui!'), findsOneWidget);
  });

  testWidgets('Login calls service and confirms success', (tester) async {
    final service = _TestAuthService();
    await openAuth(tester, authService: service);
    await tester.enterText(find.byType(TextFormField).first, 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'senha123');
    await tap(tester, 'Entrar');
    expect(service.loginCalls, 1);
    expect(service.email, 'ana@example.com');
    expect(service.password, 'senha123');
    expect(find.text('Login realizado com sucesso!'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('Auth fits a narrow viewport with theme dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openAuth(tester, dark: dark);
      expect(tester.takeException(), isNull);
      await tap(tester, 'Cadastre-se');
      expect(tester.takeException(), isNull);
      await tap(tester, 'Entrar');
      await tap(tester, 'Esqueci minha senha');
      expect(tester.takeException(), isNull);
    });
  }
}

class _TestAuthService extends AuthService {
  Stream<User?>? sessionStream;
  VoidCallback? onLogout;
  int logoutCalls = 0;

  @override
  Stream<User?> get usuarioLogado => sessionStream ?? Stream<User?>.value(null);

  @override
  Future<void> sair() async {
    logoutCalls++;
    onLogout?.call();
  }

  int calls = 0;
  int loginCalls = 0;
  String? recoveryEmail;
  String? name;
  String? email;
  String? password;
  FirebaseAuthException? error;

  @override
  Future<UserCredential> entrar(
      {required String email, required String senha}) async {
    loginCalls++;
    this.email = email;
    password = senha;
    if (error != null) throw error!;
    return _TestCredential();
  }

  @override
  Future<void> recuperarSenha(String email) async {
    recoveryEmail = email;
    if (error != null) throw error!;
  }

  @override
  Future<UserCredential> cadastrar(
      {required String nome,
      required String email,
      required String senha}) async {
    calls++;
    name = nome;
    this.email = email;
    password = senha;
    if (error != null) throw error!;
    return _TestCredential();
  }
}

class _ProfileRetryAuthService extends _TestAuthService {
  final failure = ValueNotifier<ProfileSyncFailure?>(null);
  int profileRetries = 0;

  @override
  ValueNotifier<ProfileSyncFailure?> get falhaPerfil => failure;

  @override
  Future<bool> sincronizarPerfil({User? usuario, String? nome}) async {
    profileRetries++;
    failure.value = null;
    return true;
  }
}

class _TestCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestUser implements User {
  @override
  String get uid => 'test-user';

  @override
  String? get displayName => 'Ana Silva';

  @override
  String? get email => 'ana@example.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OtherTestUser extends _TestUser {
  @override
  String get uid => 'other-user';
}
