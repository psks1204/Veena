import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// About Us Screen
///
/// Displays Veena Music history, cultural mission, discography, and company details.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
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

            // Title
            Center(
              child: Text(
                'Veena Music',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'Pioneer of Rajasthani Music',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _buildSectionTitle(theme, 'Preserving the Soul of Rajasthani Music'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Veena Music (operated by Oriental Audio Visual Electronics) is a pioneering, world-renowned brand in the Indian music industry, passionately dedicated to developing, preserving, and promoting the rich cultural and musical heritage of Rajasthan. Established with the vision of bringing authentic folk melodies and devotional traditions to global audiences, Veena Music has become the definitive benchmark for Rajasthani music production, artistic integrity, and copyright preservation.'),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle(theme, 'A Rich Legacy of Authentic Folk & Bhakti'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Our catalog remains steadfastly true to its traditional roots. Spanning Rajasthani Folk, timeless Bhajans, Devotional Melodies, traditional Wedding Gits, and festive celebrations, every track is produced with master audio fidelity and respect for folkloric authenticity.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Through collaborations with legendary folk artists, maestros, composers, and traditional musicians, we have curated an extraordinary catalog that connects millions of listeners worldwide with the vibrant spirit of Rajasthan.'),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle(theme, 'Milestones & The Iconic Ghoomar Series'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Over several decades, Veena Music has produced hundreds of iconic albums. Our internationally acclaimed Ghoomar series (Parts 1 to 4) achieved historic milestones in India and across the global Indian diaspora, revitalizing traditional Rajasthani dance and musical culture across continents.'),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle(theme, 'Digital Innovation & Global Streaming'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Today, Veena Music bridges ancient cultural heritage with cutting-edge technology. Through our Android app, iOS app, and web platform (veenamusiconline.com), listeners can enjoy curated playlists, seamless streaming, and high-quality audio anywhere in the world.'),
            const SizedBox(height: AppSpacing.lg),

            // Corporate details card
            _buildSectionTitle(theme, 'Corporate Entity'),
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
                    'Oriental Audio Visual Electronics',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Brand: Veena Music',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Headquarters: Haldia House, Johri Bazar, Jaipur, Rajasthan 302003, India',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Inquiries: info@veenamusiconline.com',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

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

  Widget _buildParagraph(ThemeData theme, ColorScheme colorScheme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.8),
        height: 1.6,
      ),
    );
  }
}
