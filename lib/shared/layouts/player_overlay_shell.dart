import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/player_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/mini_player.dart';
import '../../features/player/screens/unified_player_screen.dart';

/// PlayerOverlayShell - Wraps any screen with a mini player at the bottom
///
/// Use this to wrap detail screens (album, playlist, etc.) so users can see
/// and control playback without returning to the main app shell.
///
/// Tapping the mini player opens the UnifiedPlayerScreen.
class PlayerOverlayShell extends StatelessWidget {
  final Widget child;

  const PlayerOverlayShell({super.key, required this.child});

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
              child: child,
            ),

            // Mini player at bottom
            if (player.hasMedia)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(
                  trackTitle: player.currentMedia!.title,
                  artistName: player.currentMedia!.artistName,
                  artworkUrl: player.currentMedia!.thumbnailUrl,
                  isPlaying: player.isPlaying,
                  progress: player.progress,
                  onTap: () {
                    // Navigate to unified player for both audio and video
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const UnifiedPlayerScreen(),
                      ),
                    );
                  },
                  onPlayPause: player.togglePlayPause,
                ),
              ),
          ],
        );
      },
    );
  }
}
