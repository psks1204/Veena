import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lyrics_model.dart';

/// Lyrics Parser and Service - Supports both VTT and SRT formats
class LyricsService {
  /// Fetches and parses a lyrics file from a URL (auto-detects VTT or SRT)
  Future<Lyrics?> fetchLyrics(String url) async {
    debugPrint('[LyricsService] Starting fetch from: $url');
    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('[LyricsService] HTTP response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        debugPrint('[LyricsService] Response body length: ${response.body.length}');
        return parse(response.body);
      }
      debugPrint('[LyricsService] Non-200 status, returning null');
      return null;
    } catch (e, stack) {
      debugPrint('[LyricsService] Error fetching lyrics: $e');
      debugPrint('[LyricsService] Stack: $stack');
      return null;
    }
  }

  /// Auto-detect format and parse accordingly
  Lyrics parse(String content) {
    // Remove BOM if present
    var normalized = content;
    if (normalized.startsWith('\uFEFF')) {
      normalized = normalized.substring(1);
    }
    // Normalize line endings
    normalized = normalized.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Check for VTT format - look for WEBVTT header or VTT-style timestamps (00:00.000)
    final trimmed = normalized.trimLeft();
    final isVtt = trimmed.startsWith('WEBVTT') || 
                  // VTT uses dots in timestamps like 00:00.000 or 00:00:00.000
                  RegExp(r'\d{2}:\d{2}[:.]\d{3}').hasMatch(normalized) ||
                  // Also check for VTT-style arrow with dot timestamps  
                  normalized.contains(RegExp(r'\d{2}:\d{2}\.\d{3}\s*-->')); 
    
    if (isVtt) {
      debugPrint('[LyricsService] Detected VTT format');
      return parseVtt(normalized);
    } else {
      debugPrint('[LyricsService] Detected SRT format');
      return parseSrt(normalized);
    }
  }

  /// Parses VTT/WebVTT string into Lyrics model
  Lyrics parseVtt(String vttContent) {
    debugPrint('[LyricsService] Parsing VTT content');
    final List<LyricLine> lines = [];
    
    var content = vttContent;
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }
    
    final allLines = content.split('\n');
    int i = 0;
    
    // Skip WEBVTT header and metadata
    while (i < allLines.length) {
      if (allLines[i].contains(' --> ')) break;
      i++;
    }
    
    // Parse cues
    while (i < allLines.length) {
      final line = allLines[i].trim();
      
      if (line.isEmpty) {
        i++;
        continue;
      }
      
      if (line.contains(' --> ')) {
        final timeParts = line.split(' --> ');
        if (timeParts.length >= 2) {
          try {
            final startTime = _parseVttTime(timeParts[0].trim());
            final endTimeStr = timeParts[1].split(' ')[0].trim();
            final endTime = _parseVttTime(endTimeStr);
            
            i++;
            final textLines = <String>[];
            while (i < allLines.length) {
              final textLine = allLines[i];
              if (textLine.trim().isEmpty || textLine.contains(' --> ')) break;
              final cleanedLine = textLine.replaceAll(RegExp(r'<[^>]*>'), '').trim();
              if (cleanedLine.isNotEmpty) textLines.add(cleanedLine);
              i++;
            }
            
            if (textLines.isNotEmpty) {
              lines.add(LyricLine(
                startTime: startTime,
                endTime: endTime,
                text: textLines.join(' '),
              ));
            }
          } catch (e) {
            debugPrint('[LyricsService] Skip invalid VTT cue: $e');
            i++;
          }
        } else {
          i++;
        }
      } else {
        i++;
      }
    }

    debugPrint('[LyricsService] Parsed ${lines.length} VTT lyric lines');
    return Lyrics(lines: lines);
  }

  /// Parses SRT string into Lyrics model
  Lyrics parseSrt(String srtContent) {
    debugPrint('[LyricsService] Parsing SRT content');
    final List<LyricLine> lines = [];
    
    var content = srtContent;
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }
    
    final blocks = content.split(RegExp(r'\n\s*\n'));
    debugPrint('[LyricsService] Found ${blocks.length} SRT blocks');

    for (var block in blocks) {
      final trimmedBlock = block.trim();
      if (trimmedBlock.isEmpty) continue;

      final parts = trimmedBlock.split('\n');
      
      // Find the time range line
      int timeLineIndex = -1;
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].contains(' --> ')) {
          timeLineIndex = i;
          break;
        }
      }

      if (timeLineIndex == -1 || timeLineIndex + 1 >= parts.length) continue;

      final timeLine = parts[timeLineIndex];
      final timeParts = timeLine.split(' --> ');
      if (timeParts.length != 2) continue;

      try {
        final startTime = _parseSrtTime(timeParts[0].trim());
        final endTime = _parseSrtTime(timeParts[1].trim());
        final text = parts.sublist(timeLineIndex + 1).join(' ').replaceAll(RegExp(r'<[^>]*>'), '');

        lines.add(LyricLine(
          startTime: startTime,
          endTime: endTime,
          text: text.trim(),
        ));
      } catch (e) {
        debugPrint('[LyricsService] Skip invalid SRT block: $e');
      }
    }

    debugPrint('[LyricsService] Parsed ${lines.length} SRT lyric lines');
    return Lyrics(lines: lines);
  }

  /// Parses VTT time format: 00:00:12.340 or 00:12.340
  Duration _parseVttTime(String timeStr) {
    final trimmed = timeStr.trim();
    final parts = trimmed.split(':');
    
    int hours = 0;
    int minutes = 0;
    double seconds = 0;

    if (parts.length == 3) {
      hours = int.parse(parts[0]);
      minutes = int.parse(parts[1]);
      seconds = double.parse(parts[2]);
    } else if (parts.length == 2) {
      minutes = int.parse(parts[0]);
      seconds = double.parse(parts[1]);
    }

    final totalMilliseconds = (hours * 3600 + minutes * 60 + seconds) * 1000;
    return Duration(milliseconds: totalMilliseconds.round());
  }

  /// Parses SRT time format: 00:00:12,340
  Duration _parseSrtTime(String timeStr) {
    final parts = timeStr.trim().split(':');
    if (parts.length != 3) return Duration.zero;

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    
    final secondsParts = parts[2].split(',');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = secondsParts.length > 1 ? int.parse(secondsParts[1]) : 0;

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
