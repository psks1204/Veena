import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[PushNotification] Background message: ${message.messageId}');
  // Background messages are handled by the system notification
}

/// Background notification action handler - must be top-level function.
/// This handles notification action taps (like 'Stop' on alarm) when app is in background.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) async {
  debugPrint('[PushNotification:BG] Background action received: action=${response.actionId}, id=${response.id}');
  
  if (response.actionId == 'stop_alarm') {
    debugPrint('[PushNotification:BG] Writing stop signal file');
    try {
      final dir = await getTemporaryDirectory();
      final stopFile = File('${dir.path}/stop_alarm_signal');
      await stopFile.writeAsString('stop');
    } catch (e) {
      debugPrint('[PushNotification:BG] Error: $e');
    }
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(response.id ?? 0);
    } catch (_) {}
  }
}

/// Push Notification Service - Handles FCM and rich notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  ApiService? _apiService;
  String? _currentFcmToken;

  /// Set the API service for backend communication
  void setApiService(ApiService apiService) {
    _apiService = apiService;
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Request permission
    await _requestPermission();
    
    // Get FCM token
    _currentFcmToken = await _getToken();
    
    // Set up message handlers
    _setupMessageHandlers();
    
    debugPrint('[PushNotification] Service initialized');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );
    
    // Create notification channels for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'veena_notifications',
        'Veena Notifications',
        description: 'Notifications from Veena Music App',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      // Alarm channel for alarm notifications
      const alarmChannel = AndroidNotificationChannel(
        'veena_alarm_channel',
        'Veena Alarm',
        description: 'Alarm playback notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.createNotificationChannel(alarmChannel);
    }
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    debugPrint('[PushNotification] Permission status: ${settings.authorizationStatus}');
  }

  /// Get FCM device token
  Future<String?> _getToken() async {
    final token = await _messaging.getToken();
    debugPrint('[PushNotification] FCM Token: $token');
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[PushNotification] Token refreshed: $newToken');
      _currentFcmToken = newToken;
      // Re-register with backend when token refreshes
      await registerFcmToken();
    });
    
    return token;
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    String deviceName = 'Unknown';
    String deviceId = 'unknown';
    String deviceType = 'Android';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceId = androidInfo.id;
        deviceType = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} (${iosInfo.model})';
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceType = 'iOS';
      }
    } catch (e) {
      debugPrint('[PushNotification] Error getting device info: $e');
    }

    return {
      'deviceName': deviceName,
      'deviceId': deviceId,
      'deviceType': deviceType,
    };
  }

  /// Register FCM token with backend after login
  Future<bool> registerFcmToken() async {
    if (_apiService == null) {
      debugPrint('[PushNotification] ApiService not set - cannot register FCM token');
      return false;
    }

    final fcmToken = _currentFcmToken ?? await _messaging.getToken();
    if (fcmToken == null) {
      debugPrint('[PushNotification] No FCM token available');
      return false;
    }

    try {
      final deviceInfo = await _getDeviceInfo();
      
      debugPrint('[PushNotification] Registering FCM token with backend...');
      debugPrint('  FCM Token: ${fcmToken.substring(0, 20)}...');
      debugPrint('  Device: ${deviceInfo['deviceName']}');
      debugPrint('  Device ID: ${deviceInfo['deviceId']}');
      
      await _apiService!.post('/user/devices/register', body: {
        'fcmToken': fcmToken,
        'deviceType': deviceInfo['deviceType'],
        'deviceName': deviceInfo['deviceName'],
        'deviceId': deviceInfo['deviceId'],
      });
      
      debugPrint('[PushNotification] ✅ FCM token registered successfully');
      return true;
    } catch (e) {
      debugPrint('[PushNotification] ❌ Failed to register FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token from backend on logout
  /// This uses skipUnauthorizedCallback to prevent 401 errors from triggering
  /// another logout, which would cause an infinite loop
  Future<bool> unregisterFcmToken() async {
    if (_apiService == null) {
      debugPrint('[PushNotification] ApiService not set - cannot unregister FCM token');
      return false;
    }

    final fcmToken = _currentFcmToken ?? await _messaging.getToken();
    if (fcmToken == null) {
      debugPrint('[PushNotification] No FCM token available to unregister');
      return false;
    }

    try {
      debugPrint('[PushNotification] Unregistering FCM token from backend...');
      
      // Use skipUnauthorizedCallback to prevent 401 from triggering logout loop
      await _apiService!.post('/user/devices/unregister', 
        body: {'fcmToken': fcmToken},
        skipUnauthorizedCallback: true,
      );
      
      debugPrint('[PushNotification] ✅ FCM token unregistered successfully');
      return true;
    } catch (e) {
      debugPrint('[PushNotification] ❌ Failed to unregister FCM token: $e');
      return false;
    }
  }

  /// Set up message handlers for foreground/background
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from a notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[PushNotification] App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages - show local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[PushNotification] Foreground message received');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Image: ${message.notification?.android?.imageUrl}');
    debugPrint('  Data: ${message.data}');
    
    await _showRichNotification(message);
  }

  /// Show rich notification with image
  Future<void> _showRichNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    
    final title = notification.title ?? 'Veena';
    final body = notification.body ?? '';
    final imageUrl = notification.android?.imageUrl ?? 
                     notification.apple?.imageUrl ??
                     message.data['image'];
    
    // Build notification details
    AndroidNotificationDetails androidDetails;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Download image for big picture style
      final bigPicture = await _downloadAndSaveImage(imageUrl);
      
      if (bigPicture != null) {
        androidDetails = AndroidNotificationDetails(
          'veena_notifications',
          'Veena Notifications',
          channelDescription: 'Notifications from Veena Music App',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bigPicture),
            largeIcon: ByteArrayAndroidBitmap(bigPicture),
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: false,
          ),
        );
      } else {
        androidDetails = _defaultAndroidDetails();
      }
    } else {
      androidDetails = _defaultAndroidDetails();
    }
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Default Android notification details
  AndroidNotificationDetails _defaultAndroidDetails() {
    return const AndroidNotificationDetails(
      'veena_notifications',
      'Veena Notifications',
      channelDescription: 'Notifications from Veena Music App',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );
  }

  /// Download image from URL and return as bytes
  Future<Uint8List?> _downloadAndSaveImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[PushNotification] Error downloading image: $e');
    }
    return null;
  }

  /// Handle notification tap from local notification
  void _onNotificationTap(NotificationResponse response) async {
    debugPrint('[PushNotification] Notification tapped: action=${response.actionId}, id=${response.id}, payload=${response.payload}');
    
    // Handle Stop Alarm action (action button tap)
    // OR handle alarm notification body tap (payload contains "veena_alarm")
    if (response.actionId == 'stop_alarm' || response.payload == 'veena_alarm') {
      debugPrint('[PushNotification] Alarm stop triggered - writing stop signal file');
      try {
        final dir = await getTemporaryDirectory();
        final stopFile = File('${dir.path}/stop_alarm_signal');
        await stopFile.writeAsString('stop');
        debugPrint('[PushNotification] Stop signal file written');
        
        await _localNotifications.cancel(response.id ?? 0);
      } catch (e) {
        debugPrint('[PushNotification] Error handling stop alarm: $e');
      }
      return;
    }

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateFromNotification(data);
      } catch (e) {
        debugPrint('[PushNotification] Error parsing payload: $e');
      }
    }
  }

  /// Handle notification tap from FCM
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[PushNotification] FCM notification tapped');
    _navigateFromNotification(message.data);
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    // TODO: Implement navigation based on notification data
    // Example:
    // if (data['type'] == 'album') {
    //   navigatorKey.currentState?.push(AlbumDetailScreen(albumId: data['album_id']));
    // }
    debugPrint('[PushNotification] Navigate with data: $data');
  }

  /// Get the current FCM token
  Future<String?> getToken() => _messaging.getToken();
  
  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[PushNotification] Subscribed to topic: $topic');
  }
  
  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[PushNotification] Unsubscribed from topic: $topic');
  }
}
