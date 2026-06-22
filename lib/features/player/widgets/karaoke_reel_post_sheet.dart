import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/models/media_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../channel/providers/channel_provider.dart';
import '../services/karaoke_recording_service.dart';

/// Bottom sheet for posting a karaoke cover recording as a reel.
///
/// Shown after the user finishes recording their karaoke cover.
/// Pre-fills the title and lets the user edit before posting.
class KaraokeReelPostSheet extends StatefulWidget {
  const KaraokeReelPostSheet({
    super.key,
    required this.sourceMedia,
  });

  /// The original karaoke track the user sang along to.
  final MediaItem sourceMedia;

  @override
  State<KaraokeReelPostSheet> createState() => _KaraokeReelPostSheetState();
}

class _KaraokeReelPostSheetState extends State<KaraokeReelPostSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // Preview Player
  late final AudioPlayer _previewPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: '${widget.sourceMedia.title} - My Cover',
    );
    _descriptionController = TextEditingController();

    _previewPlayer = AudioPlayer();
    _initPreviewPlayer();
  }

  Future<void> _initPreviewPlayer() async {
    final path = context.read<KaraokeRecordingService>().recordedFilePath;
    if (path != null) {
      try {
        final dur = await _previewPlayer.setFilePath(path);
        if (dur != null) {
          setState(() {
            _duration = dur;
          });
        }
      } catch (e) {
        debugPrint('Error loading preview audio: $e');
      }
    }

    _previewPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _previewPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _previewPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
        if (state.processingState == ProcessingState.completed) {
          _previewPlayer.seek(Duration.zero);
          _previewPlayer.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _postAsReel() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    // Stop playback before uploading
    await _previewPlayer.pause();

    final recordingService = context.read<KaraokeRecordingService>();
    final channelProvider = context.read<ChannelProvider>();

    channelProvider.resetUploadState();

    final success = await recordingService.uploadAsReel(
      channelProvider: channelProvider,
      sourceKaraokeItem: widget.sourceMedia,
      title: title,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Show success briefly, then close
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      channelProvider.resetUploadState();
      Navigator.of(context).pop(true); // true = posted successfully
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<KaraokeRecordingService>(
      builder: (context, recordingService, _) {
        final isUploading = recordingService.isUploading;
        final isDone = recordingService.isDone;
        final hasError = recordingService.hasError;
        final uploadProgress = context.watch<ChannelProvider>().uploadProgress;

        return Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white30 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFF6B6B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDone
                                  ? 'Reel Posted! 🎉'
                                  : 'Post Your Cover',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Duration: ${KaraokeRecordingService.formatDuration(recordingService.recordingDuration)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Source track info
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: widget.sourceMedia.thumbnailUrl != null
                              ? Image.network(
                                  widget.sourceMedia.thumbnailUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white38,
                                    size: 20,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cover of',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${widget.sourceMedia.title} • ${widget.sourceMedia.artistName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Success state
                  if (isDone) ...[
                    const SizedBox(height: 32),
                    const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cover has been posted as a reel!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'It will be visible on your channel after review.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],

                  // Form (hidden during upload/done)
                  if (!isUploading && !isDone) ...[
                    const SizedBox(height: 20),

                    // Preview player
                    _buildPreviewPlayer(theme, isDark),

                    const SizedBox(height: 20),

                    // Title field
                    Text(
                      'Title',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _titleController,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'Give your cover a title',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description field
                    Text(
                      'Description (optional)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Add a description...',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    // Error message
                    if (hasError && recordingService.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recordingService.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        // Discard button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _previewPlayer.pause();
                              recordingService.discard();
                              Navigator.of(context).pop(false);
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Discard'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white70
                                  : Colors.black54,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.black12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Post button
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _postAsReel,
                            icon: const Icon(Icons.rocket_launch_rounded),
                            label: const Text('Post as Reel'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Upload progress
                  if (isUploading) ...[
                    const SizedBox(height: 32),
                    const Center(
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading your cover...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      child: LinearProgressIndicator(
                        value: uploadProgress > 0 ? uploadProgress : null,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      uploadProgress > 0
                          ? '${(uploadProgress * 100).toStringAsFixed(0)}%'
                          : 'Preparing...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],

                  // Bottom safe area padding
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        AppSpacing.md,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewPlayer(ThemeData theme, bool isDark) {
    final durationText = KaraokeRecordingService.formatDuration(_duration);
    final positionText = KaraokeRecordingService.formatDuration(_position);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          IconButton(
            onPressed: () {
              if (_isPlaying) {
                _previewPlayer.pause();
              } else {
                _previewPlayer.play();
              }
            },
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: AppColors.primary,
              size: 40,
            ),
            padding: EdgeInsets.zero,
          ),
          
          // Slider and times
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble().clamp(
                      0.0,
                      _duration.inMilliseconds.toDouble() > 0.0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                    ),
                    max: _duration.inMilliseconds.toDouble() > 0.0
                        ? _duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (val) {
                      _previewPlayer.seek(Duration(milliseconds: val.round()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        positionText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Text(
                        durationText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
