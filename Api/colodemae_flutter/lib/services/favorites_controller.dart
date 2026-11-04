import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mantém o conjunto de conteúdos favoritados (RF07) e persiste entre sessões,
/// representando a disponibilidade "offline" desses conteúdos no protótipo.
class FavoritesController extends ChangeNotifier {
  FavoritesController() {
    _load();
  }

  static const _prefsKey = 'favorite_ids';

  final Set<String> _favorites = <String>{};

  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites.addAll(prefs.getStringList(_prefsKey) ?? const []);
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _favorites.toList());
  }
}
