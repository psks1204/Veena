import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/player_provider.dart';

/// Video Player Screen - Refined to fix layout and overlap issues
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _showControls = true;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _hideControlsAfterDelay();
    // Monitor orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 4), () {
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

  void _toggleFullscreen() {
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    setState(() {
      _isLandscape = !_isLandscape;
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final controller = player.videoController;
        final isValid = controller != null && 
                        controller.value.isInitialized &&
                        !controller.value.hasError;
        
        if (!isValid) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Loading video...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: WillPopScope(
            onWillPop: () async {
              if (_isLandscape) {
                _toggleFullscreen();
                return false;
              }
              return true;
            },
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // 1. Video Layer - Centered and respects aspect ratio
                  Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),

                  // 2. Controls & Metadata Overlay
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.2, 0.8, 1.0],
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top bar
                              _buildTopBar(player),
                              
                              const Spacer(),

                              // Controls and Metadata (Non-overlapping if possible)
                              _buildBottomUI(player),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Mini loading indicator
                  if (player.isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (_isLandscape) {
                _toggleFullscreen();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(
              _isLandscape ? Icons.arrow_back_rounded : Icons.keyboard_arrow_down_rounded, 
              color: Colors.white, 
              size: _isLandscape ? 24 : 32
            ),
          ),
          if (!_isLandscape)
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'PLAYING FROM PLAYLIST',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1.0, fontSize: 10),
                  ),
                  Text(
                    player.currentMedia?.title ?? 'Unknown',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomUI(PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isLandscape) ...[
            // Switch to audio button
             _buildSwitchToAudioButton(player),
            const SizedBox(height: 20),
            // Metadata
            _buildMetadata(player),
            const SizedBox(height: 10),
          ],
          
          // Progress bar
          _buildProgressBar(player),
          
          const SizedBox(height: 10),

          // Primary Controls (Play/Pause, Skip)
          _buildControls(player),

          if (!_isLandscape) ...[
            const SizedBox(height: 20),
            _buildFooterIcons(),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchToAudioButton(PlayerProvider player) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.music_note_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Switch to audio', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata(PlayerProvider player) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.currentMedia?.title ?? 'Unknown',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                player.currentMedia?.description ?? 'Unknown Artist',
                style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 26),
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerProvider player) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            trackHeight: 3,
          ),
          child: Slider(
            value: player.progress.clamp(0.0, 1.0),
            onChanged: (v) => player.seekToProgress(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(player.formatDuration(player.position), style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text(player.formatDuration(player.duration), style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle_rounded, color: Colors.white60, size: 22), 
          onPressed: () {}
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 38), 
              onPressed: () => player.previous()
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: player.togglePlayPause,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(
                  player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                  size: 38, 
                  color: Colors.black
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 38), 
              onPressed: () => player.next()
            ),
          ],
        ),
        IconButton(
          icon: Icon(_isLandscape ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white, size: 26), 
          onPressed: _toggleFullscreen
        ),
      ],
    );
  }

  Widget _buildFooterIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.devices_rounded, color: Colors.white60, size: 20),
        const Spacer(),
        const Icon(Icons.share_outlined, color: Colors.white60, size: 18),
        const SizedBox(width: 20),
        const Icon(Icons.list_rounded, color: Colors.white60, size: 22),
      ],
    );
  }
}
