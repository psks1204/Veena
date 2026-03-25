import 'package:flutter/foundation.dart';
import 'package:veena/features/notifications/data/models/notification_model.dart';
import 'package:veena/features/notifications/data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider(this._service);

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;
  int _totalElements = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get totalElements => _totalElements;

  /// Load initial notifications
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _notifications = [];
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchNotifications(page: _currentPage, size: 20);
      
      if (refresh) {
        _notifications = response.content;
      } else {
        _notifications.addAll(response.content);
      }

      _totalElements = response.totalElements;
      _currentPage++;
      _hasMore = !response.isLast;
      
      // Also refresh count when loading
      await refreshCount();

      _error = null;
    } catch (e) {
      debugPrint('❌ NotificationProvider.loadNotifications: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh unread count
  Future<void> refreshCount() async {
    try {
      _unreadCount = await _service.getNotificationCount();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ NotificationProvider.refreshCount: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      _unreadCount = 0;
      // Update local state for all notifications
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        title: n.title,
        description: n.description,
        imageUrl: n.imageUrl,
        targetGroup: n.targetGroup,
        isActive: n.isActive,
        viewed: true,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ NotificationProvider.markAllAsRead: $e');
    }
  }

  /// Mark as read locally
  void markLocalAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].viewed) {
      final n = _notifications[index];
      _notifications[index] = NotificationModel(
        id: n.id,
        title: n.title,
        description: n.description,
        imageUrl: n.imageUrl,
        targetGroup: n.targetGroup,
        isActive: n.isActive,
        viewed: true,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      );
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }
}
