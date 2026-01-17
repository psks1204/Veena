import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/theme_provider.dart';

/// Profile Screen
/// 
/// User profile with theme toggle and settings.
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
          _ProfileHeader(),
          
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
              _SettingsTile(
                icon: Icons.music_note_rounded,
                title: 'Playback',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.storage_rounded,
                title: 'Data Saver',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.download_rounded,
                title: 'Downloads',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy',
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
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.article_rounded,
                title: 'Terms of Service',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.shield_rounded,
                title: 'Privacy Policy',
                onTap: () {},
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
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          ),
          child: const Center(
            child: Text(
              'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Name
        Text(
          'User Name',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xs),
        
        // Email
        Text(
          'user@example.com',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Edit profile button
        OutlinedButton(
          onPressed: () {},
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
