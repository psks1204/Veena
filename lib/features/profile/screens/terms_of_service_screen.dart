import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Terms of Service Screen
///
/// Displays the Veena Music terms of service, subscription policies,
/// intellectual property rights, and DMCA copyright notice procedures.
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
              'Last Updated: February 2026',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              'Entity: Oriental Audio Visual Electronics (Veena Music)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Section 1
            _buildSectionTitle(theme, '1. Acceptance of Terms'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'These Terms of Service ("Terms") constitute a legally binding agreement between you and Oriental Audio Visual Electronics ("Veena Music", "we", "us", or "our"). By downloading, installing, accessing, or using the Veena Music mobile apps, web platform (veenamusiconline.com), or related streaming services, you acknowledge that you have read, understood, and agree to be bound by these Terms.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 2
            _buildSectionTitle(theme, '2. Eligibility and Account Registration'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'You must be at least 13 years old (or the age of majority in your jurisdiction) to use Veena Music. When registering an account, you agree to provide accurate, complete, and current information. You are solely responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 3
            _buildSectionTitle(theme, '3. Intellectual Property Rights & Ownership'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'All music recordings, master tracks, compositions, lyrics, album artworks, videos, brand names, and software associated with Veena Music are the exclusive intellectual property of Oriental Audio Visual Electronics or its licensed copyright holders. We grant you a limited, non-exclusive, non-transferable, revocable license to access and stream content strictly for personal, non-commercial use.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 4
            _buildSectionTitle(theme, '4. Prohibited Uses'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Users agree not to engage in any of the following unauthorized activities:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Downloading, ripping, capturing, or re-broadcasting audio or video streams outside authorized in-app offline caching.'),
            _buildBulletPoint(theme, colorScheme,
                'Reverse engineering, decompiling, or attempting to derive the source code of the platform.'),
            _buildBulletPoint(theme, colorScheme,
                'Using automated bots, scrapers, or scripts to access or extract data from the service.'),
            _buildBulletPoint(theme, colorScheme,
                'Circumventing any digital rights management (DRM), geo-filtering, or advertising systems.'),
            _buildBulletPoint(theme, colorScheme,
                'Uploading abusive, defamatory, or infringing content in channel comments or community features.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 5
            _buildSectionTitle(theme, '5. Subscriptions, Payments & Free Tiers'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Veena Music offers both ad-supported free tiers and paid premium subscription tiers:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Ad-Supported Free Tier: Grants access to selected streaming content with contextual and third-party advertising (served via Google AdSense/AdMob).'),
            _buildBulletPoint(theme, colorScheme,
                'Premium Subscriptions: Provides ad-free streaming, high-fidelity audio, and premium catalog access. Subscriptions are billed in advance on a recurring basis.'),
            _buildBulletPoint(theme, colorScheme,
                'Payments & Refunds: Payments are processed securely via certified gateways (e.g. Razorpay). Subscription fees are non-refundable except where required by applicable law.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 6
            _buildSectionTitle(theme, '6. Copyright Protection & DMCA Takedowns'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We respect the intellectual property rights of others. If you believe that any content hosted on Veena Music infringes upon your copyright, please submit a written DMCA / Copyright Notice to our designated agent at info@veenamusiconline.com with the specific URL/track details and proof of ownership.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 7
            _buildSectionTitle(theme, '7. Disclaimer of Warranties'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'The service is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, whether express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, or non-infringement.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 8
            _buildSectionTitle(theme, '8. Limitation of Liability'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'To the maximum extent permitted by applicable law, Oriental Audio Visual Electronics and its officers, directors, and employees shall not be liable for any indirect, incidental, punitive, or consequential damages resulting from your use of or inability to use the service.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 9
            _buildSectionTitle(theme, '9. Governing Law & Jurisdiction'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'These Terms shall be governed by and construed in accordance with the laws of India. Any legal action or proceeding arising under these Terms shall be subject to the exclusive jurisdiction of the competent courts located in Jaipur, Rajasthan, India.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 10
            _buildSectionTitle(theme, '10. Contact Information'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'For legal inquiries or questions regarding these Terms, contact us at:'),
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
                    'Veena Music (Oriental Audio Visual Electronics)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Haldia House, Johri Bazar, Jaipur, Rajasthan 302003, India',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Email: info@veenamusiconline.com',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
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
