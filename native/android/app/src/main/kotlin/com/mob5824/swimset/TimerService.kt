package com.mob5824.swimset

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Keeps the poolside timer alive while the screen is off.
 *
 * The Dart side owns the clock; this service only holds the process in the
 * foreground, mirrors the countdown in an ongoing notification and forwards the
 * notification buttons back to the runner.
 */
class TimerService : Service() {
    private var title: String = "Poolside timer running"
    private var text: String = "SwimSet keeps timing with the screen off."
    private var running: Boolean = true
    private var foreground: Boolean = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PAUSE -> {
                running = false
                onAction?.invoke("pause")
            }
            ACTION_RESUME -> {
                running = true
                onAction?.invoke("resume")
            }
            ACTION_NEXT -> onAction?.invoke("next")
            else -> {
                intent?.getStringExtra(EXTRA_TITLE)?.let { title = it }
                intent?.getStringExtra(EXTRA_TEXT)?.let { text = it }
                running = intent?.getBooleanExtra(EXTRA_RUNNING, true) ?: true
            }
        }
        publish()
        return START_STICKY
    }

    /** Called from the host activity while the timer ticks. */
    fun update(title: String, text: String, running: Boolean) {
        this.title = title
        this.text = text
        this.running = running
        if (foreground) manager()?.notify(NOTIFICATION_ID, build())
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        if (instance === this) instance = null
        foreground = false
        super.onDestroy()
    }

    private fun publish() {
        val notification = build()
        if (!foreground) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            foreground = true
        } else {
            manager()?.notify(NOTIFICATION_ID, notification)
        }
    }

    private fun manager(): NotificationManager? = getSystemService(NotificationManager::class.java)

    private fun pending(action: String?, request: Int): PendingIntent {
        val intent = Intent(this, TimerService::class.java)
        if (action != null) intent.action = action
        return PendingIntent.getService(
            this,
            request,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun build(): Notification {
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val toggleLabel = if (running) "Pause" else "Resume"
        val toggleAction = if (running) ACTION_PAUSE else ACTION_RESUME
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_timer)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, toggleLabel, pending(toggleAction, 1))
            .addAction(0, "Next", pending(ACTION_NEXT, 2))
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = manager() ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Poolside timer",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Keeps the SwimSet timer running with the screen off."
                    setShowBadge(false)
                },
            )
        }
    }

    companion object {
        const val CHANNEL_ID = "swimset.timer"
        const val NOTIFICATION_ID = 7741

        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_RUNNING = "running"

        private const val ACTION_PAUSE = "com.mob5824.swimset.PAUSE"
        private const val ACTION_RESUME = "com.mob5824.swimset.RESUME"
        private const val ACTION_NEXT = "com.mob5824.swimset.NEXT"

        /** The running service, if any, so the activity can refresh the text. */
        var instance: TimerService? = null

        /** Set by the activity; forwards notification buttons into Dart. */
        var onAction: ((String) -> Unit)? = null
    }
}
