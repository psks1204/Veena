import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/location_service.dart';

/// Profile Provider
///
/// Manages user profile state and interactions with the Profile API.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  ProfileProvider(this._service);

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  bool _needsNameSetup = false;
  bool _hasInitialized = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  /// True if profile was fetched but has no name — first-login flow
  bool get needsNameSetup => _needsNameSetup;

  /// True if the first-login initialization has already been called
  bool get hasInitialized => _hasInitialized;

  /// Called once after login. Fetches existing profile; conditionally updates
  /// with location + google name if meaningful data is available.
  Future<void> initializeOnLogin({
    required String? googleName,
    required String? googleEmail,
  }) async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1) Fetch existing profile first to avoid overwriting data
      try {
        _profile = await _service.getProfile();
      } catch (e) {
        debugPrint('⚠️ Fetch profile failed during init: $e');
      }

      // 2) Determine the name to use — never send an empty string to the API
      final existingName = _profile?.name?.trim();
      final hasValidExistingName =
          existingName != null && existingName.isNotEmpty;

      // Only update if we have a real Google name and the profile doesn't have one yet
      final nameToSend =
          (!hasValidExistingName &&
              googleName != null &&
              googleName.trim().isNotEmpty)
          ? googleName.trim()
          : null;

      // 3) Get device location (best-effort, skip if unavailable)
      double? lat;
      double? lng;
      try {
        final position = await _getDeviceLocation();
        if (position != null) {
          lat = position.$1;
          lng = position.$2;
        }
      } catch (e) {
        debugPrint('📍 Location not available: $e');
      }

      // 4) Only call PUT if we have something worth updating AND a valid name
      // Always need a non-empty name to pass API validation
      final effectiveName = nameToSend ?? existingName ?? '';
      final shouldUpdate =
          effectiveName.isNotEmpty && (nameToSend != null || lat != null);
      if (shouldUpdate) {
        try {
          await _service.updateProfile(
            name: effectiveName,
            birthDate: _buildBirthDateString(_profile?.birthDate),
            latitude: lat ?? _profile?.latitude,
            longitude: lng ?? _profile?.longitude,
          );
          // 5) Re-fetch after update
          _profile = await _service.getProfile();
        } catch (e) {
          debugPrint('⚠️ Profile update failed (non-fatal): $e');
          // Not fatal — use whatever profile data we already have
        }
      }

      // 6) Check if user still needs to set up name
      _needsNameSetup =
          _profile?.name == null || _profile!.name!.trim().isEmpty;
      _error = null;
    } catch (e) {
      debugPrint('❌ ProfileProvider.initializeOnLogin: $e');
      _error = e.toString();
      if (_profile == null) {
        try {
          _profile = await _service.getProfile();
        } catch (_) {}
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _buildBirthDateString(DateTime? date) {
    if (date == null) return null;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Reset provider state for sign-out so the next sign-in initialises fresh.
  void resetForSignOut() {
    _profile = null;
    _hasInitialized = false;
    _needsNameSetup = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Get device location - returns (lat, lng) or null
  Future<(double, double)?> _getDeviceLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      if (position != null) {
        debugPrint(
          '📍 Location fetched: ${position.latitude}, ${position.longitude}',
        );
        return (position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
    return null;
  }

  /// Fetch profile from API
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.getProfile();
      _error = null;
    } catch (e) {
      debugPrint('❌ ProfileProvider.fetchProfile: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark name setup as done (user saved or skipped)
  void markNameSetupDone() {
    _needsNameSetup = false;
    notifyListeners();
  }

  /// Update profile fields
  Future<bool> updateProfile({
    required String name,
    DateTime? birthDate,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dateStr = birthDate != null
          ? '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}'
          : '';

      await _service.updateProfile(
        name: name,
        birthDate: dateStr,
        latitude: latitude ?? _profile?.latitude,
        longitude: longitude ?? _profile?.longitude,
      );

      // Refresh profile data after update
      await fetchProfile();
      return true;
    } catch (e) {
      debugPrint('❌ ProfileProvider.updateProfile: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile photo from picker
  Future<bool> uploadPhoto(XFile image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await _service.uploadPhoto(bytes: bytes, fileName: image.name);
      } else {
        await _service.uploadPhoto(filePath: image.path);
      }

      // Refresh profile to get new photo URL
      await fetchProfile();
      return true;
    } catch (e) {
      debugPrint('❌ ProfileProvider.uploadPhoto: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete profile photo
  Future<bool> deletePhoto() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deletePhoto();
      // Update local state
      if (_profile != null) {
        _profile = _profile!.copyWith(clearPhoto: true);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ ProfileProvider.deletePhoto: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear local profile data (on logout)
  void clearProfile() {
    _profile = null;
    _error = null;
    _isLoading = false;
    _needsNameSetup = false;
    _hasInitialized = false;
    notifyListeners();
  }
}
