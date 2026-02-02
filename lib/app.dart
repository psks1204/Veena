import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/player_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/media_service.dart';
import 'core/services/dashboard_service.dart';
import 'core/services/library_service.dart';
import 'core/services/album_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/player/screens/video_player_screen.dart';
import 'features/player/screens/audio_player_screen.dart';
import 'shared/layouts/app_shell.dart';
import 'core/services/push_notification_service.dart';
import 'core/navigation/app_navigation.dart';

/// Veena Music Streaming App
/// 
/// Premium music streaming application with Spotify-level polish.
class VeenaApp extends StatelessWidget {
  const VeenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create ApiService first as other services depend on it
    final apiService = ApiService();
    
    // Set ApiService on PushNotificationService for FCM token registration (mobile only)
    if (!kIsWeb) {
      PushNotificationService().setApiService(apiService);
    }
    
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        
        // API-based services (share the same ApiService instance)
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => DashboardService(apiService)),
        ChangeNotifierProvider(create: (_) => MediaService(apiService)),
        ChangeNotifierProvider(create: (_) => LibraryService(apiService)),
        ChangeNotifierProvider(create: (_) => AlbumService(apiService)),
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, PlayerProvider>(
      builder: (context, authService, player, child) {
        // Show loading while initializing
        if (authService.state == AuthState.initial ||
            authService.state == AuthState.loading) {
          return const SplashScreen();
        }

        // Show login if not authenticated
        if (authService.state != AuthState.authenticated) {
          return LoginScreen(
            onLoginSuccess: () {
              // Navigate to home after login
            },
          );
        }

        // Inject access token into ApiService for authenticated API calls
        final apiService = context.read<ApiService>();
        apiService.setAccessToken(authService.accessToken);
        
        // Handle 401 Unauthorized - Logout automatically
        apiService.onUnauthorized = () {
          // Prevent infinite loop: don't call signOut if already signing out
          if (!authService.isSigningOut) {
            debugPrint('⚠️ Unauthorized! Signing out...');
            authService.signOut();
          } else {
            debugPrint('⚠️ 401 received but signOut already in progress, skipping');
          }
        };
        
        // Connect player to media service for auto play tracking
        final playerProvider = context.read<PlayerProvider>();
        final mediaService = context.read<MediaService>();
        playerProvider.setMediaService(mediaService);

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
                        if (player.isVideo) {
                          // Video player fullscreen (over everything)
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const VideoPlayerScreen(),
                            ),
                          );
                        } else {
                          // Audio player fullscreen (over everything)
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => const AudioPlayerScreen(),
                            ),
                          );
                        }
                      },
                      onPlayPause: () {
                        player.togglePlayPause();
                      },
                      onNext: () {},
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

