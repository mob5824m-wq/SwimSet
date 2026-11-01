package com.mob5824.swimset

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and answers the small set of native calls SwimSet needs.
 *
 * The poolside timer asks for `keepAwake` so the screen does not sleep mid-set,
 * `startTimer` / `updateTimer` / `stopTimer` for the background service, and the
 * service forwards its notification buttons back through `timerAction`.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "swimset/power"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        this.channel = channel
        TimerService.onAction = { action ->
            runOnUiThread {
                try {
                    channel.invokeMethod("timerAction", action)
                } catch (_: Exception) {
                    // The engine is going away; the Dart side stops the timer anyway.
                }
            }
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "keepAwake" -> {
                    val awake = call.arguments as? Boolean ?: false
                    if (awake) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(awake)
                }
                "startTimer" -> {
                    startTimerService(payload(call.arguments))
                    result.success(true)
                }
                "updateTimer" -> {
                    val data = payload(call.arguments)
                    TimerService.instance?.update(data.title, data.text, data.running)
                    result.success(true)
                }
                "stopTimer" -> {
                    stopService(Intent(this, TimerService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        TimerService.onAction = null
        channel = null
        super.onDestroy()
    }

    private class TimerPayload(
        val title: String,
        val text: String,
        val running: Boolean,
    )

    private fun payload(arguments: Any?): TimerPayload {
        val map = arguments as? Map<*, *>
        return TimerPayload(
            title = (map?.get("title") as? String)?.takeIf { it.isNotBlank() }
                ?: "Poolside timer running",
            text = (map?.get("text") as? String)?.takeIf { it.isNotBlank() }
                ?: "SwimSet keeps timing with the screen off.",
            running = (map?.get("running") as? Boolean) ?: true,
        )
    }

    /** Runs the poolside timer as a foreground service so a locked screen does not stop it. */
    private fun startTimerService(data: TimerPayload) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_REQUEST)
        }
        val intent = Intent(this, TimerService::class.java).apply {
            putExtra(TimerService.EXTRA_TITLE, data.title)
            putExtra(TimerService.EXTRA_TEXT, data.text)
            putExtra(TimerService.EXTRA_RUNNING, data.running)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private companion object {
        const val NOTIFICATION_REQUEST = 7741
    }
}
