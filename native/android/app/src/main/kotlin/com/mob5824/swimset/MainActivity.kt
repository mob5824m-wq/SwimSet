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
 * The poolside timer asks for `keepAwake` so the screen does not sleep mid-set;
 * this is handled directly by the window flags instead of a third-party plugin.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "swimset/power"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
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
                        startTimerService()
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

    /** Runs the poolside timer as a foreground service so a locked screen does not stop it. */
    private fun startTimerService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_REQUEST)
        }
        val intent = Intent(this, TimerService::class.java).apply {
            putExtra(TimerService.EXTRA_TITLE, "Poolside timer running")
            putExtra(TimerService.EXTRA_TEXT, "SwimSet keeps beeping with the screen off.")
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
