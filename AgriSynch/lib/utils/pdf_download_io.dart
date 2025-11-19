import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Saves [bytes] to a temporary file named [filename].
/// Returns the file path on success.
Future<String?> savePdfBytes(String filename, Uint8List bytes) async {
  Directory dir;
  try {
    dir = await getTemporaryDirectory();
  } catch (_) {
    dir = Directory.systemTemp;
  }

  final file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
