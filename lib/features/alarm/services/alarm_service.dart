import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

/// AlarmService — schedules and manages alarms using native Android AlarmManager
/// via MethodChannel. Audio playback is handled entirely on the native side
/// (AlarmReceiver → AlarmPlayerService) using Android's MediaPlayer with
/// USAGE_ALARM attributes, which works reliably on Samsung and all OEM devices.
@pragma('vm:entry-point')
class AlarmService {
  static const String _alarmsKey = 'veena_alarms';
  static const MethodChannel _channel = MethodChannel(
    'com.veena.music/alarm_player',
  );

  final SharedPreferences _prefs;

  AlarmService(this._prefs);

  /// Initialize is kept for API compatibility (no-op now since we use native AlarmManager)
  static Future<void> initialize() async {
    // No longer need AndroidAlarmManager.initialize() since we schedule natively
    debugPrint('[AlarmService] Initialized');
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
      _alarmsKey,
      jsonEncode(alarms.map((e) => e.toJson()).toList()),
    );

    if (alarm.isEnabled) {
      await _scheduleAlarm(alarm);
    } else {
      await _cancelAlarm(alarm);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final alarms = getAlarms();
    final alarm = alarms.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Alarm not found'),
    );

    await _cancelAlarm(alarm);
    alarms.removeWhere((a) => a.id == id);

    await _prefs.setString(
      _alarmsKey,
      jsonEncode(alarms.map((e) => e.toJson()).toList()),
    );
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
    final triggerAtMillis = scheduledDate.millisecondsSinceEpoch;

    try {
      await _channel.invokeMethod('scheduleNativeAlarm', {
        'alarmId': alarmId,
        'triggerAtMillis': triggerAtMillis,
        'mediaUrl': alarm.mediaUrl ?? '',
        'mediaTitle': alarm.mediaTitle ?? 'Alarm',
        'artistName': alarm.artistName ?? 'Veena',
      });
      debugPrint('[AlarmService] Alarm $alarmId scheduled for $scheduledDate');
    } catch (e) {
      debugPrint('[AlarmService] Error scheduling alarm: $e');
      rethrow;
    }
  }

  Future<void> _cancelAlarm(Alarm alarm) async {
    final alarmId = alarm.id.hashCode;
    try {
      await _channel.invokeMethod('cancelNativeAlarm', {'alarmId': alarmId});
      debugPrint('[AlarmService] Alarm $alarmId cancelled');
    } catch (e) {
      debugPrint('[AlarmService] Error cancelling alarm: $e');
    }
  }

  /// Stop a currently playing alarm (call from UI)
  static Future<void> stopNativeAlarm() async {
    try {
      await _channel.invokeMethod('stopAlarm');
      debugPrint('[AlarmService] Native alarm stopped');
    } catch (e) {
      debugPrint('[AlarmService] Error stopping alarm: $e');
    }
  }
}
