import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

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

  /// Called once after login. Sends location + Google name via PUT, then fetches profile.
  /// Returns true if the user needs to set up their name (first login).
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
        // If fetch fails (e.g. 404), we might be creating a new profile
        debugPrint('⚠️ Fetch profile failed during init (expected for new users): $e');
      }

      // 2) Determine values to use (preserve existing if available)
      String nameToUse = googleName ?? '';
      if (_profile?.name != null && _profile!.name!.trim().isNotEmpty) {
        nameToUse = _profile!.name!;
      }
      
      String birthDateToUse = '';
      if (_profile?.birthDate != null) {
        final d = _profile!.birthDate!;
        birthDateToUse = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      // 3) Get device location (best-effort)
      double lat = _profile?.latitude ?? 0;
      double lng = _profile?.longitude ?? 0;
      
      try {
        final position = await _getDeviceLocation();
        if (position != null) {
          lat = position.$1;
          lng = position.$2;
        }
      } catch (e) {
        debugPrint('📍 Location not available: $e');
      }

      // 4) Update profile with merged data
      await _service.updateProfile(
         name: nameToUse,
         birthDate: birthDateToUse,
         latitude: lat,
         longitude: lng,
      );

      // 5) Refresh profile to ensure we have the latest
      _profile = await _service.getProfile();

      // 6) Check if user still needs to set up name
      _needsNameSetup = _profile?.name == null || _profile!.name!.trim().isEmpty;

      _error = null;
    } catch (e) {
      debugPrint('❌ ProfileProvider.initializeOnLogin: $e');
      _error = e.toString();
      // Even on error, try to guarantee profile state is acceptable
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

  /// Get device location - returns (lat, lng) or null
  Future<(double, double)?> _getDeviceLocation() async {
    // Use platform-agnostic approach: 
    // On web, we can't easily get location without geolocator.
    // For now, return null (location = 0,0 means not set).
    // The geolocator package can be added later for actual GPS.
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
        await _service.uploadPhoto(
          bytes: bytes,
          fileName: image.name,
        );
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
