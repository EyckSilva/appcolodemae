import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../auth_gate.dart';
import '../screens/splash/splash_screen.dart';
import '../services/auth_service.dart';
import '../services/account_settings_service.dart';
import '../services/favorites_controller.dart';
import '../services/theme_controller.dart';
import 'theme/app_theme.dart';

/// Widget raiz do Colo de Mãe: injeta os controladores de estado e monta o
/// [MaterialApp] com os temas claro e escuro definidos em [AppTheme].
class ColoDeMaeApp extends StatelessWidget {
  const ColoDeMaeApp({super.key, this.authService, this.settingsService});

  final AuthService? authService;
  final AccountSettingsService? settingsService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService ?? AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => FavoritesController()),
        Provider<AccountSettingsService>(
            create: (_) => settingsService ?? AccountSettingsService()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Colo de Mãe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.themeMode,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _AppRoot(),
          );
        },
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return _showSplash
        ? SplashScreen(onDone: () => setState(() => _showSplash = false))
        : const AuthGate();
  }
}
