/// Channel Feature Models
///
/// Matches the ChannelResponse and UserMediaResponse shapes from
/// the backend API (UserChannelController).
library;

class ChannelResponse {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? channelName;
  final String? channelHandle;
  final String? description;
  final String? imageUrl;
  final bool active;
  final int subscriberCount;
  final int totalViews;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int totalMedia;
  final int pendingMedia;
  final int approvedMedia;

  const ChannelResponse({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.channelName,
    this.channelHandle,
    this.description,
    this.imageUrl,
    this.active = true,
    this.subscriberCount = 0,
    this.totalViews = 0,
    this.createdAt,
    this.updatedAt,
    this.totalMedia = 0,
    this.pendingMedia = 0,
    this.approvedMedia = 0,
  });

  factory ChannelResponse.fromJson(Map<String, dynamic> json) {
    return ChannelResponse(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      channelName: json['channelName'] as String?,
      channelHandle: json['channelHandle'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      active: json['active'] as bool? ?? true,
      subscriberCount: json['subscriberCount'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      totalMedia: json['totalMedia'] as int? ?? 0,
      pendingMedia: json['pendingMedia'] as int? ?? 0,
      approvedMedia: json['approvedMedia'] as int? ?? 0,
    );
  }
}

enum MediaType { audio, video }

enum MediaStatus { uploading, processing, ready, failed }

enum ApprovalStatus { pending, approved, rejected }

class UserMediaResponse {
  final String id;
  final String title;
  final String? description;
  final MediaType mediaType;
  final MediaStatus status;
  final ApprovalStatus approvalStatus;
  final String? rejectionReason;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final int? fileSize;
  final String? fileExtension;
  final int playCount;
  final int? durationSeconds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final String? channelId;
  final String? channelName;
  final String? uploadedById;
  final String? uploadedByName;
  final String? uploadedByEmail;

  const UserMediaResponse({
    required this.id,
    required this.title,
    this.description,
    required this.mediaType,
    required this.status,
    required this.approvalStatus,
    this.rejectionReason,
    this.hlsUrl,
    this.thumbnailUrl,
    this.fileSize,
    this.fileExtension,
    this.playCount = 0,
    this.durationSeconds,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.channelId,
    this.channelName,
    this.uploadedById,
    this.uploadedByName,
    this.uploadedByEmail,
  });

  factory UserMediaResponse.fromJson(Map<String, dynamic> json) {
    return UserMediaResponse(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      mediaType: _parseMediaType(json['mediaType'] as String?),
      status: _parseMediaStatus(json['status'] as String?),
      approvalStatus: _parseApprovalStatus(json['approvalStatus'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileSize: json['fileSize'] as int?,
      fileExtension: json['fileExtension'] as String?,
      playCount: json['playCount'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      channelId: json['channelId'] as String?,
      channelName: json['channelName'] as String?,
      uploadedById: json['uploadedById'] as String?,
      uploadedByName: json['uploadedByName'] as String?,
      uploadedByEmail: json['uploadedByEmail'] as String?,
    );
  }

  static MediaType _parseMediaType(String? value) {
    switch (value?.toUpperCase()) {
      case 'VIDEO':
        return MediaType.video;
      default:
        return MediaType.audio;
    }
  }

  static MediaStatus _parseMediaStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'PROCESSING':
        return MediaStatus.processing;
      case 'READY':
        return MediaStatus.ready;
      case 'FAILED':
        return MediaStatus.failed;
      default:
        return MediaStatus.uploading;
    }
  }

  static ApprovalStatus _parseApprovalStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'REJECTED':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }
}
