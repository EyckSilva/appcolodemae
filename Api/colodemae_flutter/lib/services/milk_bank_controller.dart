import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/location.dart';
import '../models/milk_bank.dart';
import 'milk_bank_repository.dart';
import 'blh_city_resolver.dart';
import 'blh_demo_repository.dart';
import 'blh_distance.dart';

class MilkBankController extends ChangeNotifier {
  MilkBankController(
      {required this.repository,
      required this.location,
      this.demoMode = false,
      BlhCityResolver? cityResolver,
      this.locationTimeout = const Duration(seconds: 50),
      this.reverseTimeout = const Duration(seconds: 5),
      this.queryTimeout = const Duration(seconds: 26)})
      : cityResolver = cityResolver ?? AracajuCityResolver();
  final MilkBankRepository repository;
  final AppLocationService location;
  final bool demoMode;
  final BlhCityResolver cityResolver;
  AppCoordinates? _position;
  final Duration locationTimeout, reverseTimeout, queryTimeout;
  List<MilkBankResult> results = [];
  bool busy = false, locating = false, located = false, searched = false;
  String? error;
  String? city, state;
  Object? _cursor;
  bool get hasMore => _cursor != null;
  bool _disposed = false;
  bool _retryLocation = false;
  int _request = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _queryError(Object failure) {
    if (failure is FirebaseException &&
        const ['unavailable', 'deadline-exceeded', 'network-request-failed']
            .contains(failure.code)) {
      return 'Não foi possível consultar as unidades. Verifique sua conexão e tente novamente.';
    }
    return 'A busca está temporariamente indisponível. Tente novamente em alguns instantes.';
  }

  Future<void> locate() async {
    if (_disposed || busy) return;
    final request = ++_request;
    busy = locating = true;
    located = false;
    searched = true;
    error = null;
    _retryLocation = true;
    results = [];
    _cursor = null;
    city = state = null;
    _position = null;
    _notify();
    try {
      final position =
          await location.currentPosition().timeout(locationTimeout);
      if (_disposed || request != _request) return;
      locating = false;
      located = true;
      _notify();
      _position = position;
      final municipality =
          await cityResolver.resolve(position).timeout(reverseTimeout);
      if (_disposed || request != _request) return;
      city = municipality.city.trim();
      state = normalizeBlhState(municipality.state);
      final page = await repository.byCity(city!, state!).timeout(queryTimeout);
      if (_disposed || request != _request) return;
      _cursor = page.cursor;
      results = withBlhDistances(page.banks, _position);
    } catch (failure) {
      if (_disposed || request != _request) return;
      error = switch (failure) {
        AppLocationServiceDisabledException() =>
          'Ative o GPS e tente novamente.',
        AppLocationPermissionDeniedForeverException() =>
          'Localização bloqueada. Habilite a permissão nas configurações.',
        AppLocationPermissionDeniedException() =>
          'Permissão de localização negada. Permita o acesso e tente novamente.',
        TimeoutException() =>
          'A localização ou consulta demorou mais que o esperado. Tente novamente.',
        FirebaseException() => _queryError(failure),
        StateError() => failure.message.toString(),
        _ => 'Não foi possível concluir a busca. Tente novamente.',
      };
    } finally {
      if (!_disposed && request == _request) {
        busy = locating = false;
        _notify();
      }
    }
  }

  Future<void> searchCity(String city, String state,
      {bool more = false}) async {
    if (_disposed || busy) return;
    final request = ++_request;
    this.city = city;
    this.state = state;
    busy = true;
    locating = located = false;
    searched = true;
    _retryLocation = false;
    error = null;
    if (!more) {
      results = [];
      _cursor = null;
    }
    _notify();
    try {
      final page = await repository
          .byCity(city, state, cursor: more ? _cursor : null)
          .timeout(queryTimeout);
      if (_disposed || request != _request) return;
      final unique = {
        for (final entry in results) entry.bank.id: entry,
        for (final entry in withBlhDistances(page.banks, _position))
          entry.bank.id: entry
      };
      results = unique.values.toList();
      _cursor = page.cursor;
    } catch (failure) {
      if (!_disposed && request == _request) {
        error = _queryError(failure);
      }
    } finally {
      if (!_disposed && request == _request) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> retry() =>
      _retryLocation || city == null ? locate() : searchCity(city!, state!);

  /// Somente posições já autorizadas pelo fluxo de localização. Nenhum I/O.
  void updateLocation(AppCoordinates position) {
    if (_disposed) return;
    _position = position;
    results = withBlhDistances(results.map((r) => r.bank), _position);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    results = [];
    _position = null;
    super.dispose();
  }
}
