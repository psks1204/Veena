import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_download_models.dart';
import '../models/media_item.dart';
import 'api_service.dart';
import 'media_download_service_stub.dart'
    if (dart.library.io) 'media_download_service_io.dart'
    as impl;

abstract class MediaDownloadService {
  factory MediaDownloadService(ApiService api, SharedPreferences prefs) =>
      impl.createMediaDownloadService(api, prefs);

  bool get isInitialized;
  bool get isPlatformSupported;

  Future<void> initialize();

  List<DownloadedMediaRecord> getAllDownloads();
  DownloadedMediaRecord? getDownload(String mediaId);
  bool isDownloadInProgress(String mediaId);

  Future<String?> getLocalPathIfExists(String mediaId);
  Future<MediaDownloadResult> downloadMedia(MediaItem media);
  Future<bool> removeDownload(String mediaId);
}
