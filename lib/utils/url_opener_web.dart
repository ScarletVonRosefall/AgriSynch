import 'dart:html' as html;

Future<bool> openUrl(String url) async {
  try {
    html.window.open(url, '_blank');
    return true;
  } catch (e) {
    return false;
  }
}
