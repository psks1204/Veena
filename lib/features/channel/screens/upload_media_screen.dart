import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';

/// Upload Media Screen
///
/// Allows creators to upload audio or video files with an optional thumbnail.
/// Displays real-time upload progress and supports retry on failure.
class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({super.key, this.initialMediaType = MediaType.audio});

  final MediaType initialMediaType;

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late MediaType _mediaType;

  // Selected media file
  List<int>? _mediaBytes;
  String? _mediaFileName;
  String? _mediaFileSizeLabel;

  // Selected thumbnail
  List<int>? _thumbnailBytes;
  String? _thumbnailFileName;

  // Whether the upload finished successfully (shows brief "done" state)
  bool _uploadDone = false;

  @override
  void initState() {
    super.initState();
    _mediaType = widget.initialMediaType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickMediaFile() async {
    FileType type = _mediaType == MediaType.audio
        ? FileType.audio
        : FileType.video;

    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final sizeKb = file.bytes!.length / 1024;
    final sizeLabel = sizeKb < 1024
        ? '${sizeKb.toStringAsFixed(1)} KB'
        : '${(sizeKb / 1024).toStringAsFixed(1)} MB';

    setState(() {
      _mediaBytes = file.bytes;
      _mediaFileName = file.name;
      _mediaFileSizeLabel = sizeLabel;
    });
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _thumbnailBytes = bytes;
      _thumbnailFileName = image.name;
    });
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mediaBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a media file first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final provider = context.read<ChannelProvider>();
    final ok = await provider.uploadMedia(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      mediaType: _mediaType == MediaType.audio ? 'AUDIO' : 'VIDEO',
      mediaBytes: _mediaBytes!,
      mediaFileName: _mediaFileName!,
      thumbnailBytes: _thumbnailBytes,
      thumbnailFileName: _thumbnailFileName,
    );

    if (!mounted) return;
    if (ok) {
      // Show "done" state briefly so user sees the 100% completion
      setState(() => _uploadDone = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      provider.resetUploadState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload successful! Your media is pending review.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      // Error is shown inline via the error section
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mediaType == MediaType.audio ? 'Upload Music' : 'Upload Video',
          style: theme.textTheme.headlineMedium,
        ),
      ),
      body: Consumer<ChannelProvider>(
        builder: (context, provider, _) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding + bottomInset,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Media type toggle ───────────────────────────
                    if (!provider.isUploading) ...[
                      _SectionLabel('Type'),
                      const SizedBox(height: AppSpacing.xs),
                      SegmentedButton<MediaType>(
                        segments: const [
                          ButtonSegment(
                            value: MediaType.audio,
                            icon: Icon(Icons.audio_file_rounded),
                            label: Text('Music'),
                          ),
                          ButtonSegment(
                            value: MediaType.video,
                            icon: Icon(Icons.video_file_rounded),
                            label: Text('Video'),
                          ),
                        ],
                        selected: {_mediaType},
                        onSelectionChanged: (s) {
                          setState(() {
                            _mediaType = s.first;
                            // Clear previously picked file when type changes
                            _mediaBytes = null;
                            _mediaFileName = null;
                            _mediaFileSizeLabel = null;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? AppColors.primary.withOpacity(0.15)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Title ─────────────────────────────────────
                      _SectionLabel('Title *'),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter a title for your upload',
                        ),
                        maxLength: 200,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Description ───────────────────────────────
                      _SectionLabel('Description (optional)'),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          hintText: 'Add a short description…',
                        ),
                        maxLines: 3,
                        maxLength: 1000,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Media file picker ─────────────────────────
                      _SectionLabel(
                        _mediaType == MediaType.audio
                            ? 'Audio File *'
                            : 'Video File *',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _FilePicker(
                        isDark: isDark,
                        fileName: _mediaFileName,
                        fileSize: _mediaFileSizeLabel,
                        icon: _mediaType == MediaType.audio
                            ? Icons.audio_file_rounded
                            : Icons.video_file_rounded,
                        label: 'Select file',
                        onPick: _pickMediaFile,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Thumbnail picker ──────────────────────────
                      _SectionLabel('Thumbnail (optional)'),
                      const SizedBox(height: AppSpacing.xs),
                      _FilePicker(
                        isDark: isDark,
                        fileName: _thumbnailFileName,
                        icon: Icons.image_rounded,
                        label: 'Select thumbnail',
                        onPick: _pickThumbnail,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // ── Upload progress ───────────────────────────────
                    if (provider.isUploading || _uploadDone) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _uploadDone
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  size: 64,
                                  color: AppColors.success,
                                  key: ValueKey('done'),
                                )
                              : const Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 64,
                                  color: AppColors.primary,
                                  key: ValueKey('uploading'),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _uploadDone ? 'Upload Complete!' : 'Uploading…',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _uploadDone ? AppColors.success : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LinearProgressIndicator(
                        value: _uploadDone
                            ? 1.0
                            : (provider.uploadProgress > 0
                                  ? provider.uploadProgress
                                  : null),
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        color: _uploadDone
                            ? AppColors.success
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _uploadDone
                            ? '100% — Done!'
                            : (provider.uploadProgress > 0
                                  ? '${(provider.uploadProgress * 100).toStringAsFixed(0)}%'
                                  : 'Preparing…'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _uploadDone
                              ? AppColors.success
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // ── Error + Retry ─────────────────────────────────
                    if (provider.uploadError != null &&
                        !provider.isUploading) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Upload failed. Please try again.',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ── Upload button ─────────────────────────────────
                    if (!provider.isUploading)
                      FilledButton.icon(
                        onPressed: _upload,
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          provider.uploadError != null
                              ? 'Retry Upload'
                              : 'Upload',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onPick,
    this.fileName,
    this.fileSize,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onPick;
  final String? fileName;
  final String? fileSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = fileName != null;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: hasFile
                ? AppColors.primary.withOpacity(0.5)
                : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_outline_rounded : icon,
              color: hasFile ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? fileName! : label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasFile
                          ? null
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fileSize != null)
                    Text(
                      fileSize!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
