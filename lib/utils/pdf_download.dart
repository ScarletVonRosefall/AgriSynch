// Cross-platform PDF download/save helper.
// Exports platform-specific implementations using conditional export.

export 'pdf_download_io.dart' if (dart.library.html) 'pdf_download_web.dart';
