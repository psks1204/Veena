import 'dart:convert';

import 'media_item.dart';

enum MediaDownloadStatus {
  success,
  alreadyDownloaded,
  inProgress,
  notSubscribed,
  unsupportedPlatform,
  failed,
}

class MediaDownloadResult {
  const MediaDownloadResult({required this.status, this.record, this.message});

  final MediaDownloadStatus status;
  final DownloadedMediaRecord? record;
  final String? message;

  bool get isSuccess =>
      status == MediaDownloadStatus.success ||
      status == MediaDownloadStatus.alreadyDownloaded;
}

class MediaDownloadMetadata {
  const MediaDownloadMetadata({
    required this.downloadUrl,
    required this.mediaId,
    required this.title,
    required this.fileSize,
    required this.expiresInSeconds,
  });

  final String downloadUrl;
  final String mediaId;
  final String title;
  final int fileSize;
  final int expiresInSeconds;

  factory MediaDownloadMetadata.fromJson(Map<String, dynamic> json) {
    final fileSizeValue = json['fileSize'];
    final expiresValue = json['expiresInSeconds'];

    return MediaDownloadMetadata(
      downloadUrl: json['downloadUrl'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fileSize: fileSizeValue is int
          ? fileSizeValue
          : int.tryParse(fileSizeValue?.toString() ?? '') ?? 0,
      expiresInSeconds: expiresValue is int
          ? expiresValue
          : int.tryParse(expiresValue?.toString() ?? '') ?? 0,
    );
  }
}

class DownloadedMediaRecord {
  const DownloadedMediaRecord({
    required this.mediaId,
    required this.title,
    required this.artistName,
    required this.mediaType,
    this.thumbnailUrl,
    required this.localPath,
    required this.fileSize,
    required this.downloadedAt,
  });

  final String mediaId;
  final String title;
  final String artistName;
  final MediaType mediaType;
  final String? thumbnailUrl;
  final String localPath;
  final int fileSize;
  final DateTime downloadedAt;

  bool get isVideo => mediaType == MediaType.video;

  factory DownloadedMediaRecord.fromJson(Map<String, dynamic> json) {
    final fileSizeValue = json['fileSize'];
    final downloadedAtRaw = json['downloadedAt'] as String?;

    return DownloadedMediaRecord(
      mediaId: json['mediaId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      mediaType: MediaType.fromString(json['mediaType'] as String? ?? 'AUDIO'),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      localPath: json['localPath'] as String? ?? '',
      fileSize: fileSizeValue is int
          ? fileSizeValue
          : int.tryParse(fileSizeValue?.toString() ?? '') ?? 0,
      downloadedAt: downloadedAtRaw != null
          ? DateTime.tryParse(downloadedAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'mediaId': mediaId,
    'title': title,
    'artistName': artistName,
    'mediaType': mediaType.value,
    'thumbnailUrl': thumbnailUrl,
    'localPath': localPath,
    'fileSize': fileSize,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  static String encodeList(List<DownloadedMediaRecord> records) {
    return jsonEncode(records.map((record) => record.toJson()).toList());
  }

  static List<DownloadedMediaRecord> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map(
          (item) =>
              DownloadedMediaRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
