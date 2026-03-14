import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Terms of Service Screen
///
/// Displays the Veena Music terms and services.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Terms of Service',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Last Updated: 12 June 2025',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section 1
            _buildSectionTitle(theme, '1. Acceptance of Terms'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'By accessing or using the Veena Music app and website, you agree to be bound by these Terms of Service. If you do not agree, please do not use our services.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 2
            _buildSectionTitle(theme, '2. Content Ownership'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'All content provided on Veena Music, including but not limited to songs, videos, podcasts, and graphics, is the property of Veena Music or its content creators and is protected by copyright laws.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 3
            _buildSectionTitle(theme, '3. User Conduct'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Users agree to use the service only for lawful purposes. Unauthorized distribution, reproduction, or modification of content is strictly prohibited.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 4
            _buildSectionTitle(theme, '4. Subscriptions and Payments'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Details regarding subscription plans, payments, and refunds are outlined in our billing section. All payments are processed securely.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 5
            _buildSectionTitle(theme, '5. Termination'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Veena Music reserves the right to terminate or suspend access to our services at any time, without prior notice, for conduct that violates these Terms.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 6
            _buildSectionTitle(theme, '6. Contact Us'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'If you have any questions about these Terms, please contact us at info@veenamusiconline.com'),
            
            // Bottom padding for mini player
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildParagraph(
      ThemeData theme, ColorScheme colorScheme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.8),
        height: 1.6,
      ),
    );
  }
}
