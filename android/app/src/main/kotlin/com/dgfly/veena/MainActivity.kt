package com.dgfly.veena

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val ALARM_CHANNEL = "com.dgfly.veena/alarm_player"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleNativeAlarm" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                        val mediaUrl = call.argument<String>("mediaUrl") ?: ""
                        val mediaTitle = call.argument<String>("mediaTitle") ?: "Alarm"
                        val artistName = call.argument<String>("artistName") ?: "Veena"

                        if (mediaUrl.isEmpty() || triggerAtMillis <= 0) {
                            result.error("INVALID_ARGS", "mediaUrl and triggerAtMillis are required", null)
                            return@setMethodCallHandler
                        }

                        scheduleAlarm(alarmId, triggerAtMillis, mediaUrl, mediaTitle, artistName)
                        result.success(true)
                    }
                    "cancelNativeAlarm" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: 0
                        cancelAlarm(alarmId)
                        result.success(true)
                    }
                    "stopAlarm" -> {
                        val intent = AlarmPlayerService.createStopIntent(this)
                        startService(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun scheduleAlarm(
        alarmId: Int,
        triggerAtMillis: Long,
        mediaUrl: String,
        mediaTitle: String,
        artistName: String
    ) {
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra(AlarmReceiver.EXTRA_MEDIA_URL, mediaUrl)
            putExtra(AlarmReceiver.EXTRA_MEDIA_TITLE, mediaTitle)
            putExtra(AlarmReceiver.EXTRA_ARTIST_NAME, artistName)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+ requires checking canScheduleExactAlarms
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setAlarmClock(
                        AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent),
                        pendingIntent
                    )
                } else {
                    // Fallback to inexact alarm (user hasn't granted permission)
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent),
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
            Log.d(TAG, "Alarm $alarmId scheduled for $triggerAtMillis")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm", e)
        }
    }

    private fun cancelAlarm(alarmId: Int) {
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        Log.d(TAG, "Alarm $alarmId cancelled")
    }
}
