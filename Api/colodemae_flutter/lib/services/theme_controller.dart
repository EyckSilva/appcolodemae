import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o modo noturno e persiste a preferência entre sessões.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _prefsKey = 'dark_mode_enabled';

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefsKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleDark() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDark);
  }
}
