import 'package:flutter/foundation.dart';

/// Lyric Line Model
class LyricLine {
  final Duration startTime;
  final Duration endTime;
  final String text;

  const LyricLine({
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  @override
  String toString() => '[$startTime - $endTime] $text';
}

/// Lyrics Model
class Lyrics {
  final List<LyricLine> lines;

  const Lyrics({required this.lines});

  /// Finds the index of the line that should be active at the given position
  int getActiveLineIndex(Duration position) {
    if (lines.isEmpty) return -1;
    
    for (int i = 0; i < lines.length; i++) {
        if (position >= lines[i].startTime && position <= lines[i].endTime) {
            return i;
        }
    }
    
    // If we are between lines, return the previous line or a specific gap handling
    // For Spotify-style, we usually highlight the most recently passed line
    for (int i = lines.length - 1; i >= 0; i--) {
        if (position >= lines[i].startTime) {
            return i;
        }
    }

    return -1;
  }
}
