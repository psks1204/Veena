import 'package:veena/core/services/api_service.dart';
import 'package:veena/features/notifications/data/models/notification_model.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// Fetch paginated notifications
  /// GET /api/notifications?page=X&size=Y
  Future<NotificationPagedResponse> fetchNotifications({int page = 0, int size = 20}) async {
    final response = await _apiService.get(
      '/notifications',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
    );
    return NotificationPagedResponse.fromJson(response);
  }

  /// Get unread notification count
  /// GET /api/notifications/count
  Future<int> getNotificationCount() async {
    final response = await _apiService.get('/notifications/count');
    if (response is int) return response;
    if (response is Map<String, dynamic>) {
      return response['count'] ?? 0;
    }
    return 0;
  }

  /// Mark all notifications as read
  /// POST /api/notifications/view
  Future<void> markAllAsRead() async {
    await _apiService.post('/notifications/view', body: {});
  }
}
