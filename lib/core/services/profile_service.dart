import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/user_profile.dart';

/// Profile Service
///
/// Handles all profile-related API calls.
class ProfileService {
  final ApiService _api;

  ProfileService(this._api);

  /// GET /api/profile - Fetch current user profile
  Future<UserProfile> getProfile() async {
    try {
      final data = await _api.get('/profile');
      if (data == null) {
        throw ApiException('Empty profile response', 200);
      }
      return UserProfile.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ getProfile error: $e');
      rethrow;
    }
  }

  /// PUT /api/profile - Update profile fields
  Future<UserProfile> updateProfile({
    required String name,
    String? birthDate,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'birthDate': birthDate ?? '',
        'latitude': latitude ?? 0,
        'longitude': longitude ?? 0,
      };
      final data = await _api.put('/profile', body: body);
      if (data == null) {
        // PUT may not return body; fetch fresh
        return getProfile();
      }
      return UserProfile.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ updateProfile error: $e');
      rethrow;
    }
  }

  /// POST /api/profile/photo - Upload profile photo
  /// Uses multipart for mobile (file path) and bytes for web
  Future<void> uploadPhoto({
    String? filePath,
    List<int>? bytes,
    String? fileName,
  }) async {
    try {
      if (filePath != null && !kIsWeb) {
        final contentType = _getContentType(filePath);
        await _api.multipartPost(
          '/profile/photo',
          filePath: filePath,
          fieldName: 'file',
          contentType: contentType,
        );
      } else if (bytes != null) {
        final name = fileName ?? 'photo.jpg';
        final contentType = _getContentType(name);
        await _api.multipartPostBytes(
          '/profile/photo',
          bytes: bytes,
          fieldName: 'file',
          fileName: name,
          contentType: contentType,
        );
      }
    } catch (e) {
      debugPrint('❌ uploadPhoto error: $e');
      rethrow;
    }
  }
  
  String _getContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/jpeg';
  }

  /// DELETE /api/profile/photo - Remove profile photo
  Future<void> deletePhoto() async {
    try {
      await _api.delete('/profile/photo');
    } catch (e) {
      debugPrint('❌ deletePhoto error: $e');
      rethrow;
    }
  }
}
