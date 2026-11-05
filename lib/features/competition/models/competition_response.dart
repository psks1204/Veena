import '../../channel/models/winner_response.dart';

/// Response model for Competition API (/api/competitions/ongoing)
class CompetitionResponse {
  final String id;
  final String title;
  final String? description;
  final String? prize;
  final double? prizeValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? bannerImageUrl;
  final String? prizeImageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status; // "UPCOMING" | "ONGOING" | "ENDED"
  final int daysRemaining;
  final List<LeaderboardEntry> leaderboard;
  final WinnerResponse? winnerAnnouncement;

  CompetitionResponse({
    required this.id,
    required this.title,
    this.description,
    this.prize,
    this.prizeValue,
    this.startDate,
    this.endDate,
    this.bannerImageUrl,
    this.prizeImageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    required this.status,
    this.daysRemaining = 0,
    this.leaderboard = const [],
    this.winnerAnnouncement,
  });

  bool get isOngoing => status.toUpperCase() == 'ONGOING';
  bool get isEnded => status.toUpperCase() == 'ENDED';
  bool get isUpcoming => status.toUpperCase() == 'UPCOMING';

  factory CompetitionResponse.fromJson(Map<String, dynamic> json) {
    return CompetitionResponse(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Singing Competition',
      description: json['description'] as String?,
      prize: json['prize'] as String?,
      prizeValue: (json['prizeValue'] as num?)?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      bannerImageUrl: json['bannerImageUrl'] as String?,
      prizeImageUrl: json['prizeImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      status: (json['status'] as String? ?? 'UPCOMING').toUpperCase(),
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      leaderboard: (json['leaderboard'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      winnerAnnouncement: json['winnerAnnouncement'] != null
          ? WinnerResponse.fromJson(
              json['winnerAnnouncement'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Entry in the competition leaderboard (top performers)
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String? photoUrl;
  final String? channelId;
  final String? channelName;
  final String? channelHandle;
  final String? channelImageUrl;
  final String? mediaId;
  final String? mediaTitle;
  final String? thumbnailUrl;
  final int likesInCompetition;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.channelId,
    this.channelName,
    this.channelHandle,
    this.channelImageUrl,
    this.mediaId,
    this.mediaTitle,
    this.thumbnailUrl,
    this.likesInCompetition = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      name: json['name'] as String? ?? 'Performer',
      photoUrl: json['photoUrl'] as String?,
      channelId: json['channelId']?.toString(),
      channelName: json['channelName'] as String?,
      channelHandle: json['channelHandle'] as String?,
      channelImageUrl: json['channelImageUrl'] as String?,
      mediaId: json['mediaId']?.toString(),
      mediaTitle: json['mediaTitle'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      likesInCompetition:
          (json['likesInCompetition'] as num?)?.toInt() ?? 0,
    );
  }
}
