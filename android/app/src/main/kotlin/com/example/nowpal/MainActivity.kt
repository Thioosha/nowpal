package com.example.nowpal

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.nowpal/launch"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getLaunchExtrasextractExtras(intent: Intent?)") {
                result.success(extractExtras(intent))
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(newIntent: Intent) {
        super.onNewIntent(newIntent)
        setIntent(newIntent)
        val extras = extractExtras(newIntent)
        if (extras != null) {
            methodChannel?.invokeMethod("onNewLaunchExtras", extras)
        }
    }

    private fun extractExtras(intent: Intent?): Map<String, Any>? {
        val extras = intent?.extras
        return if (extras != null && extras.getBoolean("launchStrictSession", false)) {
            mapOf(
                "launchStrictSession" to true,
                "focusMinutes" to extras.getInt("focusMinutes", 25),
                "breakMinutes" to extras.getInt("breakMinutes", 5),
                "sessionId" to (extras.getString("sessionId") ?: "")
            )
        } else null
    }
}