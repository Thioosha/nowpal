package com.example.nowpal

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AppBlockerAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("NowPalAccessibility", "🟢 SERVICE CONNECTED")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        Log.d("NowPalAccessibility", "🔵 Window changed to: $packageName")

        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val strictActive = prefs.getBoolean("flutter.strict_session_active", false)

        if (!strictActive) return
        if (packageName != "com.android.settings") return // ONLY react to Settings specifically

        Log.d("NowPalAccessibility", "🔴 KICKING OUT OF SETTINGS")
        val homeIntent = Intent(Intent.ACTION_MAIN)
        homeIntent.addCategory(Intent.CATEGORY_HOME)
        homeIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(homeIntent)
    }

    override fun onInterrupt() {}
}