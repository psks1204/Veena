import 'package:flutter/material.dart';

class Alarm {
  final String id;
  final TimeOfDay time;
  final bool isEnabled;
  final String? mediaId;
  final String? mediaTitle;
  final String? mediaUrl;
  final String? artistName;

  const Alarm({
    required this.id,
    required this.time,
    this.isEnabled = true,
    this.mediaId,
    this.mediaTitle,
    this.mediaUrl,
    this.artistName,
  });

  Alarm copyWith({
    String? id,
    TimeOfDay? time,
    bool? isEnabled,
    String? mediaId,
    String? mediaTitle,
    String? mediaUrl,
    String? artistName,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      mediaId: mediaId ?? this.mediaId,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      artistName: artistName ?? this.artistName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled,
      'mediaId': mediaId,
      'mediaTitle': mediaTitle,
      'mediaUrl': mediaUrl,
      'artistName': artistName,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      isEnabled: json['isEnabled'] ?? true,
      mediaId: json['mediaId'],
      mediaTitle: json['mediaTitle'],
      mediaUrl: json['mediaUrl'],
      artistName: json['artistName'],
    );
  }
}
