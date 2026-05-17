import 'package:flutter/foundation.dart';

import '../models/media_download_models.dart';
import '../models/media_item.dart';
import '../services/media_download_service.dart';

enum DownloadTaskStatus { downloading, failed }

class DownloadTaskEntry {
  const DownloadTaskEntry({
    required this.media,
    required this.status,
    required this.updatedAt,
    this.errorMessage,
  });

  final MediaItem media;
  final DownloadTaskStatus status;
  final DateTime updatedAt;
  final String? errorMessage;

  DownloadTaskEntry copyWith({
    MediaItem? media,
    DownloadTaskStatus? status,
    DateTime? updatedAt,
    String? errorMessage,
  }) {
    return DownloadTaskEntry(
      media: media ?? this.media,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage,
    );
  }
}

class DownloadProvider extends ChangeNotifier {
  DownloadProvider(this._service);

  final MediaDownloadService _service;

  bool _initialized = false;
  bool _isLoading = false;
  bool _isSubscribed = false;
  String? _error;

  final Set<String> _inProgressIds = <String>{};
  final Map<String, DownloadTaskEntry> _taskEntriesById =
      <String, DownloadTaskEntry>{};
  Map<String, DownloadedMediaRecord> _recordsById =
      <String, DownloadedMediaRecord>{};

  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  bool get isSubscribed => _isSubscribed;
  String? get error => _error;
  bool get isPlatformSupported => _service.isPlatformSupported;

  List<DownloadedMediaRecord> get downloads {
    final all = _recordsById.values.toList(growable: false);
    all.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return all;
  }

  List<DownloadTaskEntry> get taskEntries {
    final all = _taskEntriesById.values.toList(growable: false);
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  void updateSubscriptionStatus(bool subscribed) {
    if (_isSubscribed == subscribed) return;
    _isSubscribed = subscribed;
    notifyListeners();
  }

  bool isDownloaded(String mediaId) => _recordsById.containsKey(mediaId);

  bool isDownloading(String mediaId) {
    return _inProgressIds.contains(mediaId) ||
        _service.isDownloadInProgress(mediaId);
  }

  DownloadedMediaRecord? getRecord(String mediaId) => _recordsById[mediaId];

  DownloadTaskEntry? getTaskEntry(String mediaId) => _taskEntriesById[mediaId];

  Future<void> initialize() async {
    if (_initialized || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.initialize();
      _syncFromService();
      _initialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MediaDownloadResult> downloadMedia(MediaItem media) async {
    debugPrint('[DownloadProvider] downloadMedia start: ${media.id}');

    if (!_service.isPlatformSupported) {
      debugPrint('[DownloadProvider] Unsupported platform for ${media.id}');
      return const MediaDownloadResult(
        status: MediaDownloadStatus.unsupportedPlatform,
        message: 'Downloads are available on Android and iOS only.',
      );
    }

    if (!_isSubscribed) {
      debugPrint('[DownloadProvider] Not subscribed for ${media.id}');
      return const MediaDownloadResult(
        status: MediaDownloadStatus.notSubscribed,
        message: 'Subscription is required for in-app downloads.',
      );
    }

    await initialize();

    if (_inProgressIds.contains(media.id)) {
      debugPrint('[DownloadProvider] Already in progress: ${media.id}');
      return const MediaDownloadResult(
        status: MediaDownloadStatus.inProgress,
        message: 'Download already in progress.',
      );
    }

    _inProgressIds.add(media.id);
    _taskEntriesById[media.id] = DownloadTaskEntry(
      media: media,
      status: DownloadTaskStatus.downloading,
      updatedAt: DateTime.now(),
      errorMessage: null,
    );
    notifyListeners();

    try {
      final result = await _service.downloadMedia(media);
      debugPrint(
        '[DownloadProvider] downloadMedia result for ${media.id}: ${result.status} (${result.message ?? 'no-message'})',
      );
      _error = result.status == MediaDownloadStatus.failed
          ? (result.message ?? 'Download failed.')
          : null;

      if (result.status == MediaDownloadStatus.success ||
          result.status == MediaDownloadStatus.alreadyDownloaded) {
        _taskEntriesById.remove(media.id);
      } else if (result.status == MediaDownloadStatus.failed) {
        _taskEntriesById[media.id] = DownloadTaskEntry(
          media: media,
          status: DownloadTaskStatus.failed,
          updatedAt: DateTime.now(),
          errorMessage: result.message ?? 'Download failed.',
        );
      }

      _syncFromService();
      return result;
    } finally {
      _inProgressIds.remove(media.id);
      debugPrint('[DownloadProvider] downloadMedia finished: ${media.id}');
      notifyListeners();
    }
  }

  Future<MediaDownloadResult> retryDownload(String mediaId) async {
    final task = _taskEntriesById[mediaId];
    if (task == null) {
      return const MediaDownloadResult(
        status: MediaDownloadStatus.failed,
        message: 'Download task no longer available.',
      );
    }
    return downloadMedia(task.media);
  }

  void clearTask(String mediaId) {
    if (_taskEntriesById.remove(mediaId) != null) {
      notifyListeners();
    }
  }

  Future<bool> removeDownload(String mediaId) async {
    await initialize();
    final removed = await _service.removeDownload(mediaId);
    if (removed) {
      _recordsById.remove(mediaId);
      _taskEntriesById.remove(mediaId);
      notifyListeners();
    }
    return removed;
  }

  Future<void> refresh() async {
    await initialize();
    _syncFromService();
    notifyListeners();
  }

  void _syncFromService() {
    final next = <String, DownloadedMediaRecord>{};
    for (final record in _service.getAllDownloads()) {
      next[record.mediaId] = record;
    }
    _recordsById = next;
  }
}
