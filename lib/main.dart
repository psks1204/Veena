import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'app.dart';
import 'core/services/audio_handler.dart';

/// Global audio handler - initialized once at app startup
late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AudioService BEFORE runApp
  audioHandler = await AudioService.init(
    builder: () => VeenaAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.veena.app.channel.audio',
      androidNotificationChannelName: 'Veena Music',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      notificationColor: Color(0xFF6366F1),
    ),
  );
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  runApp(const VeenaApp());
}
