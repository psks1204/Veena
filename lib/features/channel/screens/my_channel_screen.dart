import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';
import 'upload_media_screen.dart';

/// My Channel Screen
///
/// Shows the current user's channel details, upload CTAs,
/// and a paginated list of their uploaded media.
class MyChannelScreen extends StatefulWidget {
  const MyChannelScreen({super.key});

  @override
  State<MyChannelScreen> createState() => _MyChannelScreenState();
}

class _MyChannelScreenState extends State<MyChannelScreen> {
  final _scrollController = ScrollController();
  ApprovalStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChannelProvider>();
      provider.loadMedia(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChannelProvider>().loadMedia();
    }
  }

  void _applyFilter(ApprovalStatus? status) {
    setState(() => _filter = status);
    context.read<ChannelProvider>().loadMedia(
      approvalFilter: status?.name.toUpperCase(),
      refresh: true,
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );
    if (image == null || !mounted) return;

    final provider = context.read<ChannelProvider>();
    bool success;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      success = await provider.uploadChannelImage(
        bytes: bytes,
        fileName: image.name,
      );
    } else {
      success = await provider.uploadChannelImage(filePath: image.path);
    }

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to upload image'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToUpload(MediaType type) {
    context.read<ChannelProvider>().resetUploadState();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UploadMediaScreen(initialMediaType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Channel', style: theme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit channel',
            onPressed: () => _showEditChannelSheet(context),
          ),
        ],
      ),
      body: Consumer<ChannelProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.channel == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final channel = provider.channel;

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadMedia(refresh: true);
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // ── Channel Header ──────────────────────────────────
                _ChannelHeader(
                  channel: channel,
                  isDark: isDark,
                  onEditImage: _pickAndUploadImage,
                  isLoading: provider.isLoading,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Upload CTAs ─────────────────────────────────────
                Text('Upload Content', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _UploadButton(
                        icon: Icons.audio_file_rounded,
                        label: 'Upload Music',
                        onTap: () => _navigateToUpload(MediaType.audio),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _UploadButton(
                        icon: Icons.video_file_rounded,
                        label: 'Upload Video',
                        onTap: () => _navigateToUpload(MediaType.video),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Media filter chips ──────────────────────────────
                Text('My Uploads', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _FilterChips(current: _filter, onSelected: _applyFilter),
                const SizedBox(height: AppSpacing.sm),

                // ── Media list ──────────────────────────────────────
                if (provider.mediaLoading && provider.media.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.media.isEmpty)
                  _EmptyMedia(isDark: isDark)
                else
                  ...provider.media.map(
                    (item) => _MediaTile(
                      item: item,
                      isDark: isDark,
                      onDelete: () => _confirmDelete(context, provider, item),
                    ),
                  ),

                if (provider.mediaLoading && provider.media.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ChannelProvider provider,
    UserMediaResponse item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete media?'),
        content: Text('Delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await provider.deleteMedia(item.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not delete. Approved media cannot be removed.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditChannelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChannelProvider>(),
        child: const _EditChannelSheet(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ──────────────────────────────────────────────────────────────────────────────

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({
    required this.channel,
    required this.isDark,
    required this.onEditImage,
    required this.isLoading,
  });

  final ChannelResponse? channel;
  final bool isDark;
  final VoidCallback onEditImage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Channel image
        GestureDetector(
          onTap: onEditImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: channel?.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: channel!.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(80),
                        errorWidget: (_, __, ___) => _placeholder(80),
                      )
                    : _placeholder(80),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Channel details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channel?.channelName ?? 'My Channel',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (channel?.channelHandle != null)
                Text(
                  '@${channel!.channelHandle}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  _Stat(
                    value: '${channel?.totalMedia ?? 0}',
                    label: 'uploads',
                    isDark: isDark,
                  ),
                  _Stat(
                    value: '${channel?.subscriberCount ?? 0}',
                    label: 'subscribers',
                    isDark: isDark,
                  ),
                  _Stat(
                    value: '${channel?.totalViews ?? 0}',
                    label: 'views',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.isDark});
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        side: const BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onSelected});
  final ApprovalStatus? current;
  final ValueChanged<ApprovalStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, null, 'All'),
          const SizedBox(width: AppSpacing.xs),
          _chip(context, ApprovalStatus.pending, 'Pending'),
          const SizedBox(width: AppSpacing.xs),
          _chip(context, ApprovalStatus.approved, 'Approved'),
          const SizedBox(width: AppSpacing.xs),
          _chip(context, ApprovalStatus.rejected, 'Rejected'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, ApprovalStatus? status, String label) {
    final selected = current == status;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(status),
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.isDark,
    required this.onDelete,
  });

  final UserMediaResponse item;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(item.approvalStatus);
    final statusLabel = item.approvalStatus.name.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: item.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.thumbnailUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _leadingIcon(item.mediaType),
                )
              : _leadingIcon(item.mediaType),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              item.mediaType == MediaType.audio ? 'Audio' : 'Video',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        trailing: item.approvalStatus != ApprovalStatus.approved
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.error,
                tooltip: 'Delete',
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }

  Widget _leadingIcon(MediaType type) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(
        type == MediaType.audio
            ? Icons.audio_file_rounded
            : Icons.video_file_rounded,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }

  Color _statusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return AppColors.success;
      case ApprovalStatus.rejected:
        return AppColors.error;
      case ApprovalStatus.pending:
        return Colors.orange;
    }
  }
}

class _EmptyMedia extends StatelessWidget {
  const _EmptyMedia({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.upload_rounded,
            size: 64,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No uploads yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap Upload Music or Upload Video to get started.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Edit Channel Bottom Sheet ─────────────────────────────────────────────────

class _EditChannelSheet extends StatefulWidget {
  const _EditChannelSheet();

  @override
  State<_EditChannelSheet> createState() => _EditChannelSheetState();
}

class _EditChannelSheetState extends State<_EditChannelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final channel = context.read<ChannelProvider>().channel;
    _nameController.text = channel?.channelName ?? '';
    _handleController.text = channel?.channelHandle ?? '';
    _descController.text = channel?.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ChannelProvider>();
    final ok = await provider.updateChannel(
      channelName: _nameController.text.trim(),
      channelHandle: _handleController.text.trim().isEmpty
          ? null
          : _handleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Channel', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Channel name'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _handleController,
                decoration: const InputDecoration(
                  labelText: 'Handle (optional)',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              Consumer<ChannelProvider>(
                builder: (context, provider, _) => FilledButton(
                  onPressed: provider.isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
