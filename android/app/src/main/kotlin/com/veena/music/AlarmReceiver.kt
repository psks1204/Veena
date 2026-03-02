package com.veena.music

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BroadcastReceiver that intercepts alarm triggers and starts the AlarmPlayerService foreground
 * service directly.
 *
 * This is registered from the Dart side when scheduling an alarm. When the alarm fires, Android
 * invokes this receiver which then starts the foreground service for reliable audio playback.
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "AlarmReceiver"
        const val EXTRA_MEDIA_URL = "media_url"
        const val EXTRA_MEDIA_TITLE = "media_title"
        const val EXTRA_ARTIST_NAME = "artist_name"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Alarm received!")

        val mediaUrl = intent.getStringExtra(EXTRA_MEDIA_URL) ?: ""
        val mediaTitle = intent.getStringExtra(EXTRA_MEDIA_TITLE) ?: "Alarm"
        val artistName = intent.getStringExtra(EXTRA_ARTIST_NAME) ?: "Veena"

        if (mediaUrl.isEmpty()) {
            Log.e(TAG, "No media URL in alarm intent, ignoring")
            return
        }

        val serviceIntent =
                AlarmPlayerService.createStartIntent(context, mediaUrl, mediaTitle, artistName)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "AlarmPlayerService started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start AlarmPlayerService", e)
        }
    }
}
