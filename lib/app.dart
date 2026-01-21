import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
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
  
  // Demo player state
  bool _isPlaying = true;
  double _progress = 0.35;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show loading while initializing
        if (authService.state == AuthState.initial ||
            authService.state == AuthState.loading) {
          return const _SplashScreen();
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
              showMiniPlayer: true,
              miniPlayerData: MiniPlayerData(
                trackTitle: 'Blinding Lights',
                artistName: 'The Weeknd',
                isPlaying: _isPlaying,
                progress: _progress,
                onTap: () {
                  setState(() {
                    _showFullPlayer = true;
                  });
                },
                onPlayPause: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                onNext: () {},
              ),
              child: _buildCurrentScreen(),
            ),
            
            // Full player overlay
            if (_showFullPlayer)
              Material(
                child: FullPlayer(
                  trackTitle: 'Blinding Lights',
                  artistName: 'The Weeknd',
                  albumName: 'After Hours',
                  isPlaying: _isPlaying,
                  progress: _progress,
                  currentPosition: const Duration(minutes: 1, seconds: 10),
                  duration: const Duration(minutes: 3, seconds: 20),
                  onClose: () {
                    setState(() {
                      _showFullPlayer = false;
                    });
                  },
                  onPlayPause: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                  onSeek: (value) {
                    setState(() {
                      _progress = value;
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

/// Splash Screen
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Veena',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
