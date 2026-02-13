import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Privacy Policy Screen
///
/// Displays the Veena Music privacy policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
              'Privacy Policy',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Effective Date: 12 June 2025',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              'Website & App: Veena Music',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section 1
            _buildSectionTitle(theme, '1. Introduction'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Welcome to Veena Music, your destination for Rajasthani songs, bhakti content, films, podcasts, videos, and popular TV serial telecasts. This Privacy Policy explains how we collect, use, store, and protect your data, ensuring full compliance with applicable laws.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'By using our website, app, and services, you acknowledge that you have read and understood this policy.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 2
            _buildSectionTitle(theme, '2. Information We Collect'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We collect various types of information, including:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Personal Information such as name, email, phone number, and payment details when subscribing or purchasing'),
            _buildBulletPoint(theme, colorScheme,
                'Usage Data including browsing patterns, interactions with our music, videos, and podcasts'),
            _buildBulletPoint(theme, colorScheme,
                'Technical Data such as device type, IP address, cookies, and analytics data for site improvement'),
            _buildBulletPoint(theme, colorScheme,
                'Content Usage Data related to streaming, downloading, or purchasing copyrighted material'),
            const SizedBox(height: AppSpacing.lg),

            // Section 3
            _buildSectionTitle(theme, '3. How We Use Your Information'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Veena Music uses collected information to:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Provide access to our Rajasthani songs, bhakti content, films, podcasts, and videos'),
            _buildBulletPoint(theme, colorScheme,
                'Offer personalized recommendations based on user preferences'),
            _buildBulletPoint(theme, colorScheme,
                'Process subscriptions, payments, and transactions securely'),
            _buildBulletPoint(theme, colorScheme,
                'Enforce copyright protection and prevent unauthorized distribution'),
            _buildBulletPoint(theme, colorScheme,
                'Improve our digital platform and user experience'),
            const SizedBox(height: AppSpacing.lg),

            // Section 4
            _buildSectionTitle(theme, '4. Third-Party Services and Data Sharing'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We may share data with:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Streaming Platforms such as YouTube, Spotify, JioSaavn, Gaana, Amazon Music, iTunes, and others'),
            _buildBulletPoint(theme, colorScheme,
                'Analytics Providers to understand audience engagement and optimize content'),
            _buildBulletPoint(theme, colorScheme,
                'Legal Authorities in case of copyright disputes or infringement claims'),
            _buildBulletPoint(theme, colorScheme,
                'Payment Processors for securely handling transactions'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We do not sell or misuse personal data for commercial purposes.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 5
            _buildSectionTitle(theme, '5. Copyright Protection and Content Usage'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'All songs, podcasts, videos, and telecasts published under Veena Music are copyright-protected'),
            _buildBulletPoint(theme, colorScheme,
                'Unauthorized uploading, distribution, or reproduction of content is strictly prohibited'),
            _buildBulletPoint(theme, colorScheme,
                'If you find copyright violations, report them via info@veenamusiconline.com'),
            const SizedBox(height: AppSpacing.lg),

            // Section 6
            _buildSectionTitle(theme, '6. Cookies and Tracking Technologies'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Veena Music uses cookies and analytics tools to improve user experience'),
            _buildBulletPoint(theme, colorScheme,
                'Users can manage cookies via browser settings'),
            const SizedBox(height: AppSpacing.lg),

            // Section 7
            _buildSectionTitle(theme, '7. Data Security Measures'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We implement strict security protocols to safeguard your data from unauthorized access, breaches, or misuse.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 8
            _buildSectionTitle(theme, '8. User Rights and Data Control'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Users can request data deletion, access, or updates'),
            _buildBulletPoint(theme, colorScheme,
                'For any privacy concerns, contact info@veenamusiconline.com'),
            const SizedBox(height: AppSpacing.lg),

            // Section 9
            _buildSectionTitle(theme, '9. Policy Updates'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'We may update this Privacy Policy periodically. Users will be notified of significant changes.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 10
            _buildSectionTitle(theme, '10. Contact Information'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'For legal and privacy inquiries, reach us at:'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Veena Music',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '(Oriental Audio Visual Electronics)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.email_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'info@veenamusiconline.com',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.language_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Veena Music',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

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

  Widget _buildBulletPoint(
      ThemeData theme, ColorScheme colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.md, bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
