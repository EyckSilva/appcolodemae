import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby.dart';

/// Mantém os dados do bebê (RF02) e persiste entre sessões.
class BabyController extends ChangeNotifier {
  BabyController() {
    _load();
  }

  static const _nameKey = 'baby_name';
  static const _birthDateKey = 'baby_birth_date';

  Baby _baby = Baby(name: 'Luna', birthDate: DateTime.now().subtract(const Duration(days: 5)));
  Baby get baby => _baby;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    final birthDateIso = prefs.getString(_birthDateKey);
    if (name != null && birthDateIso != null) {
      _baby = Baby(name: name, birthDate: DateTime.parse(birthDateIso));
      notifyListeners();
    }
  }

  Future<void> update(Baby baby) async {
    _baby = baby;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, baby.name);
    await prefs.setString(_birthDateKey, baby.birthDate.toIso8601String());
  }
}
