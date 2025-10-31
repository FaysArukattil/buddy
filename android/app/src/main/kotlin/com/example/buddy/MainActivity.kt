package com.example.buddy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.util.Log

class MainActivity : FlutterActivity() {

    companion object {
        var instance: MainActivity? = null
        private const val CHANNEL = "notification_channel"
    }

    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this

        // Create the MethodChannel for Flutter <-> Android communication
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startNotificationService" -> {
                    Log.d("MainActivity", "Starting NotificationListener service...")
                    startService(Intent(this, NotificationListener::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        Log.d("MainActivity", "✅ MethodChannel '$CHANNEL' ready")
    }

    // Called by NotificationListener.kt
    fun sendNotificationToFlutter(packageName: String, title: String, content: String) {
        Log.d("MainActivity", "📤 Sending notification to Flutter: $title -> $content")
        try {
            val map = mapOf(
                "package" to packageName,
                "title" to title,
                "content" to content
            )
            channel.invokeMethod("onNotificationReceived", map)
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error sending notification to Flutter: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}
