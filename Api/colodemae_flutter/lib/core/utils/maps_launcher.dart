import 'package:url_launcher/url_launcher.dart';

/// Abre o app/site de mapas do dispositivo com a rota até [address].
Future<void> openMapsDirections(String address) async {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': address,
  });
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
