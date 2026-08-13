// Renders a single AdSense display unit on web.
//
// Resolves to a no-op widget everywhere else, so callers can use it without
// `kIsWeb` branches of their own.
export 'adsense_ad_unit_stub.dart'
    if (dart.library.js_interop) 'adsense_ad_unit_web.dart';
