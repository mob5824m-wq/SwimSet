package com.mob5824.swimset

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
                    else -> result.notImplemented()
                }
            }
    }
}
