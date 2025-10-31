package com.example.buddy
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
class NotificationListener : NotificationListenerService() {
companion object {
    private const val TAG = "NotificationListener"
}

override fun onListenerConnected() {
    super.onListenerConnected()
    Log.d(TAG, "✅✅✅ NOTIFICATION LISTENER CONNECTED! ✅✅✅")
}

override fun onListenerDisconnected() {
    super.onListenerDisconnected()
    Log.e(TAG, "❌❌❌ NOTIFICATION LISTENER DISCONNECTED! ❌❌❌")
}

override fun onNotificationPosted(sbn: StatusBarNotification?) {
    if (sbn == null) {
        Log.d(TAG, "⚠️ Received null notification")
        return
    }
    
    try {
        val packageName = sbn.packageName
        val notification = sbn.notification
        
        // Log EVERY notification received
        Log.d(TAG, "📬📬📬 NOTIFICATION RECEIVED 📬📬📬")
        Log.d(TAG, "📱 Package: $packageName")
        
        val extras = notification.extras
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        
        Log.d(TAG, "📝 Title: $title")
        Log.d(TAG, "💬 Text: $text")
        if (bigText.isNotEmpty()) {
            Log.d(TAG, "📄 BigText: $bigText")
        }
        
        // Send to Flutter
        val content = bigText.ifEmpty { text }
        sendToFlutter(packageName, title, content)
        
    } catch (e: Exception) {
        Log.e(TAG, "❌ Error processing notification: ${e.message}", e)
    }
}

override fun onNotificationRemoved(sbn: StatusBarNotification?) {
    // Optional: Log when notifications are dismissed
    sbn?.let {
        Log.d(TAG, "🗑️ Notification removed from: ${it.packageName}")
    }
}

private fun sendToFlutter(packageName: String, title: String, content: String) {
    try {
        // Get MainActivity's method channel
        val activity = MainActivity.instance
        if (activity != null) {
            activity.runOnUiThread {
                activity.sendNotificationToFlutter(packageName, title, content)
            }
            Log.d(TAG, "✅ Sent to Flutter via MainActivity")
        } else {
            Log.e(TAG, "❌ MainActivity instance is null! Cannot send to Flutter.")
            Log.e(TAG, "💡 Make sure MainActivity.instance is set in configureFlutterEngine()")
        }
    } catch (e: Exception) {
        Log.e(TAG, "❌ Error sending to Flutter: ${e.message}", e)
    }
}
}