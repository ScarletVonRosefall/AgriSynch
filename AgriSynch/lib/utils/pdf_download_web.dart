import 'dart:typed_data';
import 'dart:html' as html;

/// Triggers a browser download for the given [bytes] using [filename].
/// Returns null (no file path available on web).
Future<String?> savePdfBytes(String filename, Uint8List bytes) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return null;
}
