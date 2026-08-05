import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Date of Birth Gate Screen
///
/// Mandatory, non-dismissible screen shown before a user can enter the app
/// if their profile has no birth date on file. There is no skip or back
/// option — the date of birth is required so we can apply age-appropriate
/// restrictions (e.g. hiding social features from under-13 users).
class DateOfBirthGateScreen extends StatefulWidget {
  const DateOfBirthGateScreen({super.key, this.initialName});

  /// Fallback name (e.g. from Google auth) used if the profile has none yet.
  final String? initialName;

  @override
  State<DateOfBirthGateScreen> createState() => _DateOfBirthGateScreenState();
}

class _DateOfBirthGateScreenState extends State<DateOfBirthGateScreen> {
  DateTime? _selectedDate;
  bool _isSaving = false;
  String? _error;

  int? get _selectedAge {
    final date = _selectedDate;
    if (date == null) return null;
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _continue() async {
    if (_selectedDate == null) {
      setState(() => _error = 'Please select your date of birth to continue');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final provider = context.read<ProfileProvider>();
    final existingName = provider.profile?.name?.trim();
    final fallbackName = widget.initialName?.trim();
    final nameToSend = (existingName != null && existingName.isNotEmpty)
        ? existingName
        : (fallbackName ?? '');

    final success = await provider.updateProfile(
      name: nameToSend,
      birthDate: _selectedDate,
    );

    if (!mounted) return;

    if (success) {
      provider.markDobSetupDone();
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _error = provider.error ?? 'Failed to save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMinorSelection = (_selectedAge ?? 99) < 13;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Icon(
                      Icons.cake_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      "When's your birthday?",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We need your date of birth to give you an '
                      'age-appropriate experience. This is required to '
                      'continue.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl + 8),

                    GestureDetector(
                      onTap: _isSaving ? null : _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: _error != null
                              ? Border.all(color: AppColors.error, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? DateFormat(
                                        'dd MMMM yyyy',
                                      ).format(_selectedDate!)
                                    : 'Select your birth date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDate != null
                                      ? (isDark
                                            ? Colors.white
                                            : Colors.black87)
                                      : (isDark
                                            ? Colors.white38
                                            : Colors.black38),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    if (isMinorSelection) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Since you\'re under 13, Reels and My '
                                'Channel won\'t be available on your '
                                'account.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl + 8),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary
                              .withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
