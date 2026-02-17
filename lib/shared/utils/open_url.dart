// Conditional import entry point
// On web: uses dart:html window.open() (synchronous, no popup blocker)
// On mobile: uses url_launcher
export 'open_url_stub.dart' if (dart.library.html) 'open_url_web.dart';
