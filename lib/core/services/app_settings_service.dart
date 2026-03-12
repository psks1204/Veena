import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// App Settings Service
///
/// Fetches global app settings from /api/settings (authenticated).
/// Used to check maintenance mode and minimum app version.
class AppSettingsService extends ChangeNotifier {
  final ApiService _api;

  bool _maintenanceMode = false;
  String _minimumAppVersion = '2.0.0';
  bool _isLoading = false;
  bool _hasLoaded = false;

  bool get maintenanceMode => _maintenanceMode;
  String get minimumAppVersion => _minimumAppVersion;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  AppSettingsService(this._api);

  /// Current app version — must match pubspec.yaml version
  static const String currentAppVersion = '2.0.1';

  /// Fetch settings from the authenticated API
  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/settings');
      debugPrint('⚙️ Settings response: $data');

      if (data != null) {
        _maintenanceMode = data['maintenanceMode'] ?? false;
        _minimumAppVersion = data['minimumAppVersion'] ?? '2.0.1';
        debugPrint('🔧 maintenanceMode: $_maintenanceMode');
        debugPrint(
          '📱 minimumAppVersion: $_minimumAppVersion (current: $currentAppVersion)',
        );
      }

      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Settings fetch error: $e');
      // Don't block the app on settings error — default to safe values
      _maintenanceMode = false;
      _minimumAppVersion = '2.0.1';
      _isLoading = false;
      _hasLoaded = true;
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
