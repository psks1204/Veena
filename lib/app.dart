import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/playback_provider.dart';
import 'core/providers/search_provider.dart';
import 'core/providers/library_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'shared/layouts/app_shell.dart';
import 'shared/widgets/full_player.dart';

/// Veena Music Streaming App
/// 
/// Premium music streaming application with Spotify-level polish.
class VeenaApp extends StatelessWidget {
  const VeenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
        ChangeNotifierProxyProvider<AuthService, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, dashboard) => dashboard!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, SearchProvider>(
          create: (_) => SearchProvider(),
          update: (_, auth, search) => search!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, LibraryProvider>(
          create: (_) => LibraryProvider(),
          update: (_, auth, library) => library!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, PlaybackProvider>(
          create: (_) => PlaybackProvider(),
          update: (_, auth, playback) => playback!..updateAuth(auth),
        ),
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
    final playbackProvider = context.watch<PlaybackProvider>();
    final currentMedia = playbackProvider.currentMedia;

    return Consumer<AuthService>(
      builder: (context, authService, child) {
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
              showMiniPlayer: currentMedia != null,
              miniPlayerData: currentMedia == null 
                ? null 
                : MiniPlayerData(
                    trackTitle: currentMedia.title,
                    artistName: currentMedia.artistName,
                    artworkUrl: currentMedia.thumbnailUrl,
                    isPlaying: playbackProvider.isPlaying,
                    isLiked: currentMedia.isLiked,
                    progress: playbackProvider.duration.inSeconds > 0
                        ? playbackProvider.position.inSeconds / playbackProvider.duration.inSeconds
                        : 0.0,
                    onTap: () {
                      setState(() {
                        _showFullPlayer = true;
                      });
                    },
                    onPlayPause: () {
                      playbackProvider.togglePlay();
                    },
                    onNext: () {},
                    onFavorite: () {
                      playbackProvider.toggleLike();
                    },
                  ),
              child: _buildCurrentScreen(),
            ),
            
            // Full player overlay
            if (_showFullPlayer && currentMedia != null)
              Material(
                child: FullPlayer(
                  onClose: () {
                    setState(() {
                      _showFullPlayer = false;
                    });
                  },
                ),
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
