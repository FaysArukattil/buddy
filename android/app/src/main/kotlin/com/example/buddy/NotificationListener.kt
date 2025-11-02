package com.example.buddy

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.*

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val FOREGROUND_NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "notification_listener_channel"
        private const val QUEUE_FILE = "notification_queue.json"
        private const val PREFS_NAME = "buddy_prefs"
        
        private val FINANCIAL_APPS = setOf(
            "com.google.android.apps.messaging",
            "com.android.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.phonepe.app",
            "com.google.android.apps.nbu.paisa.user",
            "in.org.npci.upiapp",
            "net.one97.paytm",
            "com.amazon.mShop.android.shopping",
            "in.amazon.mShop.android.shopping",
            "com.mobikwik_new",
            "com.freecharge.android",
            "com.sbi.SBIFreedomPlus",
            "com.icicibank.mobile.iciciappathon",
            "com.hdfcbank.payzapp",
            "com.axisbank.mobile",
            "com.kotakbank.mobile",
            "com.indusind.mobile",
            "com.whatsapp",
            "com.whatsapp.w4b"
        )
        
        @Volatile
        private var isServiceRunning = false
    }

    private var notificationQueue: MutableList<NotificationData> = mutableListOf()
    private var wakeLock: PowerManager.WakeLock? = null
    private val recentlyProcessed = mutableSetOf<String>()

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "🚀 ============ SERVICE CREATED ============")
        
        isServiceRunning = true
        acquireWakeLock()
        loadQueueFromDisk()
        startForegroundService()
        
        Log.d(TAG, "✅ Service initialized and running in foreground")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "📡 onStartCommand called - Ensuring foreground service")
        
        if (!isServiceRunning) {
            startForegroundService()
            isServiceRunning = true
        }
        
        return START_STICKY
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "✅ ============ LISTENER CONNECTED ============")
        Log.d(TAG, "✅ Now actively monitoring financial app notifications")
        
        isServiceRunning = true
        startForegroundService()
        processQueuedNotifications()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        
        try {
            val pkg = sbn.packageName
            
            if (pkg == applicationContext.packageName) {
                Log.d(TAG, "🚫 Skipping own app notification")
                return
            }
            
            val extras = sbn.notification.extras
            val title = extras.getCharSequence("android.title")?.toString() ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
            val content = if (bigText.isNotEmpty()) bigText else text
            
            Log.d(TAG, "📬 NOTIFICATION: $pkg | $title | ${content.take(50)}")
            
            if (!isFromFinancialApp(pkg)) {
                Log.d(TAG, "   ⏭️ Skipping non-financial app")
                return
            }
            
            if (title.isEmpty() && content.isEmpty()) {
                Log.d(TAG, "   ⏭️ Skipping empty notification")
                return
            }
            
            if (isOwnConfirmationNotification(title, content)) {
                Log.d(TAG, "   🚫 Skipping own confirmation notification")
                return
            }
            
            Log.d(TAG, "   ✅ FINANCIAL NOTIFICATION DETECTED!")
            
            processNotificationNatively(pkg, title, content)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing notification: ${e.message}", e)
        }
    }

    private fun isOwnConfirmationNotification(title: String, content: String): Boolean {
        val lower = "$title $content".lowercase()
        return lower.contains("duplicate") ||
               lower.contains("transaction added") ||
               lower.contains("expense tracker") ||
               lower.contains("monitoring financial") ||
               lower.contains("possible duplicate") ||
               lower.contains("similar transaction")
    }

    private fun processNotificationNatively(pkg: String, title: String, content: String) {
        try {
            val fullText = "$title $content"
            val notificationKey = "$pkg|$title|$content"
            
            // Generate unique hash with timestamp
            val timestampedText = "$fullText|${System.currentTimeMillis()}"
            val hash = generateHash(timestampedText)
            
            // Prevent duplicate processing within 10 seconds
            if (recentlyProcessed.contains(notificationKey)) {
                Log.d(TAG, "   🚫 Already processed recently (same notification)")
                return
            }
            recentlyProcessed.add(notificationKey)
            
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                recentlyProcessed.remove(notificationKey)
            }, 10000)
            
            val transaction = parseTransactionNative(fullText) ?: run {
                Log.d(TAG, "   ⏭️ Could not parse transaction")
                queueNotification(NotificationData(pkg, title, content, System.currentTimeMillis()))
                return
            }
            
            Log.d(TAG, "   💰 Parsed: ₹${transaction.amount} ${transaction.type}")
            
            // Check for similar transactions FIRST
            val similarCount = countSimilarTransactions(transaction.amount, transaction.type)
            
            if (similarCount > 0) {
                Log.d(TAG, "   ⚠️ Found $similarCount similar transaction(s) in last 24 hours")
                
                // Store as pending and show confirmation
                storePendingTransaction(hash, transaction, pkg)
                showDuplicateConfirmationNotification(hash, transaction, similarCount)
                
                Log.d(TAG, "   📬 Waiting for user confirmation...")
                return
            }
            
            // Check if exact hash exists
            if (isDuplicateTransaction(hash)) {
                Log.d(TAG, "   ⚠️ Exact duplicate hash detected - already processed")
                return
            }
            
            // NEW transaction - save to SharedPreferences AND notify Flutter
            Log.d(TAG, "   ✅ No similar transactions - saving directly")
            val saved = saveTransaction(hash, transaction, pkg)
            
            if (saved) {
                // CRITICAL: Send to Flutter immediately for database insert
                notifyFlutterOfNewTransaction(hash, transaction, pkg)
                showTransactionAddedNotification(transaction)
            } else {
                Log.e(TAG, "   ❌ Failed to save transaction")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in native processing: ${e.message}", e)
        }
    }

    private fun parseTransactionNative(text: String): Transaction? {
        try {
            val lowerText = text.lowercase()
            
            val isDebit = when {
                lowerText.contains("paid you") || 
                lowerText.contains("sent you") || 
                lowerText.contains("received from") -> false
                
                lowerText.contains("you paid") || 
                lowerText.contains("you sent") || 
                lowerText.contains("paid to") ||
                lowerText.contains("debited from") ||
                lowerText.contains("withdrawn") -> true
                
                lowerText.contains("credited to") ||
                lowerText.contains("refund") ||
                lowerText.contains("cashback") -> false
                
                lowerText.contains("debited") || 
                lowerText.contains("spent") || 
                lowerText.contains("payment") -> true
                
                lowerText.contains("credited") || 
                lowerText.contains("received") -> false
                
                else -> return null
            }
            
            val amountPattern = Regex("""(?:Rs\.?\s?|INR\s?|₹\s?)([0-9,]+\.?[0-9]*)|([0-9,]+\.?[0-9]*)\s?(?:Rs\.?|INR|₹)""", RegexOption.IGNORE_CASE)
            val amountMatch = amountPattern.find(text) ?: return null
            
            val amountStr = (amountMatch.groupValues[1].ifEmpty { amountMatch.groupValues[2] })
                .replace(",", "")
                .trim()
            
            val amount = amountStr.toDoubleOrNull() ?: return null
            
            if (amount <= 0) return null
            
            val type = if (isDebit) "expense" else "income"
            val category = detectCategory(lowerText, type)
            val icon = getIconForCategory(category)
            
            Log.d(TAG, "   🔍 Parsed: amount=$amount, type=$type, category=$category")
            
            return Transaction(amount, type, category, icon, text.take(100))
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Parse error: ${e.message}")
            return null
        }
    }

    private fun detectCategory(text: String, type: String): String {
        return if (type == "expense") {
            when {
                text.contains("food") || text.contains("swiggy") || text.contains("zomato") -> "Food"
                text.contains("amazon") || text.contains("flipkart") -> "Shopping"
                text.contains("uber") || text.contains("ola") || text.contains("fuel") -> "Transport"
                text.contains("bill") || text.contains("electricity") -> "Bills"
                text.contains("movie") || text.contains("netflix") -> "Entertainment"
                text.contains("pharmacy") || text.contains("hospital") -> "Health"
                else -> "Other"
            }
        } else {
            when {
                text.contains("salary") -> "Salary"
                text.contains("refund") || text.contains("cashback") -> "Refund"
                text.contains("interest") -> "Interest"
                else -> "Other"
            }
        }
    }

    private fun getIconForCategory(category: String): Int {
        return when (category) {
            "Food" -> 0xe56c
            "Shopping" -> 0xe8cc
            "Transport" -> 0xe531
            "Bills" -> 0xe8b0
            "Entertainment" -> 0xe404
            "Health" -> 0xe3f3
            "Salary" -> 0xe263
            "Refund" -> 0xe5d5
            "Interest" -> 0xe227
            else -> 0xe8f4
        }
    }

    private fun generateHash(text: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(text.toByteArray())
        return hash.joinToString("") { "%02x".format(it) }
    }

    private fun isDuplicateTransaction(hash: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.contains("txn_$hash")
    }

    private fun countSimilarTransactions(amount: Double, type: String): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val oneDayAgo = now - (24 * 60 * 60 * 1000)
        
        var count = 0
        val allPrefs = prefs.all
        
        for ((key, value) in allPrefs) {
            if (key.startsWith("txn_") || key.startsWith("pending_")) {
                try {
                    val json = JSONObject(value as String)
                    val txnAmount = json.getDouble("amount")
                    val txnType = json.getString("type")
                    val txnTime = json.getLong("timestamp")
                    
                    if (txnAmount == amount && txnType == type && txnTime >= oneDayAgo) {
                        count++
                    }
                } catch (e: Exception) {
                    // Skip invalid entries
                }
            }
        }
        
        return count
    }

    private fun saveTransaction(hash: String, transaction: Transaction, source: String): Boolean {
        return try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = JSONObject().apply {
                put("amount", transaction.amount)
                put("type", transaction.type)
                put("category", transaction.category)
                put("icon", transaction.icon)
                put("note", "Auto-detected: ${transaction.note}")
                put("source", source)
                put("timestamp", System.currentTimeMillis())
                put("date", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(Date()))
            }
            
            val success = prefs.edit().putString("txn_$hash", json.toString()).commit()
            
            if (success) {
                Log.d(TAG, "💾 Transaction saved to SharedPreferences: $hash")
            } else {
                Log.e(TAG, "❌ Failed to save to SharedPreferences")
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception saving transaction: ${e.message}", e)
            false
        }
    }

    private fun storePendingTransaction(hash: String, transaction: Transaction, source: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = JSONObject().apply {
            put("amount", transaction.amount)
            put("type", transaction.type)
            put("category", transaction.category)
            put("icon", transaction.icon)
            put("note", "Auto-detected: ${transaction.note}")
            put("source", source)
            put("timestamp", System.currentTimeMillis())
        }
        
        prefs.edit().putString("pending_$hash", json.toString()).apply()
        Log.d(TAG, "💾 Pending transaction stored: $hash")
    }

    private fun notifyFlutterOfNewTransaction(hash: String, transaction: Transaction, source: String) {
        Log.d(TAG, "📤 Notifying Flutter of new transaction: $hash")
        
        try {
            val isoDate = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }.format(Date())
            
            val transactionData = mapOf(
                "hash" to hash,
                "amount" to transaction.amount,
                "type" to transaction.type,
                "category" to transaction.category,
                "icon" to transaction.icon,
                "note" to "Auto-detected: ${transaction.note}",
                "source" to source,
                "timestamp" to System.currentTimeMillis(),
                "date" to isoDate
            )
            
            Log.d(TAG, "📦 Transaction data prepared:")
            Log.d(TAG, "   Amount: ${transaction.amount}")
            Log.d(TAG, "   Type: ${transaction.type}")
            Log.d(TAG, "   Date: $isoDate")
            Log.d(TAG, "   Category: ${transaction.category}")
            
            MainActivity.instance?.saveTransactionToDatabase(transactionData)
            
            Log.d(TAG, "✅ Flutter notified successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error notifying Flutter: ${e.message}", e)
        }
    }

    private fun showDuplicateConfirmationNotification(hash: String, transaction: Transaction, similarCount: Int) {
        val channelId = "duplicate_confirmations"
        createNotificationChannel(channelId, "Transaction Confirmations", NotificationManager.IMPORTANCE_HIGH)
        
        val typeIcon = if (transaction.type == "expense") "💸" else "💰"
        
        val yesIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "ACTION_YES"
            putExtra("hash", hash)
        }
        val yesPendingIntent = PendingIntent.getBroadcast(
            this, 
            hash.hashCode(), 
            yesIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val noIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "ACTION_NO"
            putExtra("hash", hash)
        }
        val noPendingIntent = PendingIntent.getBroadcast(
            this, 
            hash.hashCode() + 1, 
            noIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("⚠️ Possible Duplicate Transaction")
            .setContentText("$typeIcon ₹${transaction.amount} (${transaction.category})")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("$typeIcon ₹${transaction.amount} - ${transaction.category}\n\nFound $similarCount similar transaction(s) in last 24 hours.\n\nIs this a NEW transaction?"))
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(false)
            .addAction(android.R.drawable.ic_input_add, "✅ Yes, Add", yesPendingIntent)
            .addAction(android.R.drawable.ic_delete, "❌ No, Ignore", noPendingIntent)
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(hash.hashCode(), notification)
        
        Log.d(TAG, "🔔 Duplicate confirmation notification shown")
    }

    private fun showTransactionAddedNotification(transaction: Transaction) {
        val channelId = "transaction_added"
        createNotificationChannel(channelId, "Transactions Added", NotificationManager.IMPORTANCE_DEFAULT)
        
        val typeIcon = if (transaction.type == "expense") "💸" else "💰"
        
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("✅ Transaction Added")
            .setContentText("$typeIcon ₹${transaction.amount} - ${transaction.category}")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
        
        Log.d(TAG, "🔔 Transaction added notification shown")
    }

    private fun isFromFinancialApp(packageName: String): Boolean {
        if (FINANCIAL_APPS.contains(packageName)) return true
        
        val lower = packageName.lowercase()
        val keywords = listOf("bank", "upi", "payment", "wallet", "paisa", "money", "sms", "message", "messaging")
        
        return keywords.any { lower.contains(it) }
    }

    private fun queueNotification(data: NotificationData) {
        notificationQueue.add(data)
        saveQueueToDisk()
        Log.d(TAG, "💾 Queued notification (total: ${notificationQueue.size})")
    }

    private fun processQueuedNotifications() {
        if (notificationQueue.isEmpty()) {
            Log.d(TAG, "📭 No queued notifications")
            return
        }
        
        Log.d(TAG, "📮 Processing ${notificationQueue.size} queued notifications")
        
        val activity = MainActivity.instance
        if (activity != null) {
            val toProcess = notificationQueue.toList()
            
            activity.runOnUiThread {
                for (data in toProcess) {
                    try {
                        activity.sendNotificationToFlutter(data.packageName, data.title, data.content)
                        notificationQueue.remove(data)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error processing queued: ${e.message}")
                    }
                }
                saveQueueToDisk()
            }
        }
    }

    private fun saveQueueToDisk() {
        try {
            val file = File(applicationContext.filesDir, QUEUE_FILE)
            val jsonArray = org.json.JSONArray()
            
            for (data in notificationQueue) {
                val json = JSONObject().apply {
                    put("packageName", data.packageName)
                    put("title", data.title)
                    put("content", data.content)
                    put("timestamp", data.timestamp)
                }
                jsonArray.put(json)
            }
            
            file.writeText(jsonArray.toString())
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error saving queue: ${e.message}", e)
        }
    }

    private fun loadQueueFromDisk() {
        try {
            val file = File(applicationContext.filesDir, QUEUE_FILE)
            if (!file.exists()) return
            
            val jsonArray = org.json.JSONArray(file.readText())
            notificationQueue.clear()
            
            for (i in 0 until jsonArray.length()) {
                val json = jsonArray.getJSONObject(i)
                val data = NotificationData(
                    json.getString("packageName"),
                    json.getString("title"),
                    json.getString("content"),
                    json.getLong("timestamp")
                )
                notificationQueue.add(data)
            }
            
            Log.d(TAG, "📂 Loaded ${notificationQueue.size} notifications")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading queue: ${e.message}", e)
        }
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "NotificationListener::WakeLock")
            wakeLock?.acquire(10 * 60 * 1000L)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error acquiring wake lock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.release()
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error releasing wake lock: ${e.message}")
        }
    }

    private fun startForegroundService() {
        createNotificationChannel(CHANNEL_ID, "Transaction Monitor", NotificationManager.IMPORTANCE_LOW)
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Expense Tracker Active")
            .setContentText("Monitoring financial notifications")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
        
        startForeground(FOREGROUND_NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel(channelId: String, channelName: String, importance: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.e(TAG, "❌ LISTENER DISCONNECTED")
        isServiceRunning = false
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            requestRebind(android.content.ComponentName(this, NotificationListener::class.java))
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "🛑 SERVICE DESTROYED")
        isServiceRunning = false
        releaseWakeLock()
        saveQueueToDisk()
        super.onDestroy()
        
        val restartIntent = Intent(applicationContext, NotificationListener::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(restartIntent)
        } else {
            applicationContext.startService(restartIntent)
        }
    }

    data class NotificationData(
        val packageName: String,
        val title: String,
        val content: String,
        val timestamp: Long
    )
    
    data class Transaction(
        val amount: Double,
        val type: String,
        val category: String,
        val icon: Int,
        val note: String
    )
}