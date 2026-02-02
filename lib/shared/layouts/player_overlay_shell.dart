import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/player_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/mini_player.dart';
import '../widgets/full_player.dart';
import '../../features/player/screens/video_player_screen.dart';

/// PlayerOverlayShell - Wraps any screen with a mini player at the bottom
/// 
/// Use this to wrap detail screens (album, playlist, etc.) so users can see
/// and control playback without returning to the main app shell.
class PlayerOverlayShell extends StatefulWidget {
  final Widget child;
  
  const PlayerOverlayShell({
    super.key,
    required this.child,
  });

  @override
  State<PlayerOverlayShell> createState() => _PlayerOverlayShellState();
}

class _PlayerOverlayShellState extends State<PlayerOverlayShell> {
  bool _showFullPlayer = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        return Stack(
          children: [
            // Main content with bottom padding for mini player
            Padding(
              padding: EdgeInsets.only(
                bottom: player.hasMedia ? AppSpacing.miniPlayerHeight + 8 : 0,
              ),
              child: widget.child,
            ),
            
            // Mini player at bottom
            if (player.hasMedia)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(
                  trackTitle: player.currentMedia!.title,
                  artistName: player.currentMedia!.artistName ?? 'Unknown Artist',
                  artworkUrl: player.currentMedia!.thumbnailUrl,
                  isPlaying: player.isPlaying,
                  progress: player.progress,
                  onTap: () {
                    if (player.isVideo) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const VideoPlayerScreen()),
                      );
                    } else {
                      setState(() {
                        _showFullPlayer = true;
                      });
                    }
                  },
                  onPlayPause: player.togglePlayPause,
                ),
              ),
            
            // Full player overlay (for audio)
            if (_showFullPlayer && player.hasMedia && player.isAudio)
              AnimatedSlide(
                offset: _showFullPlayer ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                child: FullPlayer(
                  trackTitle: player.currentMedia!.title,
                  artistName: player.currentMedia!.description ?? '',
                  albumName: '',
                  artworkUrl: player.currentMedia!.thumbnailUrl,
                  isPlaying: player.isPlaying,
                  progress: player.progress,
                  currentPosition: player.position,
                  duration: player.duration,
                  isShuffleOn: player.shuffleEnabled,
                  repeatMode: player.repeatMode,
                  lyrics: player.currentLyrics,
                  activeLyricIndex: player.activeLyricIndex,
                  onClose: () {
                    setState(() {
                      _showFullPlayer = false;
                    });
                  },
                  onPlayPause: player.togglePlayPause,
                  onSeek: player.seekToProgress,
                  onPrevious: player.previous,
                  onNext: player.next,
                  onShuffle: player.toggleShuffle,
                  onRepeat: player.toggleRepeatMode,
                ),
              ),
          ],
        );
      },
    );
  }
}
