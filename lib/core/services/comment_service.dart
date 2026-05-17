import '../services/api_service.dart';
import '../models/paged_response.dart';
import '../models/comment.dart';

class CommentService {
  final ApiService _api;

  CommentService(this._api);

  Future<PagedResponse<Comment>> getComments(
    String mediaId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.get(
      '/media/$mediaId/comments',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'createdAt,desc',
      },
    );

    if (response == null) {
      return PagedResponse(
        content: [],
        totalPages: 0,
        totalElements: 0,
        size: size,
        number: page,
      );
    }

    final content = (response['content'] as List)
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();

    return PagedResponse(
      content: content,
      totalPages: response['totalPages'] ?? 1,
      totalElements: response['totalElements'] ?? content.length,
      size: response['size'] ?? size,
      number: response['number'] ?? page,
    );
  }

  Future<bool> postComment(
    String mediaId,
    String content, {
    int parentCommentId = 0,
  }) async {
    try {
      await _api.post(
        '/media/$mediaId/comments',
        body: {'content': content, 'parentCommentId': parentCommentId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PagedResponse<Comment>> getReplies(
    String mediaId,
    int commentId, {
    int page = 0,
    int size = 10,
  }) async {
    final response = await _api.get(
      '/media/$mediaId/comments/$commentId/replies',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'createdAt,asc',
      },
    );

    if (response == null) {
      return PagedResponse(
        content: const [],
        totalPages: 0,
        totalElements: 0,
        size: size,
        number: page,
      );
    }

    final content = (response['content'] as List<dynamic>? ?? const [])
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();

    return PagedResponse(
      content: content,
      totalPages: response['totalPages'] ?? 1,
      totalElements: response['totalElements'] ?? content.length,
      size: response['size'] ?? size,
      number: response['number'] ?? page,
    );
  }

  Future<bool> deleteComment(String mediaId, int commentId) async {
    try {
      await _api.delete('/media/$mediaId/comments/$commentId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> getCommentCount(String mediaId) async {
    final response = await _api.get('/media/$mediaId/comments/count');
    if (response is int) return response;
    if (response is Map && response.containsKey('count')) {
      return response['count'] as int? ?? 0;
    }
    return 0;
  }
}
