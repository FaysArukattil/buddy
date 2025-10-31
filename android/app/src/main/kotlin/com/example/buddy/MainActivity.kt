package com.example.buddy

import android.content.Intent
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "notification_channel"
    private var notificationChannel: MethodChannel? = null
    
    companion object {
        private const val TAG = "MainActivity"
        var instance: MainActivity? = null
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set the static instance so NotificationListener can access it
        instance = this
        Log.d(TAG, "✅ MainActivity instance set")
        
        // Create MethodChannel for communication with Flutter
        notificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkNotificationPermission" -> {
                        val hasPermission = isNotificationServiceEnabled()
                        Log.d(TAG, "📋 Permission check: $hasPermission")
                        result.success(hasPermission)
                    }
                    "requestNotificationPermission" -> {
                        openNotificationSettings()
                        result.success(true)
                    }
                    else -> {
                        Log.w(TAG, "⚠️ Unknown method: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
        }
        
        Log.d(TAG, "✅ MethodChannel configured: $CHANNEL")
    }
    
    // Called by NotificationListener to send data to Flutter
    fun sendNotificationToFlutter(packageName: String, title: String, content: String) {
        Log.d(TAG, "📤 Sending to Flutter:")
        Log.d(TAG, "   📱 Package: $packageName")
        Log.d(TAG, "   📝 Title: $title")
        Log.d(TAG, "   💬 Content: ${content.take(50)}...")
        
        try {
            notificationChannel?.invokeMethod("onNotificationReceived", mapOf(
                "packageName" to packageName,
                "title" to title,
                "content" to content
            ))
            Log.d(TAG, "✅ Successfully invoked Flutter method")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error invoking Flutter method: ${e.message}", e)
        }
    }
    
    private fun isNotificationServiceEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        val packageName = packageName
        val isEnabled = enabledListeners?.contains(packageName) ?: false
        
        Log.d(TAG, "🔍 Checking notification permission:")
        Log.d(TAG, "   📦 Package: $packageName")
        Log.d(TAG, "   📋 Enabled listeners: $enabledListeners")
        Log.d(TAG, "   ✅ Is enabled: $isEnabled")
        
        return isEnabled
    }
    
    private fun openNotificationSettings() {
        Log.d(TAG, "🔓 Opening notification settings")
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "❌ MainActivity instance cleared")
    }
}