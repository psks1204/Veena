import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/channel_provider.dart';

/// Channel Name Setup Screen
///
/// Shown once after first login to let users customise their channel name.
/// Pre-filled with the Google display name. Can be skipped.
/// Mirrors the isFirstLogin pattern from EditProfileScreen.
class ChannelSetupScreen extends StatefulWidget {
  const ChannelSetupScreen({super.key, this.initialName});

  /// Pre-fill value — usually the user's display name from Google
  final String? initialName;

  @override
  State<ChannelSetupScreen> createState() => _ChannelSetupScreenState();
}

class _ChannelSetupScreenState extends State<ChannelSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static final _nameRegex = RegExp(r'^[a-zA-Z0-9 \-_]+$');

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Channel name is required';
    if (v.length < 3) return 'Must be at least 3 characters';
    if (!_nameRegex.hasMatch(v)) {
      return 'Only letters, numbers, spaces, hyphens and underscores allowed';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ChannelProvider>();
    final name = _nameController.text.trim();

    final success = await provider.createChannel(channelName: name);
    if (!mounted) return;

    if (success) {
      await provider.markChannelSetupDone();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save channel name'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _skip() async {
    await context.read<ChannelProvider>().markChannelSetupDone();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      // Prevent back-button dismissal — must save or skip
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Title
                      Text(
                        'Name your channel',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Subtitle
                      Text(
                        'This is how your content will appear to listeners.\nYou can change it later from your profile.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Form
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _nameController,
                          validator: _validate,
                          maxLength: 80,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: InputDecoration(
                            labelText: 'Channel name',
                            hintText: 'e.g. Classical Vibes',
                            prefixIcon: const Icon(Icons.person_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Save button
                      Consumer<ChannelProvider>(
                        builder: (context, provider, _) {
                          return FilledButton(
                            onPressed: provider.isLoading ? null : _save,
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
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Skip
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
