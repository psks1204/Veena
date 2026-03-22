import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/player_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/media_service.dart';
import 'core/services/dashboard_service.dart';
import 'core/services/library_service.dart';
import 'core/services/album_service.dart';
import 'core/services/artist_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/public_dashboard_service.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/comment_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/screens/maintenance_page.dart';
import 'features/settings/screens/update_required_page.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/public_landing_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/player/screens/unified_player_screen.dart';
import 'shared/layouts/app_shell.dart';
import 'core/services/push_notification_service.dart';
import 'core/navigation/app_navigation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/alarm/services/alarm_service.dart';

/// Veena Music Streaming App
///
/// Premium music streaming application with Spotify-level polish.
class VeenaApp extends StatelessWidget {
  final SharedPreferences prefs;

  const VeenaApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Create ApiService first as other services depend on it
    final apiService = ApiService();

    // Set ApiService on PushNotificationService for FCM token registration (mobile only)
    if (!kIsWeb) {
      PushNotificationService().setApiService(apiService);
    }

    // Initialize deep link service once
    final deepLinkService = DeepLinkService();
    deepLinkService.initialize();

    return MultiProvider(
      providers: [
        // Core providers
        Provider<AlarmService>(create: (_) => AlarmService(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),

        // API-based services (share the same ApiService instance)
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => DashboardService(apiService)),
        ChangeNotifierProvider(create: (_) => MediaService(apiService)),
        ChangeNotifierProvider(create: (_) => LibraryService(apiService)),
        ChangeNotifierProvider(create: (_) => AlbumService(apiService)),
        ChangeNotifierProvider(create: (_) => ArtistService(apiService)),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(ProfileService(apiService)),
        ),
        ChangeNotifierProvider(create: (_) => PublicDashboardService()),
        ChangeNotifierProvider(create: (_) => AppSettingsService(apiService)),
        Provider<CommentService>(create: (_) => CommentService(apiService)),

        // Deep link service
        ChangeNotifierProvider<DeepLinkService>.value(value: deepLinkService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Veena',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AppRouter(),
          );
        },
      ),
    );
  }
}

/// App Router - handles auth state and navigation
class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  int _currentIndex = 0;
  bool _settingsFetched = false;
  bool _deepLinkHandled = false;

  void _fetchSettingsOnce() {
    if (_settingsFetched) return;
    
    final authService = context.read<AuthService>();
    if (authService.accessToken == null) return; // Wait for token to be available
    
    _settingsFetched = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppSettingsService>().fetchSettings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, PlayerProvider, AppSettingsService>(
      builder: (context, authService, player, settings, child) {
        // Show splash while loading auth
        if (authService.state == AuthState.initial ||
            authService.state == AuthState.loading) {
          return const SplashScreen();
        }

        // Show login if not authenticated
        if (authService.state != AuthState.authenticated) {
          // Reset so settings are re-fetched on next login
          _settingsFetched = false;
          // Web: show public landing page with dashboard preview
          if (kIsWeb) {
            return PublicLandingScreen(
              onSignIn: () => authService.signInWithGoogle(),
            );
          }
          // Mobile: show standard login screen
          return LoginScreen(
            onLoginSuccess: () {
              // Navigate to home after login
            },
          );
        }

        // ── Authenticated from here ──

        // Inject access token into ApiService for authenticated API calls
        final apiService = context.read<ApiService>();
        apiService.setAccessToken(authService.accessToken);

        // Handle Token Refresh
        apiService.onRefreshToken = () async {
          debugPrint('🔄 AppRouter: Refreshing token...');
          final success = await authService.refreshAccessToken();
          if (success) {
            debugPrint('✅ AppRouter: Token refreshed, updating ApiService');
            apiService.setAccessToken(authService.accessToken);
          }
          return success;
        };

        // Fetch app settings once after login
        _fetchSettingsOnce();

        // === GATE 1: Maintenance Mode ===
        if (settings.maintenanceMode) {
          return MaintenancePage(
            onRetry: () {
              _settingsFetched = false;
              _fetchSettingsOnce();
            },
          );
        }

        // === GATE 2: Minimum Version Check ===
        if (settings.isAppOutdated) {
          return UpdateRequiredPage(
            currentVersion: AppSettingsService.currentAppVersion,
            minimumVersion: settings.minimumAppVersion,
          );
        }

        // Initialize profile on login: sends location + Google name via PUT, then fetches GET
        final profileProvider = context.read<ProfileProvider>();
        if (!profileProvider.hasInitialized && !profileProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            profileProvider.initializeOnLogin(
              googleName: authService.userName,
              googleEmail: authService.userEmail,
            );
          });
        }

        // Show first-login name setup if profile has no name
        if (profileProvider.needsNameSetup) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  initialName: authService.userName,
                  isFirstLogin: true,
                ),
              ),
            );
            profileProvider.markNameSetupDone();
          });
        }

        // Handle 401 Unauthorized - Logout automatically
        apiService.onUnauthorized = () {
          // Prevent infinite loop: don't call signOut if already signing out
          if (!authService.isSigningOut) {
            debugPrint('⚠️ Unauthorized! Signing out...');
            authService.signOut();
          } else {
            debugPrint(
              '⚠️ 401 received but signOut already in progress, skipping',
            );
          }
        };

        // Connect player to media service for auto play tracking
        final playerProvider = context.read<PlayerProvider>();
        final mediaService = context.read<MediaService>();
        playerProvider.setMediaService(mediaService);

        // ── Deep link: navigate to song after first login ──────────────────
        final deepLinkService = context.read<DeepLinkService>();
        if (!_deepLinkHandled && deepLinkService.pendingSongId != null) {
          _deepLinkHandled = true;
          final songId = deepLinkService.pendingSongId!;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            debugPrint('🔗 AppRouter: handling deep link for songId=$songId');
            final item = await mediaService.fetchMediaById(songId);
            deepLinkService.consume();
            if (item != null && mounted) {
              playerProvider.play(item);
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const UnifiedPlayerScreen(),
                ),
              );
            }
          });
        }

        // Show main app
        return Stack(
          children: [
            AppShell(
              currentIndex: _currentIndex,
              onDestinationSelected: (index) {
                // If tapping the same tab, pop to root of that tab
                if (_currentIndex == index) {
                  AppNavigation.popToFirst();
                } else {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              showMiniPlayer: player.hasMedia,
              miniPlayerData: player.hasMedia
                  ? MiniPlayerData(
                      trackTitle: player.currentMedia!.title,
                      artistName: player.currentMedia!.artistName,
                      artworkUrl: player.currentMedia!.thumbnailUrl,
                      isPlaying: player.isPlaying,
                      progress: player.progress,
                      onTap: () {
                        // Unified player handles both audio and video
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => const UnifiedPlayerScreen(),
                          ),
                        );
                      },
                      onPlayPause: () {
                        player.togglePlayPause();
                      },
                      onNext: () {},
                      onClose: () {
                        player.clearQueue();
                      },
                    )
                  : null,
              screens: _buildScreens(context),
            ),
          ],
        );
      },
    );
  }

  /// Build all tab screens (for nested navigation)
  List<Widget> _buildScreens(BuildContext context) {
    final authService = context.read<AuthService>();

    return [
      const HomeScreen(),
      const SearchScreen(),
      const LibraryScreen(),
      ProfileScreen(
        onSignOut: () async {
          await authService.signOut();
        },
      ),
    ];
  }
}
