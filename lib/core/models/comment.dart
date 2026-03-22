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
    
    return Comment(
      id: json['id'] as int,
      mediaId: json['mediaId'] as String,
      content: json['content'] as String,
      userId: user['id'] as String? ?? '',
      username: user['name'] as String? ?? 'User',
      userImageUrl: user['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
