import 'package:url_launcher/url_launcher.dart';
import 'external_links.dart';

Future<void> openMapsAddressDirections(String address,
    {ExternalUrlLauncher launcher = launchExternalUrl}) async {
  if (address.trim().isEmpty) {
    throw ArgumentError('Endereço de destino ausente.');
  }
  final uri = Uri.https(
      'www.google.com', '/maps/dir/', {'api': '1', 'destination': address});
  if (!await launcher(uri, LaunchMode.externalApplication)) {
    throw const ExternalLinkException();
  }
}

/// O app de mapas escolhe a origem; coordenadas pessoais não são enviadas aqui.
Future<void> openMapsDirections(
    {required double latitude,
    required double longitude,
    ExternalUrlLauncher launcher = launchExternalUrl}) async {
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180) {
    throw ArgumentError('Destino inválido.');
  }
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
  });
  if (!await launcher(uri, LaunchMode.externalApplication)) {
    throw const ExternalLinkException();
  }
}
