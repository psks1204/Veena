import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/open_url.dart';

/// Privacy Policy Screen
///
/// Displays the Veena Music privacy policy including full Google AdSense
/// and advertising cookie disclosures, GDPR/CCPA rights, and contact details.
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

            // Section 1: Introduction
            _buildSectionTitle(theme, '1. Introduction'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Welcome to Veena Music ("we", "our", or "us"), operated by Oriental Audio Visual Electronics. We are the pioneers and premier platform for Rajasthani music, devotional bhajans, folk songs, podcasts, and cultural content. We are committed to protecting your privacy and ensuring transparency about how your data is collected, used, and safeguarded.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'This Privacy Policy applies to our website (veenamusiconline.com), mobile applications (Android and iOS), and all associated services. By accessing or using our services, you consent to the practices described in this policy.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 2: Information We Collect
            _buildSectionTitle(theme, '2. Information We Collect'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We collect information to provide, personalize, and improve our services:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Account Information: Name, email address, phone number, and profile details when you register, log in, or subscribe.'),
            _buildBulletPoint(theme, colorScheme,
                'Usage & Streaming Data: Listening history, playlists, liked tracks, search queries, channel interactions, and app usage metrics.'),
            _buildBulletPoint(theme, colorScheme,
                'Device & Technical Data: IP address, device type, operating system version, browser type, unique device identifiers, network information, and crash reports.'),
            _buildBulletPoint(theme, colorScheme,
                'Payment Information: Subscription details and transaction identifiers. Note: We do not store full credit card numbers; payments are processed securely via certified payment gateways like Razorpay.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 3: How We Use Your Information
            _buildSectionTitle(theme, '3. How We Use Your Information'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'To deliver music streaming, curated playlists, devotional albums, and podcast content.'),
            _buildBulletPoint(theme, colorScheme,
                'To personalize recommendations, artist discovery, and user preferences.'),
            _buildBulletPoint(theme, colorScheme,
                'To process subscription billing, verify accounts, and manage orders.'),
            _buildBulletPoint(theme, colorScheme,
                'To display relevant, policy-compliant advertisements on free tiers.'),
            _buildBulletPoint(theme, colorScheme,
                'To protect intellectual property, prevent fraudulent activity, and enforce our Terms of Service.'),
            _buildBulletPoint(theme, colorScheme,
                'To analyze service performance, fix bugs, and enhance user experience.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 4: Google AdSense, AdMob & Third-Party Advertising
            _buildSectionTitle(theme, '4. Third-Party Advertising & Google AdSense'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We work with third-party advertising partners, including Google AdSense and Google AdMob, to serve advertisements on our web and mobile platforms to support our free content tier.'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Google as a Third-Party Vendor: Google uses cookies and unique identifiers to serve ads based on your prior visits to our website or other websites on the Internet.'),
            _buildBulletPoint(theme, colorScheme,
                'Advertising Cookies (DoubleClick / DART Cookie): Google\'s use of advertising cookies enables it and its partners to serve personalized or contextual ads to you based on your visits to our site and other sites across the web.'),
            _buildBulletPoint(theme, colorScheme,
                'Ad-Free Experience: Users who purchase a premium subscription receive an ad-free experience, and ad requests are completely disabled during their active subscription.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'You have the right to opt out of personalized advertising at any time:'),
            const SizedBox(height: AppSpacing.xs),
            _buildLinkCard(
              context,
              title: 'Google Ads Settings',
              description: 'Customize or opt out of personalized Google Ads across the web.',
              url: 'https://www.google.com/settings/ads',
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildLinkCard(
              context,
              title: 'AboutAds Consumer Choice',
              description: 'Opt out of participating third-party advertising networks.',
              url: 'https://www.aboutads.info/choices',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 5: Cookies and Tracking Technologies
            _buildSectionTitle(theme, '5. Cookies & Tracking Technologies'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We use cookies, local storage, and similar technologies to enhance your experience:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Essential Cookies: Necessary for authentication, session continuity, and core app functionality.'),
            _buildBulletPoint(theme, colorScheme,
                'Performance & Analytics Cookies: Help us understand how visitors interact with our content and diagnose technical issues (e.g. Firebase Analytics).'),
            _buildBulletPoint(theme, colorScheme,
                'Advertising Cookies: Used by advertising partners to measure ad effectiveness and prevent repetitive ads.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'You can configure your browser or device settings to block or delete cookies. However, disabling cookies may impact certain features or require you to re-authenticate.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 6: Third-Party Service Providers
            _buildSectionTitle(theme, '6. Third-Party Service Providers'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We may share necessary data with trusted third-party providers strictly for service operation:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Cloud Infrastructure & Analytics: Google Cloud, Firebase.'),
            _buildBulletPoint(theme, colorScheme,
                'Payment Processors: Razorpay (PCI-DSS compliant).'),
            _buildBulletPoint(theme, colorScheme,
                'Advertising Networks: Google AdSense, Google AdMob.'),
            _buildBulletPoint(theme, colorScheme,
                'Music & Media Distribution: Official YouTube and streaming integrations.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 7: Copyright & Content Protection
            _buildSectionTitle(theme, '7. Copyright & Content Protection'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'All sound recordings, musical compositions, artwork, videos, and trademarks available through Veena Music are the exclusive copyrighted property of Oriental Audio Visual Electronics or licensed by respective creators. Unauthorized copying, downloading, scraping, broadcasting, or redistribution is strictly prohibited.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 8: Data Retention & Security
            _buildSectionTitle(theme, '8. Data Retention & Security'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We implement industry-standard technical and organizational security measures, including SSL/TLS encryption, secure database access, and regular vulnerability monitoring. We retain your information only as long as necessary to provide services, resolve disputes, and comply with legal obligations.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 9: Your Privacy Rights (GDPR & CCPA/CPRA)
            _buildSectionTitle(theme, '9. Your Privacy Rights (GDPR & CCPA/CPRA)'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Depending on your location, you have statutory rights regarding your personal information:'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint(theme, colorScheme,
                'Right to Access: Request a copy of the personal information we hold about you.'),
            _buildBulletPoint(theme, colorScheme,
                'Right to Rectification: Correct inaccurate or incomplete information in your profile.'),
            _buildBulletPoint(theme, colorScheme,
                'Right to Erasure (Right to be Forgotten): Request deletion of your account and associated personal data.'),
            _buildBulletPoint(theme, colorScheme,
                'Right to Restrict or Object: Object to processing for direct marketing or personalized advertising.'),
            _buildBulletPoint(theme, colorScheme,
                'Non-Discrimination: We will never discriminate against you for exercising your privacy rights.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'To exercise any of these rights, please email info@veenamusiconline.com or use the account deletion options in the app settings.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 10: Children's Privacy (COPPA)
            _buildSectionTitle(theme, '10. Children\'s Privacy'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Our services are not directed to children under 13 years of age (or under 16 in certain jurisdictions). We do not knowingly collect personal information from children without verified parental consent. If we discover that a child has provided us with personal information, we will take prompt steps to delete it.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 11: Policy Updates
            _buildSectionTitle(theme, '11. Policy Updates'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'We may update this Privacy Policy from time to time to reflect changes in our practices or applicable legal requirements. The updated date at the top of this page will indicate when revisions took effect.'),
            const SizedBox(height: AppSpacing.lg),

            // Section 12: Contact Information
            _buildSectionTitle(theme, '12. Contact Information'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'For questions, feedback, or privacy-related requests, please contact our Data Protection team:'),
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
                    'Oriental Audio Visual Electronics',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Haldia House, Johri Bazar, Jaipur, Rajasthan 302003, India',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.email_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: AppSpacing.xs),
                      InkWell(
                        onTap: () => openUrl('mailto:info@veenamusiconline.com'),
                        child: Text(
                          'info@veenamusiconline.com',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
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
                      InkWell(
                        onTap: () => openUrl('https://veenamusiconline.com/privacy-policy.html'),
                        child: Text(
                          'https://veenamusiconline.com/privacy-policy.html',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
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

  Widget _buildLinkCard(
    BuildContext context, {
    required String title,
    required String description,
    required String url,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: BorderSide(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: () => openUrl(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
