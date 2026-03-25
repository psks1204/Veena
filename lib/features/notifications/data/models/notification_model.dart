import 'package:veena/core/models/paged_response.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? targetGroup;
  final bool isActive;
  final bool viewed;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.targetGroup,
    required this.isActive,
    required this.viewed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      targetGroup: json['targetGroup'],
      isActive: json['isActive'] ?? true,
      viewed: json['viewed'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'targetGroup': targetGroup,
      'isActive': isActive,
      'viewed': viewed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Notification Paged Response
class NotificationPagedResponse extends PagedResponse<NotificationModel> {
  NotificationPagedResponse({
    required super.content,
    required super.totalPages,
    required super.totalElements,
    required super.size,
    required super.number,
  });

  factory NotificationPagedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> contentJson = json['content'] ?? [];
    return NotificationPagedResponse(
      content: contentJson.map((item) => NotificationModel.fromJson(item)).toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
    );
  }
}
