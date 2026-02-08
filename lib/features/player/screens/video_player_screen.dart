import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/player_provider.dart';
import '../../../core/models/media_item.dart';
import '../../../shared/widgets/full_player.dart';
import '../../../shared/widgets/seekbar_control.dart';
import '../../../core/utils/fullscreen_web.dart' if (dart.library.io) '../../../core/utils/fullscreen_stub.dart' as fullscreen;

/// Video Player Screen - Refined to fix layout and overlap issues
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _showControls = true;
  bool _isLandscape = false;
  bool _isFullscreen = false;
  bool _isClosing = false; // Prevent multiple pop attempts
  late final FocusNode _focusNode;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // On web, start with controls hidden (will auto-hide)
    // On mobile, start with controls visible
    if (kIsWeb) {
      _hideControlsAfterDelay();
    }
    
    // Monitor orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Listen for media changes to detect video -> audio transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = context.read<PlayerProvider>();
      player.addListener(_onPlayerChanged);
    });
  }
  
  /// Called when player state changes - check if we need to switch to audio player
  void _onPlayerChanged() {
    if (!mounted || _isClosing) return;
    
    final player = context.read<PlayerProvider>();
    final currentMedia = player.currentMedia;
    
    // If current media is audio (not video), switch to full audio player
    if (currentMedia != null && currentMedia.isAudio) {
      _isClosing = true; // Prevent multiple navigation attempts
      debugPrint('[VideoPlayerScreen] Detected audio track, switching to FullPlayer');
      // Use post frame callback to avoid Navigator lock issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          // Navigate to FullPlayer, replacing current video screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => _buildFullPlayer(player, currentMedia),
            ),
          );
        }
      });
    }
  }

  /// Build FullPlayer widget with current player state
  Widget _buildFullPlayer(PlayerProvider player, dynamic media) {
    return Consumer<PlayerProvider>(
      builder: (context, p, _) {
        final m = p.currentMedia;
        return FullPlayer(
          trackTitle: m?.title ?? 'Unknown',
          artistName: m?.artistName ?? 'Unknown Artist',
          albumName: m?.artistName ?? '',
          artworkUrl: m?.thumbnailUrl,
          isPlaying: p.isPlaying,
          progress: p.progress,
          duration: p.duration,
          currentPosition: p.position,
          isShuffleOn: p.shuffleEnabled,
          repeatMode: p.repeatMode,
          lyrics: p.currentLyrics,
          activeLyricIndex: p.activeLyricIndex,
          onPlayPause: p.togglePlayPause,
          onPrevious: p.previous,
          onNext: p.next,
          onShuffle: p.toggleShuffle,
          onRepeat: p.toggleRepeatMode,
          onSeek: p.seekToProgress,
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }



  void _hideControlsAfterDelay() {
    // Cancel any existing timer
    _hideControlsTimer?.cancel();
    
    // On mobile (non-fullscreen), always show controls - don't hide
    if (!kIsWeb && !_isLandscape && !_isFullscreen) {
      return; // Don't hide on mobile unless in fullscreen
    }
    
    // Start new timer - 3 seconds delay
    _hideControlsTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted && context.read<PlayerProvider>().isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    // On mobile (non-fullscreen), controls are always visible
    if (!kIsWeb && !_isLandscape && !_isFullscreen) {
      return; // Controls always visible on mobile
    }
    
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _showControlsOnHover() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _hideControlsAfterDelay();
  }


  void _handleKeyEvent(KeyEvent event, PlayerProvider player) {
    if (event is KeyDownEvent) {
      // Space bar - toggle play/pause
      if (event.logicalKey == LogicalKeyboardKey.space) {
        player.togglePlayPause();
        _showControlsOnHover();
      }
      // M key - toggle mute
      if (event.logicalKey == LogicalKeyboardKey.keyM) {
        player.toggleMute();
        _showControlsOnHover();
      }
      // Left/Right arrow - seek
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        final newPos = player.position - const Duration(seconds: 10);
        player.seek(newPos < Duration.zero ? Duration.zero : newPos);
        _showControlsOnHover();
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final newPos = player.position + const Duration(seconds: 10);
        player.seek(newPos > player.duration ? player.duration : newPos);
        _showControlsOnHover();
      }
      // F key - fullscreen
      if (event.logicalKey == LogicalKeyboardKey.keyF) {
        _toggleFullscreen();
      }
      // Escape key - go back
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _goBack();
      }
    }
  }

  void _goBack() {
    if (kIsWeb) {
      // On web, just close the video player
      Navigator.of(context).pop();
    } else {
      // On mobile, exit fullscreen first if in landscape
      if (_isLandscape) {
        _toggleFullscreen();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _toggleFullscreen() {
    if (kIsWeb) {
      // Web: Use JavaScript fullscreen API
      try {
        if (_isFullscreen) {
          fullscreen.exitFullscreen();
        } else {
          fullscreen.requestFullscreen();
        }
        setState(() {
          _isFullscreen = !_isFullscreen;
        });
      } catch (e) {
        debugPrint('Fullscreen error: $e');
      }
    } else {
      // Mobile: Use orientation-based fullscreen
      if (_isLandscape) {
        // Exiting fullscreen - show controls and restore portrait
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        setState(() {
          _isLandscape = false;
          _showControls = true; // Always show controls when exiting fullscreen
        });
      } else {
        // Entering fullscreen - hide controls after entering
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        setState(() {
          _isLandscape = true;
          _showControls = true; // Show controls briefly, then start hide timer
        });
        _hideControlsAfterDelay(); // Start hide timer in fullscreen
      }
    }
  }


  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _focusNode.dispose();
    
    // Remove player listener
    try {
      context.read<PlayerProvider>().removeListener(_onPlayerChanged);
    } catch (_) {}
    
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
          body: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (event) => _handleKeyEvent(event, player),
            child: MouseRegion(
              onHover: (_) => _showControlsOnHover(),
              onEnter: (_) => _showControlsOnHover(),
              child: WillPopScope(
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
            onPressed: _goBack,
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
    final linkedMedia = player.currentMedia?.linkedMedia;
    final hasLinkedAudio = linkedMedia != null && linkedMedia.mediaType == MediaType.audio;
    
    // Only show button if linked audio exists
    if (!hasLinkedAudio) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: GestureDetector(
        onTap: () {
          // Capture current position before switching
          final currentPosition = player.position;
          
          // Create MediaItem from LinkedMediaInfo and play it
          final audioItem = MediaItem(
            id: linkedMedia.id,
            title: linkedMedia.title,
            mediaType: linkedMedia.mediaType,
            thumbnailUrl: linkedMedia.thumbnailUrl,
            hlsUrl: linkedMedia.hlsUrl,
            status: MediaStatus.published,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            artist: linkedMedia.artist,
          );
          player.play(audioItem, startPosition: currentPosition);
          // Pop video player - the app.dart will show FullPlayer for audio
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.music_note_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'Listen to Audio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
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
    return SeekbarControl(
      progress: player.progress,
      duration: player.duration,
      currentPosition: player.position,
      onSeek: (v) => player.seekToProgress(v),
      isWeb: true, // Reuse web styling for video overlay
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
          icon: Icon(
            (kIsWeb ? _isFullscreen : _isLandscape) 
              ? Icons.fullscreen_exit_rounded 
              : Icons.fullscreen_rounded, 
            color: Colors.white, 
            size: 26
          ), 
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
