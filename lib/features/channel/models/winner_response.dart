import 'channel.dart' as channel_models;

/// Response model for Winner APIs (/api/winners/*)
class WinnerResponse {
  final String period; // MONTH, QUARTER, YEAR
  final String periodLabel; // "October 2026", "Q4 2026", "2026"
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final bool hasWinner;
  final WinnerProfile? winner;
  final WinningReel? winningReel;
  final List<RunnerUp> runnerUps;

  WinnerResponse({
    required this.period,
    required this.periodLabel,
    this.periodStart,
    this.periodEnd,
    required this.hasWinner,
    this.winner,
    this.winningReel,
    this.runnerUps = const [],
  });

  factory WinnerResponse.fromJson(Map<String, dynamic> json) {
    return WinnerResponse(
      period: json['period'] as String? ?? '',
      periodLabel: json['periodLabel'] as String? ?? '',
      periodStart: json['periodStart'] != null
          ? DateTime.tryParse(json['periodStart'] as String)
          : null,
      periodEnd: json['periodEnd'] != null
          ? DateTime.tryParse(json['periodEnd'] as String)
          : null,
      hasWinner: json['hasWinner'] as bool? ?? false,
      winner: json['winner'] != null
          ? WinnerProfile.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      winningReel: json['winningReel'] != null
          ? WinningReel.fromJson(json['winningReel'] as Map<String, dynamic>)
          : null,
      runnerUps: (json['runnerUps'] as List<dynamic>?)
              ?.map((e) => RunnerUp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Converts the winning reel and runner-ups into UserMediaResponses
  List<channel_models.UserMediaResponse> toReelList() {
    final list = <channel_models.UserMediaResponse>[];
    if (hasWinner && winningReel != null) {
      list.add(winningReel!.toUserMediaResponse(winner, periodLabel: periodLabel));
    }
    for (final runner in runnerUps) {
      final rMedia = runner.toUserMediaResponse(periodLabel: periodLabel);
      if (rMedia != null) {
        list.add(rMedia);
      }
    }
    return list;
  }
}

class WinnerProfile {
  final String userId;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? channelId;
  final String? channelName;
  final String? channelHandle;
  final String? channelImageUrl;
  final int subscriberCount;

  WinnerProfile({
    required this.userId,
    required this.name,
    this.email,
    this.photoUrl,
    this.channelId,
    this.channelName,
    this.channelHandle,
    this.channelImageUrl,
    this.subscriberCount = 0,
  });

  factory WinnerProfile.fromJson(Map<String, dynamic> json) {
    return WinnerProfile(
      userId: json['userId']?.toString() ?? '',
      name: json['name'] as String? ?? 'Veena Creator',
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      channelId: json['channelId']?.toString(),
      channelName: json['channelName'] as String?,
      channelHandle: json['channelHandle'] as String?,
      channelImageUrl: json['channelImageUrl'] as String?,
      subscriberCount: (json['subscriberCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class WinningReel {
  final String mediaId;
  final String title;
  final String? description;
  final String? mediaType;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final int totalLikesInPeriod;
  final int totalLikesAllTime;
  final int playCount;
  final int? durationSeconds;

  WinningReel({
    required this.mediaId,
    required this.title,
    this.description,
    this.mediaType,
    this.thumbnailUrl,
    this.hlsUrl,
    this.totalLikesInPeriod = 0,
    this.totalLikesAllTime = 0,
    this.playCount = 0,
    this.durationSeconds,
  });

  factory WinningReel.fromJson(Map<String, dynamic> json) {
    return WinningReel(
      mediaId: json['mediaId']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      mediaType: json['mediaType'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      totalLikesInPeriod: (json['totalLikesInPeriod'] as num?)?.toInt() ?? 0,
      totalLikesAllTime: (json['totalLikesAllTime'] as num?)?.toInt() ?? 0,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );
  }

  channel_models.UserMediaResponse toUserMediaResponse(
    WinnerProfile? winner, {
    String? periodLabel,
  }) {
    return channel_models.UserMediaResponse(
      id: mediaId,
      channelId: winner?.channelId,
      channelName: winner?.channelName ?? winner?.name,
      uploadedByName: winner?.name,
      title: title,
      description: description,
      mediaType: mediaType == 'AUDIO'
          ? channel_models.MediaType.audio
          : channel_models.MediaType.video,
      status: channel_models.MediaStatus.ready,
      approvalStatus: channel_models.ApprovalStatus.approved,
      thumbnailUrl: thumbnailUrl,
      hlsUrl: hlsUrl,
      durationSeconds: durationSeconds,
      playCount: playCount,
      
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class RunnerUp {
  final int rank;
  final String userId;
  final String name;
  final String? photoUrl;
  final String? channelId;
  final String? channelName;
  final String mediaId;
  final String mediaTitle;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final String? description;
  final String? mediaType;
  final int likesInPeriod;
  final int totalLikesAllTime;
  final int playCount;
  final int? durationSeconds;

  RunnerUp({
    required this.rank,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.channelId,
    this.channelName,
    required this.mediaId,
    required this.mediaTitle,
    this.thumbnailUrl,
    this.hlsUrl,
    this.description,
    this.mediaType,
    this.likesInPeriod = 0,
    this.totalLikesAllTime = 0,
    this.playCount = 0,
    this.durationSeconds,
  });

  factory RunnerUp.fromJson(Map<String, dynamic> json) {
    return RunnerUp(
      rank: (json['rank'] as num?)?.toInt() ?? 2,
      userId: json['userId']?.toString() ?? '',
      name: json['name'] as String? ?? 'Runner-Up',
      photoUrl: json['photoUrl'] as String?,
      channelId: json['channelId']?.toString(),
      channelName: json['channelName'] as String?,
      mediaId: json['mediaId']?.toString() ?? '',
      mediaTitle: json['mediaTitle'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      description: json['description'] as String?,
      mediaType: json['mediaType'] as String?,
      likesInPeriod: (json['likesInPeriod'] as num?)?.toInt() ?? 0,
      totalLikesAllTime: (json['totalLikesAllTime'] as num?)?.toInt() ?? 0,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );
  }

  channel_models.UserMediaResponse? toUserMediaResponse({String? periodLabel}) {
    return channel_models.UserMediaResponse(
      id: mediaId,
      channelId: channelId,
      channelName: channelName ?? name,
      uploadedByName: name,
      title: mediaTitle,
      description: description,
      mediaType: mediaType == 'AUDIO'
          ? channel_models.MediaType.audio
          : channel_models.MediaType.video,
      status: channel_models.MediaStatus.ready,
      approvalStatus: channel_models.ApprovalStatus.approved,
      thumbnailUrl: thumbnailUrl,
      hlsUrl: hlsUrl,
      durationSeconds: durationSeconds,
      playCount: playCount,
      
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
