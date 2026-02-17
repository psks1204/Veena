// Web implementation - uses dart:html for synchronous window.open()
// This avoids popup blocker issues caused by async url_launcher
import 'dart:html' as html;

void openUrl(String url) {
  html.window.open(url, '_blank');
}
