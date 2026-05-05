import 'dart:async';

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
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Global audio handler - initialized once at app startup
AudioHandler? audioHandler;
Future<AudioHandler?>? _audioHandlerFuture;

Future<AudioHandler?> ensureAudioHandlerInitialized() {
  if (audioHandler != null) {
    return Future.value(audioHandler);
  }
  return _audioHandlerFuture ??= _createAudioHandler();
}

Future<AudioHandler?> _createAudioHandler() async {
  try {
    final handler = await AudioService.init(
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
    audioHandler = handler;
    return handler;
  } catch (e, stackTrace) {
    debugPrint('[Startup] AudioService init failed: $e');
    debugPrint('$stackTrace');
    _audioHandlerFuture = null;
    return null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize time zones for local notifications
  tz.initializeTimeZones();
  if (!kIsWeb) {
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.toString()));
    } catch (_) {
      // Fallback
    }
  }

  // Initialize Firebase (only on mobile - web requires separate config)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e, stackTrace) {
      debugPrint('[Startup] Firebase init failed: $e');
      debugPrint('$stackTrace');
    }
  }

  final prefs = await SharedPreferences.getInstance();

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

  // Keep native-heavy startup work off the critical first-frame path.
  unawaited(ensureAudioHandlerInitialized());
}
