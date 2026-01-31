import 'package:flutter/material.dart';
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
import 'features/player/screens/lyrics_fullscreen_screen.dart';
import 'shared/layouts/app_shell.dart';
import 'shared/widgets/full_player.dart';
import 'core/services/push_notification_service.dart';

/// Veena Music Streaming App
/// 
/// Premium music streaming application with Spotify-level polish.
class VeenaApp extends StatelessWidget {
  const VeenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create ApiService first as other services depend on it
    final apiService = ApiService();
    
    // Set ApiService on PushNotificationService for FCM token registration
    PushNotificationService().setApiService(apiService);
    
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
  bool _showFullPlayer = false;

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
          debugPrint('⚠️ Unauthorized! Signing out...');
          authService.signOut();
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
                setState(() {
                  _currentIndex = index;
                });
              },
              showMiniPlayer: player.hasMedia, // Show for both audio and video
              miniPlayerData: player.hasMedia
                  ? MiniPlayerData(
                      trackTitle: player.currentMedia!.title,
                      artistName: player.currentMedia!.artistName,
                      artworkUrl: player.currentMedia!.thumbnailUrl,
                      isPlaying: player.isPlaying,
                      progress: player.progress,
                      onTap: () {
                        if (player.isVideo) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VideoPlayerScreen(),
                            ),
                          );
                        } else {
                          setState(() {
                            _showFullPlayer = true;
                          });
                        }
                      },
                      onPlayPause: () {
                        player.togglePlayPause();
                      },
                      onNext: () {},
                    )
                  : null,
              child: _buildCurrentScreen(),
            ),
            
            // Full player overlay (for audio) with Slide-up Transition
            AnimatedSlide(
              offset: _showFullPlayer ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              child: player.hasMedia && player.isAudio
                  ? FullPlayer(
                      trackTitle: player.currentMedia!.title,
                      artistName: player.currentMedia!.description ?? '',
                      albumName: 'Playing from search', // Example source
                      artworkUrl: player.currentMedia!.thumbnailUrl,
                      isPlaying: player.isPlaying,
                      progress: player.progress,
                      currentPosition: player.position,
                      duration: player.duration,
                      isShuffleOn: player.shuffleEnabled,
                      repeatMode: player.repeatMode,
                      lyrics: player.currentLyrics,
                      activeLyricIndex: player.activeLyricIndex,
                      onFullscreenLyricsTap: () {
                        if (player.currentLyrics != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LyricsFullscreenScreen(
                                lyrics: player.currentLyrics!,
                                initialActiveIndex: player.activeLyricIndex,
                                activeIndexStream: player.lyricIndexStream,
                              ),
                            ),
                          );
                        }
                      },
                      onClose: () {
                        setState(() {
                          _showFullPlayer = false;
                        });
                      },
                      onPlayPause: () => player.togglePlayPause(),
                      onSeek: (v) => player.seekToProgress(v),
                      onPrevious: () => player.previous(),
                      onNext: () => player.next(),
                      onShuffle: () => player.toggleShuffle(),
                      onRepeat: () => player.toggleRepeatMode(),
                    )

                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    final authService = context.read<AuthService>();
    
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SearchScreen();
      case 2:
        return const LibraryScreen();
      case 3:
        return ProfileScreen(
          onSignOut: () async {
            await authService.signOut();
          },
        );
      default:
        return const HomeScreen();
    }
  }
}

