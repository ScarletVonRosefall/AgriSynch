// Conditional export: uses web implementation when compiled to web, otherwise IO implementation.
export 'url_opener_io.dart' if (dart.library.html) 'url_opener_web.dart';
