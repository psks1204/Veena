import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/player_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/download_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/media_service.dart';
import 'core/services/media_download_service.dart';
import 'core/services/dashboard_service.dart';
import 'core/services/library_service.dart';
import 'core/services/album_service.dart';
import 'core/services/artist_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/public_dashboard_service.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/comment_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/invoice_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/screens/maintenance_page.dart';
import 'features/settings/screens/update_required_page.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/public_landing_screen.dart';
import 'features/channel/screens/uploads_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/library/screens/library_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/player/screens/unified_player_screen.dart';
import 'shared/layouts/app_shell.dart';
import 'shared/layouts/shop_shell.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/ads_service.dart';
import 'core/navigation/app_navigation.dart';
import 'core/navigation/app_tabs.dart';
import 'features/channel/services/channel_service.dart';
import 'features/channel/services/channel_interaction_service.dart';
import 'features/channel/providers/channel_provider.dart';
import 'features/channel/screens/channel_setup_screen.dart';
import 'features/shop/services/shop_catalog_service.dart';
import 'features/shop/services/cart_service.dart';
import 'features/shop/services/address_service.dart';
import 'features/shop/services/order_service.dart';
import 'features/shop/services/payment_service.dart';
import 'features/shop/providers/shop_catalog_provider.dart';
import 'features/shop/providers/cart_provider.dart';
import 'features/shop/providers/order_provider.dart';
import 'features/shop/providers/address_provider.dart';
import 'features/shop/providers/wishlist_provider.dart';
import 'features/shop/screens/shop_home_screen.dart';
import 'features/shop/screens/orders_screen.dart';
import 'features/shop/screens/wishlist_screen.dart';
import 'features/shop/screens/cart_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/alarm/services/alarm_service.dart';
import 'features/notifications/data/services/notification_service.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/player/services/karaoke_recording_service.dart';

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
    final mediaDownloadService = MediaDownloadService(apiService, prefs);

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
        ChangeNotifierProvider(
          create: (_) =>
              SubscriptionProvider(prefs, SubscriptionService(apiService)),
        ),

        // API-based services (share the same ApiService instance)
        Provider<ApiService>.value(value: apiService),
        Provider<MediaDownloadService>.value(value: mediaDownloadService),
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
        Provider<InvoiceService>(create: (_) => InvoiceService(apiService)),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(NotificationService(apiService)),
        ),
        ChangeNotifierProxyProvider<SubscriptionProvider, DownloadProvider>(
          create: (_) => DownloadProvider(mediaDownloadService)..initialize(),
          update: (_, subscription, downloadProvider) {
            final provider =
                downloadProvider ?? DownloadProvider(mediaDownloadService);
            provider.updateSubscriptionStatus(subscription.isNoAdsSubscribed);
            if (!provider.isInitialized && !provider.isLoading) {
              provider.initialize();
            }
            return provider;
          },
        ),

        // Deep link service
        ChangeNotifierProvider<DeepLinkService>.value(value: deepLinkService),

        // App mode (music ↔ shop)
        ChangeNotifierProvider(create: (_) => AppModeProvider()),

        // Channel feature
        Provider<ChannelService>(create: (_) => ChannelService(apiService)),
        ChangeNotifierProxyProvider<ChannelService, ChannelInteractionService>(
          create: (ctx) =>
              ChannelInteractionService(ctx.read<ChannelService>()),
          update: (ctx, svc, prev) => prev ?? ChannelInteractionService(svc),
        ),
        ChangeNotifierProxyProvider<ChannelService, ChannelProvider>(
          create: (ctx) => ChannelProvider(ctx.read<ChannelService>(), prefs),
          update: (ctx, svc, prev) => prev ?? ChannelProvider(svc, prefs),
        ),

        // Shop services
        Provider<ShopCatalogService>(
          create: (_) => ShopCatalogService(apiService),
        ),
        Provider<CartService>(create: (_) => CartService(apiService)),
        Provider<AddressService>(create: (_) => AddressService(apiService)),
        Provider<OrderService>(create: (_) => OrderService(apiService)),
        Provider<PaymentService>(create: (_) => PaymentService(apiService)),

        // Shop providers
        ChangeNotifierProxyProvider<ShopCatalogService, ShopCatalogProvider>(
          create: (ctx) => ShopCatalogProvider(ctx.read<ShopCatalogService>()),
          update: (ctx, svc, prev) => prev ?? ShopCatalogProvider(svc),
        ),
        ChangeNotifierProxyProvider<CartService, CartProvider>(
          create: (ctx) => CartProvider(ctx.read<CartService>()),
          update: (ctx, svc, prev) => prev ?? CartProvider(svc),
        ),
        ChangeNotifierProxyProvider<OrderService, OrderProvider>(
          create: (ctx) => OrderProvider(ctx.read<OrderService>()),
          update: (ctx, svc, prev) => prev ?? OrderProvider(svc),
        ),
        ChangeNotifierProxyProvider<AddressService, AddressProvider>(
          create: (ctx) => AddressProvider(ctx.read<AddressService>()),
          update: (ctx, svc, prev) => prev ?? AddressProvider(svc),
        ),
        ChangeNotifierProvider(create: (_) => WishlistProvider(prefs)),

        // Karaoke recording
        ChangeNotifierProvider(create: (_) => KaraokeRecordingService()),
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
  bool _channelSetupTriggered = false;
  bool _providersReset = false; // tracks whether sign-out reset has been done
  bool _profileInitTriggered = false;
  bool _nameSetupTriggered = false;
  bool _subscriptionInitTriggered = false;
  bool _backgroundServicesInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer heavy background services to after the first frame so the UI can
    // render immediately and Android does not show the "Close app / Wait" ANR dialog.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initBackgroundServices();
      });
    }
  }

  Future<void> _initBackgroundServices() async {
    if (_backgroundServicesInitialized) return;
    _backgroundServicesInitialized = true;
    try {
      await AdsService.initialize();
    } catch (_) {}
    try {
      await PushNotificationService().initialize();
    } catch (_) {}
  }

  void _fetchSettingsOnce() {
    if (_settingsFetched) return;

    final authService = context.read<AuthService>();
    if (authService.accessToken == null) {
      return; // Wait for token to be available
    }

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
          // Reset so settings and channel setup are re-triggered on next login
          _settingsFetched = false;
          _channelSetupTriggered = false;
          _profileInitTriggered = false;
          _nameSetupTriggered = false;
          _subscriptionInitTriggered = false;
          // Reset provider state so re-login gets fresh data
          if (!_providersReset) {
            _providersReset = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<ProfileProvider>().resetForSignOut();
                context.read<ChannelProvider>().resetForSignOut();
                context.read<SubscriptionProvider>().resetForSignOut();
              }
            });
          }
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
        _providersReset = false; // allow reset on next sign-out

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

        // Initialize profile on login: sends Google name via PUT, then fetches GET
        // Location is fetched in the background (non-blocking) by ProfileProvider
        final profileProvider = context.read<ProfileProvider>();
        if (!_profileInitTriggered &&
            !profileProvider.hasInitialized &&
            !profileProvider.isLoading) {
          _profileInitTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            profileProvider.initializeOnLogin(
              googleName: authService.userName,
              googleEmail: authService.userEmail,
            );
          });
        }

        // Show first-login name setup if profile has no name
        if (profileProvider.needsNameSetup && !_nameSetupTriggered) {
          _nameSetupTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context, rootNavigator: true)
                .push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      initialName: authService.userName,
                      isFirstLogin: true,
                    ),
                  ),
                )
                .then((_) {
                  // Only mark done after user actually closes the screen
                  profileProvider.markNameSetupDone();
                });
          });
        }

        // Initialize channel on login (checks if setup needed)
        final channelProvider = context.read<ChannelProvider>();
        if (!channelProvider.hasInitialized && !channelProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            channelProvider.initializeOnLogin();
          });
        }

        // Show channel setup if user has not set a custom channel name
        if (channelProvider.needsChannelSetup && !_channelSetupTriggered) {
          _channelSetupTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) =>
                    ChannelSetupScreen(initialName: authService.userName),
              ),
            );
          });
        }

        final subscriptionProvider = context.read<SubscriptionProvider>();
        if (!_subscriptionInitTriggered && !subscriptionProvider.isLoading) {
          _subscriptionInitTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            subscriptionProvider.initialize();
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

        // Connect player to services
        final playerProvider = context.read<PlayerProvider>();
        final mediaService = context.read<MediaService>();
        final mediaDownloadService = context.read<MediaDownloadService>();
        playerProvider.setMediaService(mediaService);
        playerProvider.setMediaDownloadService(mediaDownloadService);
        playerProvider.setAuthService(authService);

        // ── Deep link: navigate to song after login ───────────────────────
        final deepLinkService = context.watch<DeepLinkService>();
        if (deepLinkService.pendingSongId != null) {
          final songId = deepLinkService.pendingSongId!;
          // Consume immediately to prevent duplicate triggers on rebuild
          deepLinkService.consume();

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final rootNavigator = Navigator.of(
              this.context,
              rootNavigator: true,
            );
            debugPrint('🔗 AppRouter: handling deep link for songId=$songId');
            final item = await mediaService.fetchMediaById(songId);
            if (item != null && mounted) {
              playerProvider.play(item);
              rootNavigator.push(
                MaterialPageRoute(builder: (_) => const UnifiedPlayerScreen()),
              );
            }
          });
        }

        // Build mini player data (shared between music and shop shells)
        final miniPlayerData = player.hasMedia
            ? MiniPlayerData(
                trackTitle: player.currentMedia!.title,
                artistName: player.currentMedia!.artistName,
                artworkUrl: player.currentMedia!.thumbnailUrl,
                isPlaying: player.isPlaying,
                progress: player.progress,
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => const UnifiedPlayerScreen(),
                    ),
                  );
                },
                onPlayPause: () => player.togglePlayPause(),
                onNext: () {},
                onClose: () => player.clearQueue(),
              )
            : null;

        // Show main app — music shell or shop shell based on AppMode
        return Consumer<AppModeProvider>(
          builder: (context, appMode, _) {
            final hidePlayerUi = appMode.suppressPlayerUi;

            if (appMode.isShop) {
              return ShopShell(
                miniPlayerData: miniPlayerData,
                screens: const [
                  ShopHomeScreen(),
                  OrdersScreen(),
                  WishlistScreen(),
                  CartScreen(),
                ],
              );
            }
            return AppShell(
              currentIndex: _currentIndex,
              onDestinationSelected: (index) {
                if (_currentIndex == index) {
                  AppNavigation.popToFirst();
                } else {
                  if (_currentIndex == AppTabs.uploads &&
                      index != AppTabs.uploads) {
                    UploadsScreen.pauseReelPlayback();
                  }
                  setState(() => _currentIndex = index);
                }
              },
              showMiniPlayer: player.hasMedia && !hidePlayerUi,
              miniPlayerData: miniPlayerData,
              screens: _buildScreens(context),
            );
          },
        );
      },
    );
  }

  /// Build all tab screens (for nested navigation)
  List<Widget> _buildScreens(BuildContext context) {
    final authService = context.read<AuthService>();

    return [
      const HomeScreen(),
      const UploadsScreen(),
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
