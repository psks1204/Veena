import 'package:flutter/foundation.dart';

import '../../../core/models/media_item.dart';
import 'channel_service.dart';

/// Keeps channel-media interaction state separate from main media interactions.
class ChannelInteractionService extends ChangeNotifier {
  final ChannelService _channelService;

  ChannelInteractionService(this._channelService);

  final Set<String> _likedMediaIds = {};
  final Set<String> _unlikedMediaIds = {};
  final Map<String, int> _likeCounts = {};

  bool isLiked(String mediaId, {bool initial = false}) {
    if (_unlikedMediaIds.contains(mediaId)) return false;
    if (_likedMediaIds.contains(mediaId)) return true;
    return initial;
  }

  int getLikeCount(String mediaId, {int initial = 0}) {
    return _likeCounts[mediaId] ?? initial;
  }

  Future<LikeResponse?> toggleLike(
    String mediaId, {
    bool initial = false,
  }) async {
    final currentlyLiked = isLiked(mediaId, initial: initial);

    if (currentlyLiked) {
      _likedMediaIds.remove(mediaId);
      _unlikedMediaIds.add(mediaId);
    } else {
      _unlikedMediaIds.remove(mediaId);
      _likedMediaIds.add(mediaId);
    }
    notifyListeners();

    try {
      final response = await _channelService.toggleMediaLike(mediaId);
      if (response.liked) {
        _likedMediaIds.add(mediaId);
        _unlikedMediaIds.remove(mediaId);
      } else {
        _likedMediaIds.remove(mediaId);
        _unlikedMediaIds.add(mediaId);
      }
      _likeCounts[mediaId] = response.likeCount;
      notifyListeners();
      return response;
    } catch (e) {
      if (currentlyLiked) {
        _unlikedMediaIds.remove(mediaId);
        _likedMediaIds.add(mediaId);
      } else {
        _likedMediaIds.remove(mediaId);
        _unlikedMediaIds.add(mediaId);
      }
      notifyListeners();
      debugPrint('Channel toggle like failed: $e');
      return null;
    }
  }

  Future<LikeResponse?> checkLikeStatus(String mediaId) async {
    try {
      final response = await _channelService.getMediaLikeStatus(mediaId);
      if (response.liked) {
        _likedMediaIds.add(mediaId);
        _unlikedMediaIds.remove(mediaId);
      } else {
        _likedMediaIds.remove(mediaId);
        _unlikedMediaIds.add(mediaId);
      }
      _likeCounts[mediaId] = response.likeCount;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Channel like status check failed: $e');
      return null;
    }
  }

  Future<void> recordPlay(String mediaId) async {
    try {
      await _channelService.recordMediaPlay(mediaId);
    } catch (e) {
      debugPrint('Channel play tracking failed: $e');
    }
  }

  void removeMediaState(String mediaId) {
    _likedMediaIds.remove(mediaId);
    _unlikedMediaIds.remove(mediaId);
    _likeCounts.remove(mediaId);
    notifyListeners();
  }
}
