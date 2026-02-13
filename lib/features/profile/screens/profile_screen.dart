import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../auth/services/auth_service.dart';
import 'edit_profile_screen.dart';
import '../../alarm/screens/alarm_list_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';

/// Profile Screen
///
/// User profile with theme toggle and settings.
/// Now integrated with ProfileProvider for API-sourced data.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Profile header
          _ProfileHeader(onEditTap: () {
            AppNavigation.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          }),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Theme section
          _SectionTitle(title: 'Appearance'),
          const SizedBox(height: AppSpacing.sm),
          _ThemeToggle(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Settings section
          _SectionTitle(title: 'Settings'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            children: [
              if (!kIsWeb)
                _SettingsTile(
                  icon: Icons.alarm_rounded,
                  title: 'Alarms',
                  onTap: () {
                    AppNavigation.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AlarmListScreen()),
                    );
                  },
                ),
              _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // About section
          _SectionTitle(title: 'About'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_rounded,
                title: 'About Veena',
                onTap: () {
                  AppNavigation.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.contact_mail_rounded,
                title: 'Contact Us',
                onTap: () {
                  AppNavigation.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.article_rounded,
                title: 'Terms of Service',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coming Soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.shield_rounded,
                title: 'Privacy Policy',
                onTap: () {
                  AppNavigation.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
                showDivider: false,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                side: BorderSide(
                  color: colorScheme.onSurface.withOpacity(0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              child: Text(
                'Log out',
                style: theme.textTheme.labelLarge,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          
          // Extra padding to ensure content is visible above mini player + nav bar
          const SizedBox(height: 140),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.onEditTap});

  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileProvider = context.watch<ProfileProvider>();
    final authService = context.watch<AuthService>();

    // Use ProfileProvider data first, fallback to AuthService
    final profile = profileProvider.profile;
    
    final pName = profile?.name;
    final userName = (pName != null && pName.isNotEmpty) 
        ? pName 
        : (authService.userName ?? 'User');
        
    final pEmail = profile?.email;
    final userEmail = (pEmail != null && pEmail.isNotEmpty)
        ? pEmail
        : (authService.userEmail ?? 'user@example.com');
        
    final pPhoto = profile?.photoUrl;
    final userPicture = (pPhoto != null && pPhoto.isNotEmpty)
        ? pPhoto
        : authService.userPicture;
        
    // Initials logic
    String userInitials = 'U';
    if (userName != 'User') {
      final parts = userName.split(' ');
      if (parts.length >= 2) {
        userInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (userName.isNotEmpty) {
        userInitials = userName[0].toUpperCase();
      }
    } else if (profile?.initials != null) {
      userInitials = profile!.initials;
    } else if (authService.userInitials.isNotEmpty) {
      userInitials = authService.userInitials;
    }

    return Column(
      children: [
        // Avatar
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            image: userPicture != null && userPicture.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(userPicture),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: userPicture == null || userPicture.isEmpty
              ? Center(
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Name
        Text(
          userName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xs),
        
        // Email
        Text(
          userEmail,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Edit profile button
        OutlinedButton(
          onPressed: onEditTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            side: BorderSide(
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          child: Text(
            'Edit profile',
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            themeProvider.isDarkMode 
                ? Icons.dark_mode_rounded 
                : Icons.light_mode_rounded,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  themeProvider.isDarkMode ? 'On' : 'Off',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.setDarkMode(value);
            },
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          title: Text(title),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.onSurface.withOpacity(0.05),
          ),
      ],
    );
  }
}
