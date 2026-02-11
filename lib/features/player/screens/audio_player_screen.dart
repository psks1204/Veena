import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../shared/widgets/full_player.dart';
import 'lyrics_fullscreen_screen.dart';

/// Audio Player Screen
/// 
/// Wraps FullPlayer as a navigable screen so it stays within
/// the nested navigator and keeps nav bar + mini player visible.
class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (!player.hasMedia || !player.isAudio) {
          // If no audio playing, pop back
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        return FullPlayer(
          mediaItem: player.currentMedia!,
          isPlaying: player.isPlaying,
          progress: player.progress,
          currentPosition: player.position,
          duration: player.duration,
          isShuffleOn: player.shuffleEnabled,
          repeatMode: player.repeatMode,
          lyrics: player.currentLyrics,
          activeLyricIndex: player.activeLyricIndex,
          onFullscreenLyricsTap: () {
            if (player.currentLyrics != null) {
              AppNavigation.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LyricsFullscreenScreen(
                    lyrics: player.currentLyrics!,
                    initialActiveIndex: player.activeLyricIndex,
                    activeIndexStream: player.lyricIndexStream,
                  ),
                ),
              );
            }
          },
          onClose: () {
            Navigator.of(context).pop();
          },
          onPlayPause: () => player.togglePlayPause(),
          onSeek: (v) => player.seekToProgress(v),
          onPrevious: () => player.previous(),
          onNext: () => player.next(),
          onShuffle: () => player.toggleShuffle(),
          onRepeat: () => player.toggleRepeatMode(),
        );
      },
    );
  }
}
