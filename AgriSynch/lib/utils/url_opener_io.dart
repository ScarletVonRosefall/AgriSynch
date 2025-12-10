import 'package:url_launcher/url_launcher.dart';

Future<bool> openUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    return false;
  }
}
