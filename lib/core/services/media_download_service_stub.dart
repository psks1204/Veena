import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_download_models.dart';
import '../models/media_item.dart';
import 'api_service.dart';
import 'media_download_service.dart';

MediaDownloadService createMediaDownloadService(
  ApiService api,
  SharedPreferences prefs,
) {
  return _MediaDownloadServiceStub();
}

class _MediaDownloadServiceStub implements MediaDownloadService {
  @override
  bool get isInitialized => true;

  @override
  bool get isPlatformSupported => false;

  @override
  Future<void> initialize() async {}

  @override
  List<DownloadedMediaRecord> getAllDownloads() => const [];

  @override
  DownloadedMediaRecord? getDownload(String mediaId) => null;

  @override
  bool isDownloadInProgress(String mediaId) => false;

  @override
  Future<String?> getLocalPathIfExists(String mediaId) async => null;

  @override
  Future<MediaDownloadResult> downloadMedia(MediaItem media) async {
    return const MediaDownloadResult(
      status: MediaDownloadStatus.unsupportedPlatform,
      message: 'Downloads are available on Android and iOS only.',
    );
  }

  @override
  Future<bool> removeDownload(String mediaId) async => false;
}
