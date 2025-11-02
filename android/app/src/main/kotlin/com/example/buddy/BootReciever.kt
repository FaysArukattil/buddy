package com.example.buddy

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Automatically starts the NotificationListener service after device boot
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d(TAG, "📱 Device booted - starting NotificationListener service")
            
            try {
                val serviceIntent = Intent(context, NotificationListener::class.java)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                
                Log.d(TAG, "✅ NotificationListener service started after boot")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error starting service after boot: ${e.message}", e)
            }
        }
    }
}