import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/baby.dart';
import 'account_settings_service.dart';

/// Controlador isolado por sessão; compartilha o bebê entre início e configurações.
class BabyController extends ChangeNotifier {
  BabyController({required this.uid, required this.service}) {
    _load();
  }

  final String uid;
  final AccountSettingsService service;
  StreamSubscription<List<SavedBaby>>? _subscription;
  Completer<void> _ready = Completer<void>();
  bool _disposed = false;
  Baby? _baby;
  String? _id;
  Baby? get baby => _baby;
  Object? error;

  void _load() {
    _subscription?.cancel();
    _ready = Completer<void>();
    try {
      _subscription = service.bebes(uid).listen((babies) {
        if (_disposed) return;
        _baby = babies.isEmpty ? null : babies.first.baby;
        _id = babies.isEmpty ? null : babies.first.id;
        error = null;
        if (!_ready.isCompleted) _ready.complete();
        notifyListeners();
      }, onError: _failed);
    } catch (failure) {
      _failed(failure);
    }
  }

  void _failed(Object failure) {
    if (_disposed) return;
    error = failure;
    if (!_ready.isCompleted) _ready.complete();
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (error != null) _load();
    await _ready.future;
    if (_disposed) return;
    if (error != null) {
      throw StateError('Não foi possível carregar os dados do bebê.');
    }
  }

  Future<void> update(Baby value) async {
    await ensureLoaded();
    if (_disposed) return;
    final id = await service.salvarBebe(uid, value, id: _id);
    if (_disposed) return;
    _id = id;
    _baby = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    if (!_ready.isCompleted) _ready.complete();
    super.dispose();
  }
}
