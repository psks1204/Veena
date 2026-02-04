import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/fullscreen_web.dart' if (dart.library.io) '../../core/utils/fullscreen_stub.dart' as fullscreen;

/// Fullscreen video overlay for Web
/// 
/// IMPORTANT: Only ONE VideoPlayer widget should use the controller at a time.
/// NowPlayingPanel checks [isFullscreenActive] to hide its VideoPlayer when this is shown.
class WebVideoFullscreen {
  static OverlayEntry? _overlayEntry;
  
  /// Track if fullscreen is currently active
  /// NowPlayingPanel should check this and NOT render VideoPlayer when true
  static bool isFullscreenActive = false;

  /// Callback to notify listeners when fullscreen state changes
  static VoidCallback? onStateChanged;

  /// Show fullscreen video overlay
  static void show(BuildContext context, VideoPlayerController controller) {
    if (isFullscreenActive) return;
    
    // Store playing state before transition
    final wasPlaying = controller.value.isPlaying;
    
    // Mark fullscreen as active BEFORE creating overlay
    // This will cause NowPlayingPanel to rebuild and hide its VideoPlayer
    isFullscreenActive = true;
    onStateChanged?.call();

    // Request browser fullscreen
    try {
      fullscreen.requestFullscreen();
    } catch (e) {
      debugPrint('Fullscreen error: $e');
    }

    // Small delay to allow NowPlayingPanel to rebuild and remove its VideoPlayer
    // before we create ours
    Future.delayed(const Duration(milliseconds: 50), () {
      _overlayEntry = OverlayEntry(
        builder: (context) => _FullscreenOverlay(
          controller: controller,
          wasPlaying: wasPlaying,
          onClose: () => hide(controller, wasPlaying),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
      
      // Resume playback after overlay is inserted
      if (wasPlaying && !controller.value.isPlaying) {
        controller.play();
      }
    });
  }

  /// Hide fullscreen overlay and restore state
  static void hide(VideoPlayerController controller, bool wasPlaying) {
    if (!isFullscreenActive) return;
    
    // Store current playing state
    final isCurrentlyPlaying = controller.value.isPlaying;

    // Remove overlay first
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Exit browser fullscreen
    try {
      fullscreen.exitFullscreen();
    } catch (e) {
      debugPrint('Exit fullscreen error: $e');
    }

    // Mark fullscreen as inactive AFTER removing overlay
    // This allows NowPlayingPanel to rebuild and show its VideoPlayer
    isFullscreenActive = false;
    onStateChanged?.call();
    
    // Restore playback after a small delay to allow NowPlayingPanel to rebuild
    if (isCurrentlyPlaying) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!controller.value.isPlaying) {
          controller.play();
        }
      });
    }
  }
}

class _FullscreenOverlay extends StatefulWidget {
  const _FullscreenOverlay({
    required this.controller,
    required this.wasPlaying,
    required this.onClose,
  });

  final VideoPlayerController controller;
  final bool wasPlaying;
  final VoidCallback onClose;

  @override
  State<_FullscreenOverlay> createState() => _FullscreenOverlayState();
}

class _FullscreenOverlayState extends State<_FullscreenOverlay> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Add listener to update UI when controller state changes
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: MouseRegion(
        onEnter: (_) => setState(() => _showControls = true),
        onExit: (_) => setState(() => _showControls = false),
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video (Centered & Aspect Ratio Preserved)
              Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              ),

              // Controls Overlay
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: Stack(
                  children: [
                    // Close Button (Top Right)
                    Positioned(
                      top: 24,
                      right: 24,
                      child: IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 36),
                        tooltip: 'Exit Fullscreen',
                      ),
                    ),

                    // Play/Pause Overlay (Center)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          widget.controller.value.isPlaying
                              ? widget.controller.pause()
                              : widget.controller.play();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 72,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
