package com.student_stress_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val UNLOCK_CHANNEL = "com.student_stress_app/unlock"
    private var unlockChannel: MethodChannel? = null

    // BroadcastReceiver that fires only on real device unlock (PIN / biometric / swipe)
    private val unlockReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_USER_PRESENT) {
                // Post to main thread so Flutter channel call is safe
                runOnUiThread {
                    unlockChannel?.invokeMethod("unlock", null)
                }
                android.util.Log.d("MainActivity", "Device unlocked — sent event to Flutter")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        unlockChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UNLOCK_CHANNEL
        )
    }

    override fun onStart() {
        super.onStart()
        // Register receiver for real device unlock events
        // ACTION_USER_PRESENT needs no special permission
        val filter = IntentFilter(Intent.ACTION_USER_PRESENT)
        registerReceiver(unlockReceiver, filter)
        android.util.Log.d("MainActivity", "Unlock BroadcastReceiver registered")
    }

    override fun onStop() {
        super.onStop()
        try {
            unregisterReceiver(unlockReceiver)
            android.util.Log.d("MainActivity", "Unlock BroadcastReceiver unregistered")
        } catch (e: IllegalArgumentException) {
            // Receiver was not registered — safe to ignore
        }
    }
}
