import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// App Settings Service
///
/// Fetches global app settings from /api/settings (public, no auth).
/// Used to check maintenance mode and minimum app version.
class AppSettingsService extends ChangeNotifier {
  bool _maintenanceMode = false;
  String _minimumAppVersion = '1.0.0';
  bool _isLoading = true;
  bool _hasError = false;

  bool get maintenanceMode => _maintenanceMode;
  String get minimumAppVersion => _minimumAppVersion;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  /// Current app version — must match pubspec.yaml version
  static const String currentAppVersion = '1.0.0';

  /// Fetch settings from the public API
  Future<void> fetchSettings() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/settings');
      debugPrint('⚙️ GET: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📥 Settings Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data != null) {
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _minimumAppVersion = data['minimumAppVersion'] ?? '1.0.0';
        }
      } else {
        debugPrint('Settings fetch failed: ${response.statusCode}');
        // Don't block the app on settings error — default to safe values
        _maintenanceMode = false;
        _minimumAppVersion = '1.0.0';
      }

      _isLoading = false;
      _hasError = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Settings fetch error: $e');
      // Don't block the app on network error
      _maintenanceMode = false;
      _minimumAppVersion = '1.0.0';
      _isLoading = false;
      _hasError = false;
      notifyListeners();
    }
  }

  /// Compare version strings (e.g. "1.2.3" vs "1.3.0")
  /// Returns true if current app version is below the minimum
  bool get isAppOutdated {
    return _compareVersions(currentAppVersion, _minimumAppVersion) < 0;
  }

  /// Compare two semantic version strings.
  /// Returns negative if a < b, 0 if equal, positive if a > b
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to same length
    while (aParts.length < 3) aParts.add(0);
    while (bParts.length < 3) bParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (aParts[i] < bParts[i]) return -1;
      if (aParts[i] > bParts[i]) return 1;
    }
    return 0;
  }
}
