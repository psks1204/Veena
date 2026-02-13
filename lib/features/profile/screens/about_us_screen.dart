import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// About Us Screen
///
/// Displays Veena Music company information.
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
                  'assets/images/app_logo.png',
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
            const SizedBox(height: AppSpacing.xl),

            _buildSectionTitle(theme, 'Preserving the Soul of Rajasthani Music'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Veena Music is a pioneering name in the Rajasthani music industry, passionately dedicated to developing, preserving, and promoting the rich musical traditions of Rajasthan. Established with the vision of bringing authentic folk melodies to global audiences, Veena Music has become a symbol of high-quality music production, copyright protection, and cultural preservation.'),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle(theme, 'A Legacy Rooted in Tradition'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Our music is free from commercial constraints, ensuring that every composition remains true to its traditional roots. Whether it\'s Rajasthani Folk Music, Indian Devotional Songs, or Indian Wedding Melodies, our catalog reflects the vibrant essence of Rajasthan\'s heritage.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Through collaborations with legendary artists, composers, and lyricists, we have curated a diverse collection of soulful folk renditions and festive songs, connecting audiences with the spirit of Rajasthan.'),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle(theme, 'Impactful Achievements & Milestones'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'The ever-growing popularity of Rajasthani Folk Music has led Veena Music to produce over 50 successful albums in the last four years. Our Ghoomar series (4 parts) has set a milestone in India and abroad, earning recognition as one of the definitive representations of Rajasthani music.'),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle(theme, 'Embracing Innovation & Digital Reach'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'At Veena Music, we blend tradition with technology, ensuring our music reaches global audiences through digital platforms, and streaming services. We take copyright protection seriously, ensuring our original compositions remain safeguarded from unauthorized use.'),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle(theme, 'Our Mission: Keeping Heritage Alive'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Our goal is more than music—it\'s cultural storytelling. We aim to educate, engage, and entertain through compositions that highlight Rajasthan\'s rituals, fairs, and festivals, ensuring that the legacy of Rajasthani music remains timeless and revered.'),
            const SizedBox(height: AppSpacing.sm),
            _buildParagraph(theme, colorScheme,
                'Join us in our journey as we keep the spirit of Rajasthani music alive!'),

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
