package com.example.buddy

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NotificationAction"
        private const val PREFS_NAME = "buddy_prefs"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val hash = intent.getStringExtra("hash") ?: return
        val action = intent.action
        
        Log.d(TAG, "📨 Action received: $action for hash: $hash")
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(hash.hashCode())
        
        when (action) {
            "ACTION_YES" -> handleYes(context, hash)
            "ACTION_NO" -> handleNo(context, hash)
        }
    }

    private fun handleYes(context: Context, hash: String) {
        Log.d(TAG, "✅ User clicked YES - Adding transaction")
        
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val pendingJson = prefs.getString("pending_$hash", null)
        
        if (pendingJson != null) {
            try {
                val json = JSONObject(pendingJson)
                
                // Ensure date is in ISO 8601 format
                val dateStr = if (json.has("date")) {
                    json.getString("date")
                } else {
                    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                        timeZone = TimeZone.getTimeZone("UTC")
                    }.format(Date())
                }
                
                // Update date if needed
                json.put("date", dateStr)
                
                // Save as actual transaction in SharedPreferences
                prefs.edit().putString("txn_$hash", json.toString()).commit()
                
                // Remove pending
                prefs.edit().remove("pending_$hash").commit()
                
                Log.d(TAG, "✅ Transaction moved from pending to confirmed")
                
                // CRITICAL: Notify Flutter to save to database with proper format
                val transactionData = mapOf(
                    "hash" to hash,
                    "amount" to json.getDouble("amount"),
                    "type" to json.getString("type"),
                    "category" to json.getString("category"),
                    "icon" to json.getInt("icon"),
                    "note" to json.optString("note", "Auto-detected from notification"),
                    "source" to json.optString("source", "unknown"),
                    "timestamp" to json.optLong("timestamp", System.currentTimeMillis()),
                    "date" to dateStr
                )
                
                Log.d(TAG, "📦 Sending transaction data to Flutter:")
                Log.d(TAG, "   Amount: ${transactionData["amount"]}")
                Log.d(TAG, "   Date: ${transactionData["date"]}")
                Log.d(TAG, "   Type: ${transactionData["type"]}")
                
                MainActivity.instance?.saveTransactionToDatabase(transactionData)
                
                // Show success notification
                showSuccessNotification(context, json)
                
                // Also notify via duplicate response handler
                MainActivity.instance?.handleDuplicateResponse(hash, true)
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error handling YES: ${e.message}", e)
            }
        } else {
            Log.e(TAG, "❌ No pending transaction found for hash: $hash")
        }
    }

    private fun handleNo(context: Context, hash: String) {
        Log.d(TAG, "❌ User clicked NO - Ignoring transaction")
        
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove("pending_$hash").commit()
        
        Log.d(TAG, "✅ Pending transaction removed")
        
        MainActivity.instance?.handleDuplicateResponse(hash, false)
    }

    private fun showSuccessNotification(context: Context, json: JSONObject) {
        val amount = json.getDouble("amount")
        val type = json.getString("type")
        val category = json.getString("category")
        val typeIcon = if (type == "expense") "💸" else "💰"
        
        val channelId = "transaction_added"
        
        val notification = NotificationCompat.Builder(context, channelId)
            .setContentTitle("✅ Transaction Added")
            .setContentText("$typeIcon ₹$amount - $category")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
        
        Log.d(TAG, "🔔 Success notification shown")
    }
}