import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import '../models/alarm_model.dart';

/// Writes a stop signal file that the alarm polling loop will detect.
/// This is a TOP-LEVEL function so it can be used as a background notification handler.
@pragma('vm:entry-point')
Future<void> _onStopAlarmAction(NotificationResponse response) async {
  if (response.actionId == 'stop_alarm') {
    debugPrint('[AlarmStop] Stop action received for notification ID: ${response.id}');
    try {
      // Write a stop signal file to the app's temporary directory.
      // dart:io File operations work across Flutter engines/isolates.
      final dir = await getTemporaryDirectory();
      final stopFile = File('${dir.path}/stop_alarm_signal');
      await stopFile.writeAsString('stop');
      debugPrint('[AlarmStop] Stop signal file written at: ${stopFile.path}');
    } catch (e) {
      debugPrint('[AlarmStop] Error writing stop signal file: $e');
    }

    // Also cancel the notification
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(response.id ?? 0);
    } catch (e) {
      debugPrint('[AlarmStop] Error cancelling notification: $e');
    }
  }
}

@pragma('vm:entry-point')
class AlarmService {
  static const String _alarmsKey = 'veena_alarms';

  final SharedPreferences _prefs;

  AlarmService(this._prefs);

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  List<Alarm> getAlarms() {
    final jsonString = _prefs.getString(_alarmsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => Alarm.fromJson(e)).toList();
  }

  Future<void> saveAlarm(Alarm alarm) async {
    final alarms = getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);

    if (index >= 0) {
      alarms[index] = alarm;
    } else {
      alarms.add(alarm);
    }

    await _prefs.setString(
        _alarmsKey, jsonEncode(alarms.map((e) => e.toJson()).toList()));

    if (alarm.isEnabled) {
      await _scheduleAlarm(alarm);
    } else {
      await _cancelAlarm(alarm);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final alarms = getAlarms();
    final alarm = alarms.firstWhere((a) => a.id == id,
        orElse: () => throw Exception('Alarm not found'));

    await _cancelAlarm(alarm);
    alarms.removeWhere((a) => a.id == id);

    await _prefs.setString(
        _alarmsKey, jsonEncode(alarms.map((e) => e.toJson()).toList()));
  }

  Future<void> _scheduleAlarm(Alarm alarm) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final alarmId = alarm.id.hashCode;

    final params = {
      'mediaUrl': alarm.mediaUrl,
      'mediaTitle': alarm.mediaTitle,
      'artistName': alarm.artistName,
    };

    await AndroidAlarmManager.oneShotAt(
      scheduledDate,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: params,
    );

    debugPrint('Alarm scheduled for $scheduledDate');
  }

  Future<void> _cancelAlarm(Alarm alarm) async {
    await AndroidAlarmManager.cancel(alarm.id.hashCode);
    debugPrint('Alarm cancelled: ${alarm.id}');
  }

  // --- Background Alarm Callback ---

  @pragma('vm:entry-point')
  static Future<void> alarmCallback(
      int id, Map<String, dynamic> params) async {
    debugPrint('[AlarmCallback] Alarm fired! ID: $id');

    final mediaUrl = params['mediaUrl'] as String?;
    final mediaTitle = params['mediaTitle'] as String? ?? 'Alarm';
    final artistName = params['artistName'] as String? ?? 'Veena';

    if (mediaUrl == null) {
      debugPrint('[AlarmCallback] No media URL, aborting');
      return;
    }

    // 1. Clean up any old stop signal file
    try {
      final dir = await getTemporaryDirectory();
      final stopFile = File('${dir.path}/stop_alarm_signal');
      if (await stopFile.exists()) {
        await stopFile.delete();
      }
    } catch (_) {}

    // 2. Initialize notifications with the top-level stop handler
    final notifPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await notifPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onStopAlarmAction,
      onDidReceiveBackgroundNotificationResponse: _onStopAlarmAction,
    );

    // 3. Initialize audio player and start playback
    final player = AudioPlayer();

    try {
      await player.setUrl(mediaUrl);
      player.setLoopMode(LoopMode.one);
      player.setVolume(1.0);
      player.play();
      debugPrint('[AlarmCallback] Audio playback started');

      // 4. Show notification with Stop action
      const androidDetails = AndroidNotificationDetails(
        'veena_alarm_channel',
        'Veena Alarm',
        channelDescription: 'Alarm playback notifications',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: false, // Allow swipe dismiss
        autoCancel: false,
        fullScreenIntent: true,
        actions: [
          AndroidNotificationAction(
            'stop_alarm',
            'Stop',
            showsUserInterface: true, // Route through foreground handler (which works)
            cancelNotification: false,
          ),
        ],
      );

      const notifDetails = NotificationDetails(android: androidDetails);

      await notifPlugin.show(
        id,
        '⏰ Alarm',
        '$mediaTitle • $artistName — Tap to stop',
        notifDetails,
        payload: 'veena_alarm',
      );

      // 5. Poll for stop signal file OR notification dismissed (swipe) every 500ms
      bool stopped = false;
      for (int i = 0; i < 600; i++) {
        // 600 * 500ms = 5 minutes max
        await Future.delayed(const Duration(milliseconds: 500));

        // Check 1: Stop signal file (written by notification tap/action)
        try {
          final dir = await getTemporaryDirectory();
          final stopFile = File('${dir.path}/stop_alarm_signal');
          if (await stopFile.exists()) {
            debugPrint('[AlarmCallback] Stop signal file detected! Stopping...');
            await stopFile.delete();
            stopped = true;
            break;
          }
        } catch (e) {
          debugPrint('[AlarmCallback] Error checking stop file: $e');
        }

        // Check 2: Notification dismissed (user swiped it away)
        try {
          final activeNotifs = await notifPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.getActiveNotifications();
          if (activeNotifs != null) {
            final alarmNotifExists = activeNotifs.any((n) => n.id == id);
            if (!alarmNotifExists) {
              debugPrint('[AlarmCallback] Notification was dismissed (swiped)! Stopping...');
              stopped = true;
              break;
            }
          }
        } catch (e) {
          debugPrint('[AlarmCallback] Error checking active notifications: $e');
        }
      }

      // 6. Cleanup
      debugPrint('[AlarmCallback] Stopping player (stopped=$stopped)');
      await player.stop();
      await player.dispose();
      await notifPlugin.cancel(id);
    } catch (e) {
      debugPrint('[AlarmCallback] Error: $e');
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
      await notifPlugin.cancel(id);
    }
  }
}
