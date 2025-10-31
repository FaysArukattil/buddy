package com.example.buddy

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val CHANNEL = "buddy/notification_listener"
    }

    private var flutterEngine: FlutterEngine? = null
    private var channel: MethodChannel? = null

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "✅ Notification listener connected!")

        // Initialize a FlutterEngine to send data even if app is backgrounded
        try {
            if (flutterEngine == null) {
                flutterEngine = FlutterEngine(this).apply {
                    dartExecutor.executeDartEntrypoint(
                        DartExecutor.DartEntrypoint.createDefault()
                    )
                }
                channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                Log.d(TAG, "🚀 FlutterEngine started in background for notifications")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting FlutterEngine: ${e.message}", e)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        try {
            val pkg = sbn.packageName
            val extras = sbn.notification.extras

            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""

            val content = if (bigText.isNotEmpty()) bigText else text

            Log.d(TAG, "📬 Notification: $pkg | $title → ${content.take(60)}")

            // Prefer active Flutter session first
            val activity = MainActivity.instance
            if (activity != null) {
                activity.runOnUiThread {
                    activity.sendNotificationToFlutter(pkg, title, content)
                }
                Log.d(TAG, "✅ Sent to Flutter via active MainActivity")
            } else {
                // Fallback for background
                sendViaBackgroundEngine(pkg, title, content)
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing notification: ${e.message}", e)
        }
    }

    private fun sendViaBackgroundEngine(packageName: String, title: String, content: String) {
        try {
            if (channel == null) {
                Log.e(TAG, "⚠️ Channel is null, creating background FlutterEngine...")
                flutterEngine = FlutterEngine(this).apply {
                    dartExecutor.executeDartEntrypoint(
                        DartExecutor.DartEntrypoint.createDefault()
                    )
                }
                channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            }

            val map = mapOf(
                "packageName" to packageName,
                "title" to title,
                "content" to content
            )

            channel?.invokeMethod("onNotificationReceived", map)
            Log.d(TAG, "📡 Sent via background FlutterEngine")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Background send failed: ${e.message}", e)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.e(TAG, "❌ Notification listener disconnected")
    }
}
