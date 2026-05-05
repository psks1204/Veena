class Comment {
  final int id;
  final String mediaId;
  final String content;
  final String userId;
  final String username;
  final String? userImageUrl;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.mediaId,
    required this.content,
    required this.userId,
    required this.username,
    this.userImageUrl,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final altUser = json['uploadedBy'] as Map<String, dynamic>? ?? {};
    final mergedUser = user.isNotEmpty ? user : altUser;
    final userName =
        mergedUser['name'] as String? ??
        mergedUser['username'] as String? ??
        json['username'] as String? ??
        json['userName'] as String? ??
        'User';
    final userImage =
        mergedUser['photoUrl'] as String? ??
        mergedUser['imageUrl'] as String? ??
        json['userImageUrl'] as String?;
    final resolvedMediaId =
        json['mediaId'] as String? ?? json['userMediaId'] as String? ?? '';
    final commentIdValue = json['id'];
    final resolvedId = commentIdValue is int
        ? commentIdValue
        : int.tryParse(commentIdValue?.toString() ?? '') ?? 0;
    final userIdValue = mergedUser['id'] ?? json['userId'];
    final resolvedUserId = userIdValue?.toString() ?? '';
    final createdAtRaw = json['createdAt'] as String?;
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();

    return Comment(
      id: resolvedId,
      mediaId: resolvedMediaId,
      content: json['content'] as String? ?? '',
      userId: resolvedUserId,
      username: userName,
      userImageUrl: userImage,
      createdAt: createdAt,
    );
  }
}
