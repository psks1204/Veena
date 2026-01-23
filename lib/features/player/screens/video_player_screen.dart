import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/player_provider.dart';

/// Video Player Screen
/// 
/// Full-screen video player for VIDEO content.
/// Supports HLS streaming with playback controls.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _showControls = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && context.read<PlayerProvider>().isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        // Check if controller is valid and initialized
        final controller = player.videoController;
        final isValid = controller != null && 
                        controller.value.isInitialized &&
                        !controller.value.hasError;
        
        if (!isValid) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  if (controller?.value.hasError ?? false)
                    Text(
                      'Error loading video',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video Player - wrapped in try-catch via Builder
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio > 0 
                        ? controller.value.aspectRatio 
                        : 16 / 9,
                    child: VideoPlayer(controller),
                  ),
                ),

                // Controls Overlay
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Stack(
                      children: [
                        // Top Bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                    onPressed: () {
                                      player.stop();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  const Spacer(),
                                  if (player.currentMedia != null)
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          Text(
                                            player.currentMedia!.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          if (player.currentMedia!.description != null)
                                            Text(
                                              player.currentMedia!.description!,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Center Play/Pause
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Rewind 10s
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(Icons.replay_10, color: Colors.white),
                                onPressed: () {
                                  final newPosition = player.position - const Duration(seconds: 10);
                                  player.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
                                },
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              // Play/Pause
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  iconSize: 40,
                                  icon: Icon(
                                    player.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    player.togglePlayPause();
                                    if (player.isPlaying) {
                                      _hideControlsAfterDelay();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              // Forward 10s
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(Icons.forward_10, color: Colors.white),
                                onPressed: () {
                                  final newPosition = player.position + const Duration(seconds: 10);
                                  if (newPosition < player.duration) {
                                    player.seek(newPosition);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        // Bottom Progress Bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Progress Slider
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.primary,
                                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                                      thumbColor: AppColors.primary,
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    ),
                                    child: Slider(
                                      value: player.progress,
                                      onChanged: (value) {
                                        player.seekToProgress(value);
                                      },
                                    ),
                                  ),
                                  // Time Labels
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          player.formatDuration(player.position),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                player.isMuted ? Icons.volume_off : Icons.volume_up,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed: player.toggleMute,
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              onPressed: _toggleFullScreen,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          player.formatDuration(player.duration),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading Indicator
                if (player.isLoading)
                  const CircularProgressIndicator(color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}
