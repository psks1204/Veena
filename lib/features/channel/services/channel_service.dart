import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/channel.dart';
import '../../../core/models/paged_response.dart';

/// Channel Service
///
/// Wraps all /api/user/channel/* endpoints from UserChannelController.
class ChannelService {
  final ApiService _api;

  ChannelService(this._api);

  /// GET /user/channel — get or auto-create the current user's channel
  Future<ChannelResponse> getOrCreateChannel() async {
    final data = await _api.get('/user/channel');
    return ChannelResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /user/channel — create channel (idempotent; returns existing if one exists)
  Future<ChannelResponse> createChannel({
    String? channelName,
    String? channelHandle,
    String? description,
  }) async {
    final body = <String, dynamic>{
      if (channelName != null) 'channelName': channelName,
      if (channelHandle != null) 'channelHandle': channelHandle,
      if (description != null) 'description': description,
    };
    final data = await _api.post('/user/channel', body: body);
    return ChannelResponse.fromJson(data as Map<String, dynamic>);
  }

  /// PUT /user/channel — update channel details
  Future<ChannelResponse> updateChannel({
    String? channelName,
    String? channelHandle,
    String? description,
  }) async {
    final body = <String, dynamic>{
      if (channelName != null) 'channelName': channelName,
      if (channelHandle != null) 'channelHandle': channelHandle,
      if (description != null) 'description': description,
    };
    final data = await _api.put('/user/channel', body: body);
    return ChannelResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /user/channel/image — upload channel image (multipart)
  Future<ChannelResponse> uploadChannelImage({
    String? filePath,
    List<int>? bytes,
    String? fileName,
  }) async {
    dynamic data;
    if (filePath != null && !kIsWeb) {
      data = await _api.multipartPost(
        '/user/channel/image',
        filePath: filePath,
        fieldName: 'file',
        contentType: _imageContentType(filePath),
      );
    } else if (bytes != null) {
      final name = fileName ?? 'image.jpg';
      data = await _api.multipartPostBytes(
        '/user/channel/image',
        bytes: bytes,
        fieldName: 'file',
        fileName: name,
        contentType: _imageContentType(name),
      );
    }
    return ChannelResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /user/channel/media/upload — upload media (multipart with fields + progress)
  Future<UserMediaResponse> uploadMedia({
    required String title,
    String? description,
    required String mediaType, // 'AUDIO' or 'VIDEO'
    required String mediaFilePath,
    required List<int> mediaBytes,
    required String mediaFileName,
    List<int>? thumbnailBytes,
    String? thumbnailFileName,
    void Function(double progress)? onProgress,
  }) async {
    final fields = <String, String>{
      'title': title,
      'mediaType': mediaType,
      if (description != null && description.isNotEmpty)
        'description': description,
    };

    final files = <MultipartFileData>[
      MultipartFileData(
        fieldName: 'file',
        bytes: mediaBytes,
        fileName: mediaFileName,
        contentType: _mediaContentType(mediaFileName),
      ),
      if (thumbnailBytes != null)
        MultipartFileData(
          fieldName: 'thumbnail',
          bytes: thumbnailBytes,
          fileName: thumbnailFileName ?? 'thumbnail.jpg',
          contentType: 'image/jpeg',
        ),
    ];

    final data = await _api.multipartPostWithFieldsAndProgress(
      '/user/channel/media/upload',
      fields: fields,
      files: files,
      onProgress: onProgress,
    );

    return UserMediaResponse.fromJson(data as Map<String, dynamic>);
  }

  /// GET /user/channel/media — list current user's channel media (paginated)
  Future<PagedResponse<UserMediaResponse>> getMyMedia({
    String? approvalStatus,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (approvalStatus != null) 'status': approvalStatus,
    };
    final data = await _api.get('/user/channel/media', queryParams: params);
    final json = data as Map<String, dynamic>;
    final content = (json['content'] as List<dynamic>)
        .map((e) => UserMediaResponse.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedResponse<UserMediaResponse>(
      content: content,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? content.length,
      size: json['size'] as int? ?? size,
      number: json['number'] as int? ?? page,
    );
  }

  /// DELETE /user/channel/media/{mediaId} — delete media
  Future<void> deleteMedia(String mediaId) async {
    await _api.delete('/user/channel/media/$mediaId');
  }

  /// GET /user/channel/public/{channelId} — public channel view
  Future<ChannelResponse> getPublicChannel(String channelId) async {
    final data = await _api.get('/user/channel/public/$channelId');
    return ChannelResponse.fromJson(data as Map<String, dynamic>);
  }

  /// GET /user/channel/public/{channelId}/media — public channel media
  Future<PagedResponse<UserMediaResponse>> getPublicChannelMedia(
    String channelId, {
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'size': '$size'};
    final data = await _api.get(
      '/user/channel/public/$channelId/media',
      queryParams: params,
    );
    final json = data as Map<String, dynamic>;
    final content = (json['content'] as List<dynamic>)
        .map((e) => UserMediaResponse.fromJson(e as Map<String, dynamic>))
        .toList();
    return PagedResponse<UserMediaResponse>(
      content: content,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? content.length,
      size: json['size'] as int? ?? size,
      number: json['number'] as int? ?? page,
    );
  }

  String _imageContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _mediaContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.avi')) return 'video/avi';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a')) return 'audio/m4a';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.flac')) return 'audio/flac';
    return 'application/octet-stream';
  }
}

/// Helper data class for multipart file entries
class MultipartFileData {
  final String fieldName;
  final List<int> bytes;
  final String fileName;
  final String? contentType;

  const MultipartFileData({
    required this.fieldName,
    required this.bytes,
    required this.fileName,
    this.contentType,
  });
}
