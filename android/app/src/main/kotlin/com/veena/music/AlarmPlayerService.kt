package com.veena.music

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Native Android foreground service for reliable alarm audio playback.
 *
 * Uses Android's built-in MediaPlayer with USAGE_ALARM audio attributes to bypass Samsung/OEM
 * battery optimization that kills background Flutter isolates.
 *
 * This service:
 * - Runs as a foreground service (protected from being killed)
 * - Uses USAGE_ALARM so audio plays even in DND/silent mode
 * - Acquires a WakeLock to prevent CPU sleep
 * - Loops playback until stopped
 * - Auto-stops after 5 minutes as a safety net
 */
class AlarmPlayerService : Service() {

    companion object {
        const val TAG = "AlarmPlayerService"
        const val CHANNEL_ID = "veena_alarm_playback_channel"
        const val NOTIFICATION_ID = 9999
        const val ACTION_STOP = "com.veena.music.STOP_ALARM"

        const val EXTRA_MEDIA_URL = "media_url"
        const val EXTRA_MEDIA_TITLE = "media_title"
        const val EXTRA_ARTIST_NAME = "artist_name"

        private const val MAX_PLAY_DURATION_MS = 5 * 60 * 1000L // 5 minutes

        fun createStartIntent(
                context: Context,
                mediaUrl: String,
                mediaTitle: String,
                artistName: String
        ): Intent {
            return Intent(context, AlarmPlayerService::class.java).apply {
                putExtra(EXTRA_MEDIA_URL, mediaUrl)
                putExtra(EXTRA_MEDIA_TITLE, mediaTitle)
                putExtra(EXTRA_ARTIST_NAME, artistName)
            }
        }

        fun createStopIntent(context: Context): Intent {
            return Intent(context, AlarmPlayerService::class.java).apply { action = ACTION_STOP }
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val autoStopHandler = android.os.Handler(android.os.Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: action=${intent?.action}")

        if (intent?.action == ACTION_STOP) {
            Log.d(TAG, "Stop action received")
            stopAlarm()
            return START_NOT_STICKY
        }

        val mediaUrl = intent?.getStringExtra(EXTRA_MEDIA_URL)
        val mediaTitle = intent?.getStringExtra(EXTRA_MEDIA_TITLE) ?: "Alarm"
        val artistName = intent?.getStringExtra(EXTRA_ARTIST_NAME) ?: "Veena"

        if (mediaUrl.isNullOrEmpty()) {
            Log.e(TAG, "No media URL provided, stopping")
            stopSelf()
            return START_NOT_STICKY
        }

        // Start as foreground service immediately (before any async work)
        val notification = buildNotification(mediaTitle, artistName)
        startForeground(NOTIFICATION_ID, notification)

        // Start playing audio
        startPlayback(mediaUrl, mediaTitle, artistName)

        // Schedule auto-stop after 5 minutes
        autoStopHandler.postDelayed(
                {
                    Log.d(TAG, "Auto-stop triggered after 5 minutes")
                    stopAlarm()
                },
                MAX_PLAY_DURATION_MS
        )

        return START_NOT_STICKY
    }

    private fun startPlayback(mediaUrl: String, mediaTitle: String, artistName: String) {
        // Stop any existing playback first
        releaseMediaPlayer()

        try {
            mediaPlayer =
                    MediaPlayer().apply {
                        // Set audio attributes for ALARM usage — plays even in DND/silent
                        val audioAttrs =
                                AudioAttributes.Builder()
                                        .setUsage(AudioAttributes.USAGE_ALARM)
                                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                        .build()
                        setAudioAttributes(audioAttrs)

                        setDataSource(mediaUrl)
                        isLooping = true
                        setVolume(1.0f, 1.0f)

                        setOnPreparedListener { mp ->
                            Log.d(TAG, "MediaPlayer prepared, starting playback")
                            mp.start()
                        }

                        setOnErrorListener { _, what, extra ->
                            Log.e(TAG, "MediaPlayer error: what=$what extra=$extra")
                            stopAlarm()
                            true
                        }

                        // Use async prepare for network URLs
                        prepareAsync()
                    }

            Log.d(TAG, "MediaPlayer preparing: $mediaUrl")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting playback", e)
            stopAlarm()
        }
    }

    private fun buildNotification(title: String, artist: String): Notification {
        // Stop action intent
        val stopIntent = Intent(this, AlarmPlayerService::class.java).apply { action = ACTION_STOP }
        val stopPendingIntent =
                PendingIntent.getService(
                        this,
                        0,
                        stopIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        // Tap intent — opens app
        val tapIntent = packageManager.getLaunchIntentForPackage(packageName)
        val tapPendingIntent =
                if (tapIntent != null) {
                    PendingIntent.getActivity(
                            this,
                            1,
                            tapIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                } else null

        return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("⏰ $title")
                .setContentText("$artist — Tap Stop to dismiss")
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .setContentIntent(tapPendingIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
                .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(
                                    CHANNEL_ID,
                                    "Alarm Playback",
                                    NotificationManager.IMPORTANCE_HIGH
                            )
                            .apply {
                                description = "Shows when an alarm is playing"
                                setBypassDnd(true)
                                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                                setShowBadge(true)

                                // Set alarm audio attributes on the channel itself
                                val audioAttrs =
                                        AudioAttributes.Builder()
                                                .setUsage(AudioAttributes.USAGE_ALARM)
                                                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                                .build()
                                setSound(
                                        null,
                                        audioAttrs
                                ) // No notification sound — we play our own
                                enableVibration(true)
                            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock =
                powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "veena:alarm_wakelock")
                        .apply {
                            acquire(MAX_PLAY_DURATION_MS) // Auto-release after max duration
                        }
        Log.d(TAG, "WakeLock acquired")
    }

    private fun stopAlarm() {
        Log.d(TAG, "Stopping alarm")
        autoStopHandler.removeCallbacksAndMessages(null)
        releaseMediaPlayer()
        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun releaseMediaPlayer() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaPlayer", e)
        }
        mediaPlayer = null
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let { if (it.isHeld) it.release() }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock", e)
        }
        wakeLock = null
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        autoStopHandler.removeCallbacksAndMessages(null)
        releaseMediaPlayer()
        releaseWakeLock()
        super.onDestroy()
    }
}
