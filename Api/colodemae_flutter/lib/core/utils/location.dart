import 'package:geolocator/geolocator.dart';

/// O serviço de localização do dispositivo está desativado.
class AppLocationServiceDisabledException implements Exception {}

/// O usuário negou a permissão de localização.
class AppLocationPermissionDeniedException implements Exception {}

/// Resolve a posição atual do dispositivo, cuidando da checagem de serviço e
/// da solicitação de permissão. Lança uma exceção tipada quando a localização
/// não está disponível, para que a tela possa mostrar uma mensagem adequada.
Future<Position> resolveCurrentPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw AppLocationServiceDisabledException();
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw AppLocationPermissionDeniedException();
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
  );
}
