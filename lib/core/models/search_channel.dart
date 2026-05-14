class SearchChannel {
  const SearchChannel({
    required this.id,
    required this.channelName,
    this.channelHandle,
    this.description,
    this.imageUrl,
    this.subscriberCount = 0,
    this.totalViews = 0,
  });

  final String id;
  final String channelName;
  final String? channelHandle;
  final String? description;
  final String? imageUrl;
  final int subscriberCount;
  final int totalViews;

  factory SearchChannel.fromJson(Map<String, dynamic> json) {
    return SearchChannel(
      id: (json['id'] as String?) ?? '',
      channelName: (json['channelName'] as String?)?.trim().isNotEmpty == true
          ? (json['channelName'] as String).trim()
          : 'Channel',
      channelHandle: (json['channelHandle'] as String?)?.trim(),
      description: json['description'] as String?,
      imageUrl: (json['imageUrl'] as String?)?.trim(),
      subscriberCount: json['subscriberCount'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
    );
  }
}
