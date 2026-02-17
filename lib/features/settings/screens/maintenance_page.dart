import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Maintenance Page
///
/// Shown when the server returns maintenanceMode: true.
/// Full-screen blocking page — the user cannot bypass this.
class MaintenancePage extends StatelessWidget {
  final VoidCallback? onRetry;

  const MaintenancePage({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated wrench icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: -0.1, end: 0.1),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.rotate(angle: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_circle_rounded,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'Under Maintenance',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'We\'re making Veena even better!\nPlease check back shortly.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 40),

              // Retry button
              if (onRetry != null)
                SizedBox(
                  width: 200,
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Bottom hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary.withOpacity(0.5)
                        : AppColors.lightTextSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'This usually takes just a few minutes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary.withOpacity(0.5)
                          : AppColors.lightTextSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
