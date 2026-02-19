import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/audio_handler.dart';
import 'core/services/push_notification_service.dart';

/// Global audio handler - initialized once at app startup
late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (only on mobile - web requires separate config)
  if (!kIsWeb) {
    await Firebase.initializeApp();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize Push Notification Service
    await PushNotificationService().initialize();
  }

  final prefs = await SharedPreferences.getInstance();

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

  runApp(VeenaApp(prefs: prefs));
}
