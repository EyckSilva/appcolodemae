import 'dart:async';
import 'package:colodemae_flutter/models/baby.dart';
import 'package:colodemae_flutter/services/account_settings_service.dart';

/// Persistência em memória entre sessões para testes, sem contas Firebase reais.
class MemoryAccountSettings extends AccountSettingsService {
  final profiles = <String, Map<String, dynamic>>{};
  final babies = <String, List<SavedBaby>>{};
  final preferences = <String, Map<String, dynamic>>{};
  final _events = StreamController<String>.broadcast(sync: true);
  bool failWrites = false;
  int babyWrites = 0;

  Stream<T> _watch<T>(String key, T Function() read) =>
      Stream<T>.multi((controller) {
        final sub = _events.stream
            .where((event) => event == key)
            .listen((_) => controller.add(read()));
        controller.add(read());
        controller.onCancel = sub.cancel;
      });

  @override
  Stream<Map<String, dynamic>?> perfil(String uid) =>
      _watch('profile/$uid', () => profiles[uid]);
  @override
  Stream<List<SavedBaby>> bebes(String uid) =>
      _watch('baby/$uid', () => babies[uid] ?? []);
  @override
  Stream<Map<String, dynamic>?> preferencias(String uid) =>
      _watch('prefs/$uid', () => preferences[uid]);

  @override
  Future<String> salvarBebe(String uid, Baby baby, {String? id}) async {
    if (failWrites) throw StateError('write failed');
    babyWrites++;
    final current = babies[uid] ?? [];
    final selected = id ?? (current.isEmpty ? 'principal' : current.first.id);
    babies[uid] = [
      SavedBaby(selected, baby),
      ...current.where((item) => item.id != selected)
    ];
    _events.add('baby/$uid');
    return selected;
  }

  @override
  Future<void> salvarPreferencia(String uid, String campo, bool valor) async {
    if (failWrites) throw StateError('write failed');
    preferences[uid] = {...?preferences[uid], campo: valor};
    _events.add('prefs/$uid');
  }

  Future<void> dispose() => _events.close();
}
