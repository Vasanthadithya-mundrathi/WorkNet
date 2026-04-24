package com.worknetapp.worknet

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * WorkNetDiscoveryService
 *
 * A foreground service that keeps the BLE/Wi-Fi discovery process alive
 * when the app is backgrounded on Android. Without this, Android kills
 * the Nearby Connections session within ~5 minutes of backgrounding.
 *
 * Called from Flutter via platform channel (MethodChannel):
 *   - "worknet.discovery/start" → startForeground
 *   - "worknet.discovery/stop"  → stopSelf
 *
 * The persistent notification wording updates from Flutter via
 * "worknet.discovery/updateNotification" with a peerCount argument.
 */
class WorkNetDiscoveryService : Service() {

    companion object {
        const val CHANNEL_ID      = "worknet_discovery"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START    = "com.worknetapp.worknet.ACTION_START"
        const val ACTION_STOP     = "com.worknetapp.worknet.ACTION_STOP"
        const val EXTRA_PEER_COUNT = "peer_count"

        fun buildStartIntent(context: Context, peerCount: Int = 0): Intent =
            Intent(context, WorkNetDiscoveryService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_PEER_COUNT, peerCount)
            }

        fun buildStopIntent(context: Context): Intent =
            Intent(context, WorkNetDiscoveryService::class.java).apply {
                action = ACTION_STOP
            }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                val peerCount = intent?.getIntExtra(EXTRA_PEER_COUNT, 0) ?: 0
                startForeground(NOTIFICATION_ID, buildNotification(peerCount))
            }
        }
        // Restart if killed — keeps discovery alive even on harsh OEM battery managers
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Notification ───────────────────────────────────────────────

    private fun buildNotification(peerCount: Int): Notification {
        val tapIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentText = if (peerCount > 0)
            "Discovering nearby professionals · $peerCount in range"
        else
            "WorkNet is active — scanning for nearby professionals"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("WorkNet")
            .setContentText(contentText)
            // Use a small monochrome icon; replace R.drawable.ic_notification
            // with an actual 24dp white icon asset before release.
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .setShowWhen(false)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "WorkNet Discovery",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description  = "Keeps WorkNet active so you can discover nearby professionals"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
