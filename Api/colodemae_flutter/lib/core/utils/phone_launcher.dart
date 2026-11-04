import 'package:url_launcher/url_launcher.dart';

/// Abre o discador do dispositivo com o número já preenchido.
Future<void> callPhone(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  await launchUrl(Uri(scheme: 'tel', path: digits));
}
