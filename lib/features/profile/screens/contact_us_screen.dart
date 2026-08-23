import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/open_url.dart';

/// Contact Us Screen
///
/// Displays Veena Music contact channels, office location, and inquiries.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
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
            // Logo
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/logo_light.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Center(
              child: Text(
                'Get in Touch',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'We would love to hear from you',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Office Address Card
            _buildContactCard(
              context,
              icon: Icons.location_on_rounded,
              title: 'Registered Office',
              lines: [
                'Veena Music (Oriental Audio Visual Electronics)',
                'Haldia House, Johri Bazar,',
                'Jaipur, Rajasthan 302003, India',
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Phone Card
            _buildContactCard(
              context,
              icon: Icons.phone_rounded,
              title: 'Phone Support',
              lines: [
                '+91 141 257 2666',
                '+91 88750 22558',
              ],
              onTap: () => openUrl('tel:+911412572666'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Email Card
            _buildContactCard(
              context,
              icon: Icons.email_rounded,
              title: 'Email Inquiries',
              lines: [
                'info@veenamusiconline.com',
                'veenacassettes@gmail.com',
              ],
              onTap: () => openUrl('mailto:info@veenamusiconline.com'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Website Card
            _buildContactCard(
              context,
              icon: Icons.language_rounded,
              title: 'Official Website',
              lines: [
                'https://veenamusiconline.com',
              ],
              onTap: () => openUrl('https://veenamusiconline.com'),
            ),

            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<String> lines,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...lines.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      )),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }
}
