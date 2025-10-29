import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';

class NotificationService {
  static StreamSubscription? _notificationSubscription;
  static bool _isListening = false;

  // Regex patterns for transaction detection
  static final RegExp _debitRegex = RegExp(
    r'\b(debited|spent|purchase|paid|withdrawn|debit|payment|sent|transferred)\b',
    caseSensitive: false,
  );

  static final RegExp _creditRegex = RegExp(
    r'\b(credited|received|deposit|income|credit|refund|cashback)\b',
    caseSensitive: false,
  );

  // Enhanced amount regex to handle various Indian banking formats
  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?\s?|INR\s?|₹\s?)([0-9,]+\.?[0-9]*)|([0-9,]+\.?[0-9]*)\s?(?:Rs\.?|INR|₹)|(?:amount|amt|sum)[\s:]*(?:Rs\.?\s?|INR\s?|₹\s?)?([0-9,]+\.?[0-9]*)',
    caseSensitive: false,
  );

  // Expanded list of financial and SMS apps
  static final List<String> _financialApps = [
    // SMS Apps
    'com.google.android.apps.messaging', // Google Messages
    'com.android.messaging', // Default SMS
    'com.samsung.android.messaging', // Samsung Messages
    'com.android.mms', // Default MMS
    'com.textra', // Textra SMS
    
    // UPI & Payment Apps
    'com.phonepe.app', // PhonePe
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'in.org.npci.upiapp', // BHIM UPI
    'net.one97.paytm', // Paytm
    'com.amazon.mShop.android.shopping', // Amazon Pay
    'in.amazon.mShop.android.shopping', // Amazon India
    'com.mobikwik_new', // MobiKwik
    'com.freecharge.android', // FreeCharge
    
    // Banking Apps
    'com.sbi.SBIFreedomPlus', // SBI
    'com.icicibank.mobile.iciciappathon', // ICICI
    'com.hdfcbank.payzapp', // HDFC
    'com.axisbank.mobile', // Axis Bank
    'com.kotakbank.mobile', // Kotak Bank
    'com.indusind.mobile', // IndusInd Bank
    
    // Other Apps
    'com.whatsapp', // WhatsApp (for payment messages)
    'com.truecaller', // Truecaller (SMS)
  ];

  /// Request notification listener permission
  static Future<bool> requestNotificationAccess() async {
    debugPrint('🔔 NOTIFICATION: Requesting notification access...');
    
    // Check if permission is already granted
    final isGranted = await NotificationListenerService.isPermissionGranted();
    
    if (isGranted) {
      debugPrint('✅ NOTIFICATION: Permission already granted');
      return true;
    }

    // Open settings to grant permission
    debugPrint('⚠️ NOTIFICATION: Opening settings to grant permission');
    await NotificationListenerService.requestPermission();
    
    return false;
  }

  /// Check if auto-detection is enabled in settings
  static Future<bool> isAutoDetectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_detect_transactions') ?? true; // Default enabled
  }

  /// Enable or disable auto-detection
  static Future<void> setAutoDetectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_detect_transactions', enabled);
    
    if (enabled && !_isListening) {
      await startListening();
    } else if (!enabled && _isListening) {
      await stopListening();
    }
  }

  /// Start listening to notifications
  static Future<void> startListening() async {
    if (_isListening) {
      debugPrint('⚠️ NOTIFICATION: Already listening');
      return;
    }

    final isEnabled = await isAutoDetectionEnabled();
    if (!isEnabled) {
      debugPrint('⚠️ NOTIFICATION: Auto-detection is disabled');
      return;
    }

    final isGranted = await NotificationListenerService.isPermissionGranted();
    debugPrint('🔍 NOTIFICATION: Permission status: $isGranted');
    
    if (!isGranted) {
      debugPrint('❌ NOTIFICATION: Permission not granted - Please enable in Settings → Notification Access');
      return;
    }

    debugPrint('🎧 NOTIFICATION: Starting notification listener...');
    debugPrint('📱 NOTIFICATION: Monitoring ${_financialApps.length} financial apps');
    
    try {
      _notificationSubscription = NotificationListenerService.notificationsStream.listen(
        (event) async {
          await _handleNotification(event);
        },
        onError: (error) {
          debugPrint('❌ NOTIFICATION: Error in stream: $error');
        },
        onDone: () {
          debugPrint('⚠️ NOTIFICATION: Stream closed');
          _isListening = false;
        },
      );

      _isListening = true;
      debugPrint('✅ NOTIFICATION: Listener started successfully');
      debugPrint('🔍 NOTIFICATION: Waiting for notifications...');
    } catch (e) {
      debugPrint('❌ NOTIFICATION: Failed to start listener: $e');
      _isListening = false;
    }
  }

  /// Stop listening to notifications
  static Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isListening = false;
    debugPrint('🛑 NOTIFICATION: Listener stopped');
  }

  /// Handle incoming notification
  static Future<void> _handleNotification(dynamic event) async {
    try {
      final packageName = event.packageName?.toString() ?? '';
      final title = event.title?.toString() ?? '';
      final content = event.content?.toString() ?? '';
      final timestamp = DateTime.now();

      debugPrint('\n📬 NOTIFICATION RECEIVED:');
      debugPrint('   📱 Package: $packageName');
      debugPrint('   📝 Title: $title');
      debugPrint('   💬 Content: $content');
      debugPrint('   ⏰ Time: ${timestamp.toString()}');

      // Check if notification is from a financial app
      final isFinancial = _isFromFinancialApp(packageName);
      debugPrint('   💰 Is Financial: $isFinancial');
      
      if (!isFinancial) {
        debugPrint('   ⏭️ SKIPPING: Not from financial app');
        return;
      }
      
      debugPrint('   ✅ PROCESSING: Financial app detected');

      // Combine title and content for parsing
      final fullText = '$title $content';

      // Parse transaction details
      final transactionData = _parseTransaction(fullText, packageName);

      if (transactionData != null) {
        // Generate unique hash to prevent duplicates
        final hash = _generateHash(fullText, timestamp);

        // Check for duplicates
        final isDuplicate = await DatabaseHelper.instance.isDuplicateTransaction(hash);
        if (isDuplicate) {
          debugPrint('⚠️ NOTIFICATION: Duplicate transaction detected, skipping');
          return;
        }

        // Insert transaction into database
        final transactionMap = {
          'amount': transactionData['amount'],
          'type': transactionData['type'],
          'date': timestamp.toIso8601String(),
          'note': transactionData['note'],
          'category': transactionData['category'],
          'icon': transactionData['icon'],
          'auto_detected': 1,
          'notification_source': packageName,
          'notification_hash': hash,
        };

        final id = await DatabaseHelper.instance.insertAutoTransaction(transactionMap);

        if (id > 0) {
          debugPrint('✅ NOTIFICATION: Auto-transaction added successfully!');
          debugPrint('   Type: ${transactionData['type']}');
          debugPrint('   Amount: ₹${transactionData['amount']}');
          debugPrint('   Category: ${transactionData['category']}');
          
          // Show local notification feedback (optional - can be implemented later)
          _showTransactionAddedFeedback(transactionData);
        }
      } else {
        debugPrint('⏭️ NOTIFICATION: No transaction detected in message');
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATION: Error handling notification: $e');
    }
  }

  /// Check if notification is from a financial app
  static bool _isFromFinancialApp(String packageName) {
    debugPrint('   🔍 Checking package: $packageName');
    
    // Check against known financial apps
    if (_financialApps.contains(packageName)) {
      debugPrint('   ✅ Found in whitelist');
      return true;
    }

    // Check for common bank app patterns
    final bankPatterns = [
      'bank',
      'upi',
      'payment',
      'wallet',
      'paisa',
      'money',
      'sms',
      'messaging',
      'message',
    ];

    for (final pattern in bankPatterns) {
      if (packageName.toLowerCase().contains(pattern)) {
        debugPrint('   ✅ Matches pattern: $pattern');
        return true;
      }
    }
    
    debugPrint('   ❌ Not a financial app');
    return false;
  }

  /// Parse transaction from notification text
  static Map<String, dynamic>? _parseTransaction(String text, String source) {
    // Check if it's a debit or credit
    final isDebit = _debitRegex.hasMatch(text);
    final isCredit = _creditRegex.hasMatch(text);

    if (!isDebit && !isCredit) {
      return null; // Not a transaction notification
    }

    // Extract amount
    final amountMatch = _amountRegex.firstMatch(text);
    if (amountMatch == null) {
      return null; // No amount found
    }

    // Get amount value (check all capture groups)
    final amountStr = (amountMatch.group(1) ?? amountMatch.group(2) ?? amountMatch.group(3) ?? '')
        .replaceAll(',', '')
        .trim();
    
    debugPrint('   💰 Found amount: $amountStr');
    
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      return null; // Invalid amount
    }

    // Determine transaction type
    final type = isDebit ? 'expense' : 'income';

    // Determine category based on keywords
    final category = _detectCategory(text, type);

    // Get icon for category
    final icon = _getIconForCategory(category);

    return {
      'amount': amount,
      'type': type,
      'note': 'Auto-detected from notification: ${text.length > 100 ? '${text.substring(0, 100)}...' : text}',
      'category': category,
      'icon': icon,
    };
  }

  /// Detect category from transaction text
  static String _detectCategory(String text, String type) {
    final lowerText = text.toLowerCase();

    if (type == 'expense') {
      // Expense categories
      if (lowerText.contains('food') || lowerText.contains('restaurant') || 
          lowerText.contains('swiggy') || lowerText.contains('zomato')) {
        return 'Food';
      } else if (lowerText.contains('shopping') || lowerText.contains('amazon') || 
                 lowerText.contains('flipkart') || lowerText.contains('myntra')) {
        return 'Shopping';
      } else if (lowerText.contains('transport') || lowerText.contains('uber') || 
                 lowerText.contains('ola') || lowerText.contains('fuel') || 
                 lowerText.contains('petrol')) {
        return 'Transport';
      } else if (lowerText.contains('bill') || lowerText.contains('electricity') || 
                 lowerText.contains('water') || lowerText.contains('gas')) {
        return 'Bills';
      } else if (lowerText.contains('entertainment') || lowerText.contains('movie') || 
                 lowerText.contains('netflix') || lowerText.contains('spotify')) {
        return 'Entertainment';
      } else if (lowerText.contains('health') || lowerText.contains('medical') || 
                 lowerText.contains('pharmacy') || lowerText.contains('hospital')) {
        return 'Health';
      }
      return 'Other';
    } else {
      // Income categories
      if (lowerText.contains('salary') || lowerText.contains('wage')) {
        return 'Salary';
      } else if (lowerText.contains('refund') || lowerText.contains('cashback')) {
        return 'Refund';
      } else if (lowerText.contains('interest')) {
        return 'Interest';
      }
      return 'Other';
    }
  }

  /// Get Material icon code point for category
  static int _getIconForCategory(String category) {
    // Material Icons code points
    switch (category) {
      case 'Food':
        return 0xe56c; // restaurant
      case 'Shopping':
        return 0xe8cc; // shopping_bag
      case 'Transport':
        return 0xe531; // directions_car
      case 'Bills':
        return 0xe8b0; // receipt
      case 'Entertainment':
        return 0xe404; // movie
      case 'Health':
        return 0xe3f3; // local_hospital
      case 'Salary':
        return 0xe263; // account_balance_wallet
      case 'Refund':
        return 0xe5d5; // replay
      case 'Interest':
        return 0xe227; // trending_up
      default:
        return 0xe8f4; // category (default)
    }
  }

  /// Generate unique hash for notification
  static String _generateHash(String text, DateTime timestamp) {
    final combined = '$text${timestamp.millisecondsSinceEpoch}';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Show feedback when transaction is added (placeholder for future implementation)
  static void _showTransactionAddedFeedback(Map<String, dynamic> data) {
    // This can be implemented with local notifications or in-app notifications
    // For now, just log it
    debugPrint('💬 FEEDBACK: Transaction added - ${data['type']} ₹${data['amount']}');
  }

  /// Get statistics about auto-detected transactions
  static Future<Map<String, dynamic>> getAutoDetectionStats() async {
    final transactions = await DatabaseHelper.instance.getAutoDetectedTransactions();
    
    double totalExpense = 0;
    double totalIncome = 0;
    
    for (final txn in transactions) {
      final amount = (txn['amount'] as num).toDouble();
      if (txn['type'] == 'expense') {
        totalExpense += amount;
      } else {
        totalIncome += amount;
      }
    }

    return {
      'total_count': transactions.length,
      'total_expense': totalExpense,
      'total_income': totalIncome,
    };
  }

  /// Test notification parsing manually (for debugging)
  static Future<void> testNotificationParsing(String testMessage) async {
    debugPrint('\n🧪 TESTING NOTIFICATION PARSING:');
    debugPrint('   📝 Test Message: $testMessage');
    
    final result = _parseTransaction(testMessage, 'com.test.app');
    
    if (result != null) {
      debugPrint('   ✅ PARSED SUCCESSFULLY:');
      debugPrint('      💰 Amount: ₹${result['amount']}');
      debugPrint('      📊 Type: ${result['type']}');
      debugPrint('      🏷️ Category: ${result['category']}');
      debugPrint('      📝 Note: ${result['note']}');
    } else {
      debugPrint('   ❌ PARSING FAILED: No transaction detected');
    }
  }

  /// Get current listening status and debug info
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final isGranted = await NotificationListenerService.isPermissionGranted();
    final isEnabled = await isAutoDetectionEnabled();
    
    return {
      'is_listening': _isListening,
      'permission_granted': isGranted,
      'auto_detection_enabled': isEnabled,
      'monitored_apps_count': _financialApps.length,
      'monitored_apps': _financialApps,
    };
  }
}
