import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_download_models.dart';
import '../models/media_item.dart';
import 'api_service.dart';
import 'media_download_service.dart';

MediaDownloadService createMediaDownloadService(
  ApiService api,
  SharedPreferences prefs,
) {
  return _MediaDownloadServiceIo(api, prefs);
}

class _MediaDownloadServiceIo implements MediaDownloadService {
  _MediaDownloadServiceIo(this._api, this._prefs);

  static const String _prefsKey = 'downloaded_media_records_v1';
  static const String _downloadsFolderName = 'veena_downloads';
  static const Duration _metadataTimeout = Duration(seconds: 30);
  static const Duration _downloadTimeout = Duration(minutes: 10);

  final ApiService _api;
  final SharedPreferences _prefs;

  final Map<String, DownloadedMediaRecord> _recordsById =
      <String, DownloadedMediaRecord>{};
  final Set<String> _inProgressIds = <String>{};

  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isPlatformSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final raw = _prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      final records = DownloadedMediaRecord.decodeList(raw);
      for (final record in records) {
        _recordsById[record.mediaId] = record;
      }
    }

    await _purgeMissingFiles();
    _initialized = true;
  }

  @override
  List<DownloadedMediaRecord> getAllDownloads() {
    final all = _recordsById.values.toList(growable: false);
    all.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return all;
  }

  @override
  DownloadedMediaRecord? getDownload(String mediaId) => _recordsById[mediaId];

  @override
  bool isDownloadInProgress(String mediaId) => _inProgressIds.contains(mediaId);

  @override
  Future<String?> getLocalPathIfExists(String mediaId) async {
    await initialize();
    final record = _recordsById[mediaId];
    if (record == null) return null;

    final file = File(record.localPath);
    final exists = await file.exists();
    if (!exists) {
      _recordsById.remove(mediaId);
      await _persistRecords();
      return null;
    }
    return file.path;
  }

  @override
  Future<MediaDownloadResult> downloadMedia(MediaItem media) async {
    await initialize();
    debugPrint('[DownloadService] Starting download for mediaId=${media.id}');

    if (!isPlatformSupported) {
      debugPrint(
        '[DownloadService] Platform unsupported for mediaId=${media.id}',
      );
      return const MediaDownloadResult(
        status: MediaDownloadStatus.unsupportedPlatform,
        message: 'Downloads are available on Android and iOS only.',
      );
    }

    if (_inProgressIds.contains(media.id)) {
      debugPrint('[DownloadService] Download already in progress: ${media.id}');
      return const MediaDownloadResult(
        status: MediaDownloadStatus.inProgress,
        message: 'Download already in progress.',
      );
    }

    final existingPath = await getLocalPathIfExists(media.id);
    if (existingPath != null) {
      debugPrint('[DownloadService] Media already downloaded: ${media.id}');
      return MediaDownloadResult(
        status: MediaDownloadStatus.alreadyDownloaded,
        record: _recordsById[media.id],
        message: 'Media already downloaded.',
      );
    }

    _inProgressIds.add(media.id);
    final client = http.Client();
    File? tempFile;
    try {
      final metadata = await _fetchDownloadMetadata(
        media.id,
      ).timeout(_metadataTimeout);
      if (metadata.downloadUrl.isEmpty) {
        debugPrint(
          '[DownloadService] Empty download URL for mediaId=${media.id}',
        );
        return const MediaDownloadResult(
          status: MediaDownloadStatus.failed,
          message: 'Download URL is missing.',
        );
      }

      debugPrint(
        '[DownloadService] Metadata received for ${media.id}: url=${metadata.downloadUrl}, fileSize=${metadata.fileSize}',
      );

      final downloadUri = _resolveDownloadUri(metadata.downloadUrl);
      if (downloadUri == null) {
        debugPrint(
          '[DownloadService] Invalid download URL for mediaId=${media.id}: ${metadata.downloadUrl}',
        );
        return const MediaDownloadResult(
          status: MediaDownloadStatus.failed,
          message: 'Download URL is invalid.',
        );
      }

      final headers = _buildDownloadHeaders(downloadUri);
      debugPrint(
        '[DownloadService] Requesting file for ${media.id} at $downloadUri (authHeader=${headers.containsKey('Authorization')})',
      );

      final request = http.Request('GET', downloadUri);
      request.headers.addAll(headers);
      final response = await client.send(request).timeout(_downloadTimeout);

      debugPrint(
        '[DownloadService] Response headers for ${media.id}: status=${response.statusCode}, contentLength=${response.contentLength}, contentType=${response.headers['content-type']}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final bodyPreview = await response.stream
            .transform<List<int>>(
              StreamTransformer.fromHandlers(
                handleData: (data, sink) {
                  sink.add(data);
                },
              ),
            )
            .fold<List<int>>(<int>[], (all, chunk) {
              if (all.length >= 512) return all;
              final remaining = 512 - all.length;
              all.addAll(chunk.take(remaining));
              return all;
            })
            .then((bytes) => String.fromCharCodes(bytes))
            .timeout(const Duration(seconds: 5), onTimeout: () => '');
        debugPrint(
          '[DownloadService] Download failed for ${media.id}: status=${response.statusCode}, body=$bodyPreview',
        );
        return MediaDownloadResult(
          status: MediaDownloadStatus.failed,
          message: 'Download failed (${response.statusCode}).',
        );
      }

      final downloadsDirectory = await _ensureDownloadsDirectory();
      final extension = _resolveFileExtension(
        media: media,
        downloadUri: downloadUri,
        contentType: response.headers['content-type'],
      );

      final filePath =
          '${downloadsDirectory.path}${Platform.pathSeparator}${media.id}$extension';
      tempFile = File('$filePath.part');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final sink = tempFile.openWrite();
      int bytesWritten = 0;
      int lastLoggedBytes = 0;

      try {
        await for (final chunk in response.stream.timeout(_downloadTimeout)) {
          sink.add(chunk);
          bytesWritten += chunk.length;

          // Log every ~5 MB to avoid noisy logs while still showing progress.
          if (bytesWritten - lastLoggedBytes >= (5 * 1024 * 1024)) {
            lastLoggedBytes = bytesWritten;
            debugPrint(
              '[DownloadService] Download progress for ${media.id}: ${bytesWritten ~/ (1024 * 1024)} MB',
            );
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      if (bytesWritten <= 0) {
        debugPrint(
          '[DownloadService] Empty file stream for mediaId=${media.id}',
        );
        return const MediaDownloadResult(
          status: MediaDownloadStatus.failed,
          message: 'Downloaded file is empty.',
        );
      }

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(filePath);
      tempFile = null;

      debugPrint('[DownloadService] Saved file for ${media.id} at $filePath');

      final downloadedRecord = DownloadedMediaRecord(
        mediaId: media.id,
        title: media.title,
        artistName: media.artistName,
        mediaType: media.mediaType,
        thumbnailUrl: media.thumbnailUrl,
        localPath: file.path,
        fileSize: metadata.fileSize > 0 ? metadata.fileSize : bytesWritten,
        downloadedAt: DateTime.now(),
      );

      _recordsById[media.id] = downloadedRecord;
      await _persistRecords();

      return MediaDownloadResult(
        status: MediaDownloadStatus.success,
        record: downloadedRecord,
        message: 'Downloaded successfully.',
      );
    } on TimeoutException catch (_) {
      debugPrint(
        '[DownloadService] Timeout while downloading mediaId=${media.id}',
      );
      return const MediaDownloadResult(
        status: MediaDownloadStatus.failed,
        message: 'Download timed out. Please try again.',
      );
    } catch (e) {
      debugPrint('[DownloadService] Error downloading mediaId=${media.id}: $e');
      return MediaDownloadResult(
        status: MediaDownloadStatus.failed,
        message: e.toString(),
      );
    } finally {
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }
      client.close();
      _inProgressIds.remove(media.id);
      debugPrint('[DownloadService] Finished download flow for ${media.id}');
    }
  }

  @override
  Future<bool> removeDownload(String mediaId) async {
    await initialize();

    final record = _recordsById.remove(mediaId);
    if (record == null) return false;

    try {
      final file = File(record.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Keep metadata deletion as source-of-truth even if file deletion fails.
    }

    await _persistRecords();
    return true;
  }

  Future<MediaDownloadMetadata> _fetchDownloadMetadata(String mediaId) async {
    debugPrint(
      '[DownloadService] Fetching metadata via /media/$mediaId/download',
    );
    final response = await _api.get('/media/$mediaId/download');
    Map<String, dynamic>? payload;

    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(
          response['data'] as Map<String, dynamic>,
        );
      } else {
        payload = response;
      }
    } else if (response is Map && response['data'] is Map) {
      payload = Map<String, dynamic>.from(response['data'] as Map);
    }

    if (payload == null) {
      throw StateError(
        'Unexpected download metadata response type: ${response.runtimeType}',
      );
    }

    debugPrint('[DownloadService] Metadata payload for $mediaId: $payload');
    return MediaDownloadMetadata.fromJson(payload);
  }

  Uri? _resolveDownloadUri(String rawUrl) {
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) return null;
    if (parsed.hasScheme && parsed.host.isNotEmpty) {
      return parsed;
    }

    final rootUrl = ApiService.baseUrl.replaceFirst('/api', '');
    final absolute = rawUrl.startsWith('/')
        ? '$rootUrl$rawUrl'
        : '$rootUrl/$rawUrl';
    return Uri.tryParse(absolute);
  }

  Map<String, String> _buildDownloadHeaders(Uri downloadUri) {
    final token = _api.accessToken;
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    final apiHost = Uri.parse(ApiService.baseUrl).host;
    if (downloadUri.host == apiHost) {
      return <String, String>{'Authorization': 'Bearer $token'};
    }

    return const <String, String>{};
  }

  Future<Directory> _ensureDownloadsDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$_downloadsFolderName',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _resolveFileExtension({
    required MediaItem media,
    required Uri downloadUri,
    required String? contentType,
  }) {
    final path = downloadUri.path;
    final hasExtension = path.contains('.') && !path.endsWith('.');
    if (hasExtension) {
      final extension = path.substring(path.lastIndexOf('.'));
      if (extension.length <= 8) {
        return extension;
      }
    }

    final normalizedType = (contentType ?? '').toLowerCase();
    if (normalizedType.contains('audio')) return '.m4a';
    if (normalizedType.contains('video')) return '.mp4';

    return media.isVideo ? '.mp4' : '.m4a';
  }

  Future<void> _purgeMissingFiles() async {
    if (_recordsById.isEmpty) return;

    final missingIds = <String>[];
    for (final entry in _recordsById.entries) {
      final exists = await File(entry.value.localPath).exists();
      if (!exists) {
        missingIds.add(entry.key);
      }
    }

    if (missingIds.isEmpty) return;

    for (final id in missingIds) {
      _recordsById.remove(id);
    }
    await _persistRecords();
  }

  Future<void> _persistRecords() async {
    final raw = DownloadedMediaRecord.encodeList(getAllDownloads());
    await _prefs.setString(_prefsKey, raw);
  }
}
