import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/open_url.dart';
import '../../core/services/credits_service.dart';
import '../../features/profile/screens/about_us_screen.dart';
import '../../features/profile/screens/contact_us_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/terms_of_service_screen.dart';

/// App Footer Widget
///
/// Premium footer with social media links, copyright notice,
/// and DGFly branding. Responsive for both mobile and web.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const _socialLinks = [
    _SocialItem(
      icon: Icons.facebook_rounded,
      label: 'Facebook',
      url: 'https://www.facebook.com/share/16PEdHwbDa/',
      color: Color(0xFF3B5998),
    ),
    _SocialItem(
      icon: Icons.close, // X/Twitter icon approximation
      label: 'X',
      url: 'https://x.com/Veena_Music',
      color: Color(0xFF55ACEE),
      useSvgLetter: true,
    ),
    _SocialItem(
      icon: Icons.camera_alt_rounded,
      label: 'Instagram',
      url: 'https://www.instagram.com/veenamusic/',
      color: Color(0xFFE4405F),
    ),
    _SocialItem(
      icon: Icons.play_circle_fill_rounded,
      label: 'YouTube',
      url: 'https://youtube.com/@veenamusicrajasthani',
      color: Color(0xFFFF0000),
    ),
  ];

  void _openLink(String url) {
    openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final year = DateTime.now().year;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withOpacity(0.6)
            : AppColors.lightSurfaceVariant.withOpacity(0.7),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Social Icons Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _socialLinks.map((social) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _SocialButton(
                  social: social,
                  isDark: isDark,
                  onTap: () => _openLink(social.url),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Divider ──
          Container(
            width: 120,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Made by DGFly ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Made with ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const Icon(
                Icons.favorite_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              Text(
                ' by ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _openLink('https://dgfly.in'),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'DGFly',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Dynamic Credits ──
          FutureBuilder<Map<String, String>?>(
            future: CreditsService().getCredits(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final credits = snapshot.data!;
                final name = credits['name'];
                final url = credits['url'];

                if (name != null && name.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Crafted By ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary.withOpacity(0.8)
                                : AppColors.lightTextSecondary.withOpacity(0.8),
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              if (url != null && url.isNotEmpty) {
                                _openLink(url);
                              }
                            },
                            child: Text(
                              name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // ── Internal Links ──
          const SizedBox(height: 16),
          _FooterLinks(isDark: isDark),

          const SizedBox(height: 24),
          Text(
            '© $year Veena. All rights reserved.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary.withOpacity(0.6)
                  : AppColors.lightTextSecondary.withOpacity(0.6),
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Social Item Data ──
class _SocialItem {
  final IconData icon;
  final String label;
  final String url;
  final Color color;
  final bool useSvgLetter;

  const _SocialItem({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
    this.useSvgLetter = false,
  });
}

// ── Individual Social Button ──
class _SocialButton extends StatefulWidget {
  final _SocialItem social;
  final bool isDark;
  final VoidCallback onTap;

  const _SocialButton({
    required this.social,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final socialColor = widget.social.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.social.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isHovered
                  ? socialColor.withOpacity(0.15)
                  : (widget.isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? socialColor.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Center(
              child: widget.social.useSvgLetter
                  // X/Twitter uses the letter "𝕏"
                  ? Text(
                      '𝕏',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isHovered
                            ? socialColor
                            : (widget.isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    )
                  : Icon(
                      widget.social.icon,
                      size: 22,
                      color: _isHovered
                          ? socialColor
                          : (widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  final bool isDark;

  const _FooterLinks({required this.isDark});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark
          ? AppColors.darkTextSecondary.withOpacity(0.7)
          : AppColors.lightTextSecondary.withOpacity(0.7),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        _FooterLinkItem(
          label: 'About Us',
          onTap: () => _navigateTo(context, const AboutUsScreen()),
          style: linkStyle,
        ),
        _FooterLinkItem(
          label: 'Contact Us',
          onTap: () => _navigateTo(context, const ContactUsScreen()),
          style: linkStyle,
        ),
        _FooterLinkItem(
          label: 'Terms',
          onTap: () => _navigateTo(context, const TermsOfServiceScreen()),
          style: linkStyle,
        ),
        _FooterLinkItem(
          label: 'Privacy',
          onTap: () => _navigateTo(context, const PrivacyPolicyScreen()),
          style: linkStyle,
        ),
      ],
    );
  }
}

class _FooterLinkItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final TextStyle? style;

  const _FooterLinkItem({
    required this.label,
    required this.onTap,
    this.style,
  });

  @override
  State<_FooterLinkItem> createState() => _FooterLinkItemState();
}

class _FooterLinkItemState extends State<_FooterLinkItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: widget.style?.copyWith(
            color: _isHovered ? AppColors.primary : widget.style?.color,
            decoration: _isHovered ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}
