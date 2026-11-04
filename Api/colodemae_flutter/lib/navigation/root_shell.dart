import 'package:flutter/material.dart';

import '../app/theme/app_palette.dart';
import '../screens/blh/blh_screen.dart';
import '../screens/content/content_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';

class _TabSpec {
  const _TabSpec({required this.label, required this.icon, required this.accent});

  final String label;
  final IconData icon;
  final Color Function(AppPalette) accent;
}

/// Casca de navegação principal: 4 abas fixas, cada uma com sua própria pilha de
/// navegação, preservando estado ao trocar de aba (RootShell substitui a antiga
/// navegação por `screen` em memória do protótipo original).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  static const List<_TabSpec> _tabs = [
    _TabSpec(label: 'Início', icon: Icons.home_rounded, accent: _roseAccent),
    _TabSpec(label: 'Conteúdos', icon: Icons.menu_book_rounded, accent: _lilacAccent),
    _TabSpec(label: 'BLH', icon: Icons.water_drop_rounded, accent: _peachAccent),
    _TabSpec(label: 'Config.', icon: Icons.settings_rounded, accent: _roseAccent),
  ];

  static Color _roseAccent(AppPalette p) => p.rose;
  static Color _lilacAccent(AppPalette p) => p.lilac;
  static Color _peachAccent(AppPalette p) => p.peach;

  static Color _softFor(AppPalette p, int index) {
    switch (index) {
      case 1:
        return p.lilacSoft;
      case 2:
        return p.peachSoft;
      default:
        return p.roseSoft;
    }
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildTabNavigator(int index) {
    final builders = <WidgetBuilder>[
      (_) => HomeScreen(onNavigateToTab: _navigateToTab),
      (_) => const ContentScreen(),
      (_) => const BlhScreen(),
      (_) => const SettingsScreen(),
    ];

    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: builders[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canPopRoot = _currentIndex == 0 && !(_navigatorKeys[0].currentState?.canPop() ?? false);

    return PopScope(
      canPop: canPopRoot,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _navigatorKeys[_currentIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(4, _buildTabNavigator),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.border, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final active = i == _currentIndex;
                final accent = tab.accent(palette);
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onTabTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? _softFor(palette, i) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, color: active ? accent : palette.textFaint, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: active ? accent : palette.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
