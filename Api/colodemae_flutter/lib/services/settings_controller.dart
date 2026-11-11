import 'dart:async';
import 'package:flutter/foundation.dart';
import 'account_settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required this.uid, required this.service}) {
    _loadProfile();
    _loadPreferences();
  }

  final String uid;
  final AccountSettingsService service;
  StreamSubscription<Map<String, dynamic>?>? _profileSub;
  StreamSubscription<Map<String, dynamic>?>? _prefsSub;
  bool _disposed = false;
  Map<String, dynamic>? profile;
  Map<String, dynamic> _saved = {};
  final Map<String, ({int version, bool value})> _pending = {};
  int _version = 0;
  Future<void> _writes = Future.value();
  Object? profileError;
  Object? preferencesError;
  Completer<void> _ready = Completer<void>();

  bool get educationalReminders => _value('lembretesEducativos');
  bool get fifteenDayChallenge => _value('desafio15Dias');
  bool _value(String key) =>
      _pending[key]?.value ?? _saved[key] as bool? ?? true;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _loadProfile() {
    try {
      _profileSub = service.perfil(uid).listen((data) {
        if (_disposed) return;
        profile = data;
        profileError = null;
        _notify();
      }, onError: (Object error) {
        profileError = error;
        _notify();
      });
    } catch (error) {
      profileError = error;
    }
  }

  void _loadPreferences() {
    _prefsSub?.cancel();
    _ready = Completer<void>();
    void failed(Object error) {
      if (_disposed) return;
      preferencesError = error;
      if (!_ready.isCompleted) _ready.complete();
      _notify();
    }

    try {
      _prefsSub = service.preferencias(uid).listen((data) {
        if (_disposed) return;
        _saved = Map<String, dynamic>.from(data ?? {});
        preferencesError = null;
        if (!_ready.isCompleted) _ready.complete();
        _notify();
      }, onError: failed);
    } catch (error) {
      failed(error);
    }
  }

  Future<void> setPreference(String key, bool value) async {
    if (preferencesError != null) _loadPreferences();
    final version = ++_version;
    _pending[key] = (version: version, value: value);
    _notify();
    try {
      final write = _writes.then((_) async {
        await _ready.future;
        if (_disposed) return;
        if (preferencesError != null) {
          throw StateError('Não foi possível carregar suas preferências.');
        }
        // Mantém a ordem de toques rápidos e preserva os demais campos.
        await service.salvarPreferencia(uid, key, value);
      });
      _writes = write.then<void>((_) {}, onError: (Object _, StackTrace __) {});
      await write;
      if (_disposed) return;
      if (_pending[key]?.version == version) _saved[key] = value;
    } finally {
      if (_pending[key]?.version == version) _pending.remove(key);
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _profileSub?.cancel();
    _prefsSub?.cancel();
    if (!_ready.isCompleted) _ready.complete();
    super.dispose();
  }
}
