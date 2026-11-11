import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri, LaunchMode mode);
Future<bool> launchExternalUrl(Uri uri, LaunchMode mode) =>
    launchUrl(uri, mode: mode);

class ExternalLinkException implements Exception {
  const ExternalLinkException();
}
