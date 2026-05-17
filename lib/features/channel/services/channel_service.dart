import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/models/comment.dart';
import '../../../core/models/media_item.dart' show LikeResponse;
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
    final contentType = _mediaContentType(mediaFileName);
    final fileSize = mediaBytes.length;

    try {
      onProgress?.call(0.03);
      final initiate = await initiateS3Upload(
        fileName: mediaFileName,
        contentType: contentType,
        mediaType: mediaType,
      );

      final chunkSize = 5 * 1024 * 1024;
      final partCount = (fileSize / chunkSize).ceil();
      final presigned = await getS3PresignedUrls(
        uploadId: initiate.uploadId,
        key: initiate.key,
        partCount: partCount,
      );

      final completedParts = <S3CompletedPart>[];
      for (final part in presigned) {
        final start = (part.partNumber - 1) * chunkSize;
        final end = start + chunkSize > fileSize ? fileSize : start + chunkSize;
        final partBytes = mediaBytes.sublist(start, end);

        final eTag = await _uploadPartToS3(
          url: part.url,
          bytes: partBytes,
          contentType: contentType,
        );

        completedParts.add(
          S3CompletedPart(partNumber: part.partNumber, eTag: eTag),
        );

        final ratio = part.partNumber / partCount;
        onProgress?.call((0.1 + (ratio * 0.85)).clamp(0.1, 0.95));
      }

      final completed = await completeS3Upload(
        uploadId: initiate.uploadId,
        key: initiate.key,
        mediaId: initiate.mediaId,
        title: title,
        description: description,
        mediaType: mediaType,
        fileSize: fileSize,
        parts: completedParts,
      );

      onProgress?.call(1.0);
      return completed;
    } catch (e) {
      debugPrint('S3 upload flow failed, trying legacy multipart upload: $e');
      return _legacyMultipartUpload(
        title: title,
        description: description,
        mediaType: mediaType,
        mediaBytes: mediaBytes,
        mediaFileName: mediaFileName,
        thumbnailBytes: thumbnailBytes,
        thumbnailFileName: thumbnailFileName,
        onProgress: onProgress,
      );
    }
  }

  /// GET /user/channel/media — list current user's channel media (paginated)
  Future<PagedResponse<UserMediaResponse>> getMyMedia({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (status != null) 'status': status,
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

  /// GET /user/channel/public/feed — global public channel feed
  Future<PagedResponse<UserMediaResponse>> getPublicFeed({
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'size': '$size'};
    final data = await _api.get(
      '/user/channel/public/feed',
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

  Future<LikeResponse> toggleMediaLike(String mediaId) async {
    final data = await _api.post('/user/channel/media/$mediaId/like');
    return LikeResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<LikeResponse> getMediaLikeStatus(String mediaId) async {
    final data = await _api.get('/user/channel/media/$mediaId/like');
    return LikeResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> recordMediaPlay(String mediaId) async {
    await _api.post('/user/channel/media/$mediaId/play');
  }

  Future<PagedResponse<Comment>> getMediaComments(
    String mediaId, {
    int page = 0,
    int size = 20,
  }) async {
    final data = await _api.get(
      '/user/channel/media/$mediaId/comments',
      queryParams: {'page': page.toString(), 'size': size.toString()},
    );

    if (data == null) {
      return PagedResponse<Comment>(
        content: const [],
        totalPages: 0,
        totalElements: 0,
        size: size,
        number: page,
      );
    }

    final json = data as Map<String, dynamic>;
    final content = (json['content'] as List<dynamic>? ?? const [])
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();

    return PagedResponse<Comment>(
      content: content,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? content.length,
      size: json['size'] as int? ?? size,
      number: json['number'] as int? ?? page,
    );
  }

  Future<bool> postMediaComment(
    String mediaId,
    String content, {
    int parentCommentId = 0,
  }) async {
    try {
      await _api.post(
        '/user/channel/media/$mediaId/comments',
        body: {'content': content, 'parentCommentId': parentCommentId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PagedResponse<Comment>> getMediaCommentReplies(
    String mediaId,
    int commentId, {
    int page = 0,
    int size = 10,
  }) async {
    final data = await _api.get(
      '/user/channel/media/$mediaId/comments/$commentId/replies',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'createdAt,asc',
      },
    );

    if (data == null) {
      return PagedResponse<Comment>(
        content: const [],
        totalPages: 0,
        totalElements: 0,
        size: size,
        number: page,
      );
    }

    final json = data as Map<String, dynamic>;
    final content = (json['content'] as List<dynamic>? ?? const [])
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();

    return PagedResponse<Comment>(
      content: content,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? content.length,
      size: json['size'] as int? ?? size,
      number: json['number'] as int? ?? page,
    );
  }

  Future<bool> deleteMediaComment(String mediaId, int commentId) async {
    try {
      await _api.delete('/user/channel/media/$mediaId/comments/$commentId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<InitiateUploadResponse> initiateS3Upload({
    required String fileName,
    required String contentType,
    required String mediaType,
  }) async {
    final data = await _api.post(
      '/user/channel/media/s3-upload/initiate',
      body: {
        'fileName': fileName,
        'contentType': contentType,
        'mediaType': mediaType,
      },
    );

    return InitiateUploadResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<List<S3PresignedPartUrl>> getS3PresignedUrls({
    required String uploadId,
    required String key,
    required int partCount,
  }) async {
    final data = await _api.post(
      '/user/channel/media/s3-upload/presigned-urls',
      body: {'uploadId': uploadId, 'key': key, 'partCount': partCount},
    );

    final items = (data as List<dynamic>)
        .map((e) => S3PresignedPartUrl.fromJson(e as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => a.partNumber.compareTo(b.partNumber));
    return items;
  }

  Future<UserMediaResponse> completeS3Upload({
    required String uploadId,
    required String key,
    required String mediaId,
    required String title,
    String? description,
    required String mediaType,
    required int fileSize,
    required List<S3CompletedPart> parts,
  }) async {
    final data = await _api.post(
      '/user/channel/media/s3-upload/complete',
      body: {
        'uploadId': uploadId,
        'key': key,
        'mediaId': mediaId,
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'mediaType': mediaType,
        'fileSize': fileSize,
        'parts': parts.map((e) => e.toJson()).toList(),
      },
    );

    return UserMediaResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> abortS3Upload({
    required String uploadId,
    required String key,
  }) async {
    await _api.post(
      '/user/channel/media/s3-upload/abort',
      body: {'uploadId': uploadId, 'key': key},
    );
  }

  Future<String> _uploadPartToS3({
    required String url,
    required List<int> bytes,
    required String contentType,
  }) async {
    final uri = Uri.parse(url);
    final response = await http.put(
      uri,
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('S3 part upload failed (${response.statusCode})');
    }

    final eTagHeader = response.headers['etag'];
    if (eTagHeader == null || eTagHeader.isEmpty) {
      throw Exception('S3 part upload missing ETag');
    }

    return eTagHeader;
  }

  Future<UserMediaResponse> _legacyMultipartUpload({
    required String title,
    String? description,
    required String mediaType,
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
