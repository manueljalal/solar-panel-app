import 'package:url_launcher/url_launcher.dart';

/// Public legal pages (served by the vendor portal's hosting site).
class LegalLinks {
  LegalLinks._();

  static final privacy = Uri.parse('https://solary-vendor-dev.web.app/privacy');
  static final terms = Uri.parse('https://solary-vendor-dev.web.app/terms');

  static Future<void> open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}
