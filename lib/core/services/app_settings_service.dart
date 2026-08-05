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
  bool _enableComments = true;
  bool _enableUserNotifications = true;
  bool _defaultAutoplayForUsers = true;
  bool _allowUserDownloads = false;
  bool _isLoading = false;
  bool _hasLoaded = false;

  bool get maintenanceMode => _maintenanceMode;
  String get minimumAppVersion => _minimumAppVersion;
  // Until settings are fetched, keep comments enabled so delayed responses
  // do not incorrectly block comment entry points.
  bool get enableComments => !_hasLoaded ? true : _enableComments;
  bool get enableUserNotifications => _enableUserNotifications;
  bool get defaultAutoplayForUsers => _defaultAutoplayForUsers;
  bool get allowUserDownloads => _allowUserDownloads;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  AppSettingsService(this._api);

  /// Current app version — must match pubspec.yaml version
  static const String currentAppVersion = '2.0.3';

  /// Fetch settings from the authenticated API
  Future<void> fetchSettings() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/settings');
      final settings = _extractSettingsMap(data);
      debugPrint('⚙️ Settings response (normalized): $settings');

      if (settings != null) {
        _maintenanceMode = _readBool(settings, const [
          'maintenanceMode',
          'maintenance_mode',
        ], fallback: _maintenanceMode);

        final minimumVersionRaw =
            settings['minimumAppVersion'] ?? settings['minimum_app_version'];
        if (minimumVersionRaw != null &&
            minimumVersionRaw.toString().isNotEmpty) {
          _minimumAppVersion = minimumVersionRaw.toString();
        }

        _enableComments = _readBool(settings, const [
          'enableComments',
          'enable_comments',
        ], fallback: _enableComments);

        _enableUserNotifications = _readBool(settings, const [
          'enableUserNotifications',
          'enable_user_notifications',
        ], fallback: _enableUserNotifications);

        _defaultAutoplayForUsers = _readBool(settings, const [
          'defaultAutoplayForUsers',
          'default_autoplay_for_users',
        ], fallback: _defaultAutoplayForUsers);

        _allowUserDownloads = _readBool(settings, const [
          'allowUserDownloads',
          'allow_user_downloads',
        ], fallback: _allowUserDownloads);

        debugPrint('🔧 maintenanceMode: $_maintenanceMode');
        debugPrint('💬 enableComments: $_enableComments');
        debugPrint(
          '📱 minimumAppVersion: $_minimumAppVersion (current: $currentAppVersion)',
        );
      }
    } catch (e) {
      debugPrint('❌ Settings fetch error: $e');
      // Keep last-known values to avoid toggling features off on transient failures.
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _extractSettingsMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
      }
      return data;
    }

    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }

    return null;
  }

  bool _readBool(
    Map<String, dynamic> json,
    List<String> keys, {
    required bool fallback,
  }) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;

      final raw = json[key];
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }

    return fallback;
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
    while (aParts.length < 3) {
      aParts.add(0);
    }
    while (bParts.length < 3) {
      bParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (aParts[i] < bParts[i]) return -1;
      if (aParts[i] > bParts[i]) return 1;
    }
    return 0;
  }
}
