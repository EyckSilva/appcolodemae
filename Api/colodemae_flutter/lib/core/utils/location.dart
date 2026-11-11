import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class AppLocationServiceDisabledException implements Exception {}

class AppLocationPermissionDeniedException implements Exception {}

class AppLocationPermissionDeniedForeverException implements Exception {}

class AppCoordinates {
  const AppCoordinates(this.latitude, this.longitude);
  final double latitude, longitude;
}

abstract class LocationGateway {
  Future<bool> serviceEnabled();
  Future<LocationPermission> permission();
  Future<LocationPermission> requestPermission();
  Future<AppCoordinates> position();
}

class GeolocatorGateway implements LocationGateway {
  AppCoordinates? _permissionPosition;
  @override
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();
  @override
  Future<LocationPermission> permission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() async {
    if (!kIsWeb) return Geolocator.requestPermission();
    // geolocator_web.requestPermission() usa getCurrentPosition sem timeout.
    // A posição temporária evita repetir a aquisição após obter consentimento.
    try {
      _permissionPosition = await position();
      return LocationPermission.whileInUse;
    } on PermissionDeniedException {
      return LocationPermission.denied;
    }
  }

  @override
  Future<AppCoordinates> position() async {
    final cached = _permissionPosition;
    _permissionPosition = null;
    if (cached != null) return cached;
    final value = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20)));
    return AppCoordinates(value.latitude, value.longitude);
  }
}

class AppLocationService {
  AppLocationService({
    LocationGateway? gateway,
    this.operationTimeout = const Duration(seconds: 5),
    this.permissionTimeout = const Duration(seconds: 25),
    this.positionTimeout = const Duration(seconds: 22),
  }) : _gateway = gateway ?? GeolocatorGateway();
  final LocationGateway _gateway;
  final Duration operationTimeout, permissionTimeout, positionTimeout;

  Future<AppCoordinates> currentPosition() async {
    if (!await _gateway.serviceEnabled().timeout(operationTimeout)) {
      throw AppLocationServiceDisabledException();
    }
    var permission = await _gateway.permission().timeout(operationTimeout);
    if (permission == LocationPermission.denied) {
      permission =
          await _gateway.requestPermission().timeout(permissionTimeout);
    }
    if (permission == LocationPermission.deniedForever) {
      throw AppLocationPermissionDeniedForeverException();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw AppLocationPermissionDeniedException();
    }
    final coordinates = await _gateway.position().timeout(positionTimeout);
    if (!coordinates.latitude.isFinite ||
        !coordinates.longitude.isFinite ||
        coordinates.latitude.abs() > 90 ||
        coordinates.longitude.abs() > 180) {
      throw StateError(
          'Não foi possível obter uma localização válida. Tente novamente.');
    }
    return coordinates;
  }
}
