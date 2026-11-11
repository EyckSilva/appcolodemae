import 'package:url_launcher/url_launcher.dart';
import 'external_links.dart';

/// Abre o discador do dispositivo com o número já preenchido.
Future<void> callPhone(String phone,
    {ExternalUrlLauncher launcher = launchExternalUrl}) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(digits)) {
    throw ArgumentError('Telefone inválido.');
  }
  if (!await launcher(
      Uri(scheme: 'tel', path: digits), LaunchMode.platformDefault)) {
    throw const ExternalLinkException();
  }
}
