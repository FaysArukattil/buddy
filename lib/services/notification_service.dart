// lib/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'notification_helper.dart';

typedef OnTransactionDetected =
    Future<void> Function(Map<String, Object?> transactionMap, String hash);

class NotificationService {
  static const MethodChannel _nativeChannel = MethodChannel(
    'notification_channel',
  );

  static StreamSubscription? _notificationSubscription;
  static bool _isListening = false;

  // FIXED: More specific regex patterns
  static final RegExp _debitRegex = RegExp(
    r'\b(debited|spent|purchase|paid|withdrawn|debit|payment|sent|transferred|transfer to|paid to)\b',
    caseSensitive: false,
  );

  static final RegExp _creditRegex = RegExp(
    r'\b(credited|received|deposit|income|credit|refund|cashback|received from|got)\b',
    caseSensitive: false,
  );

  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?\s?|INR\s?|₹\s?)([0-9,]+\.?[0-9]*)|([0-9,]+\.?[0-9]*)\s?(?:Rs\.?|INR|₹)|(?:amount|amt|sum)[\s:]*(?:Rs\.?\s?|INR\s?|₹\s?)?([0-9,]+\.?[0-9]*)',
    caseSensitive: false,
  );

  // Corrected package names for PhonePe and Paytm
  static final List<String> _financialApps = [
    // SMS/Messaging apps
    'com.google.android.apps.messaging',
    'com.android.messaging',
    'com.samsung.android.messaging',
    'com.android.mms',
    'com.textra',

    // Payment apps
    'com.phonepe.app', // PhonePe
    'com.google.android.apps.nbu.paisa.user', // Google Pay
    'in.org.npci.upiapp', // BHIM UPI
    'net.one97.paytm', // Paytm
    'com.paytm', // Paytm alternate
    // E-commerce
    'com.amazon.mShop.android.shopping',
    'in.amazon.mShop.android.shopping',

    // Wallets
    'com.mobikwik_new',
    'com.freecharge.android',

    // Banking apps
    'com.sbi.SBIFreedomPlus',
    'com.icicibank.mobile.iciciappathon',
    'com.hdfcbank.payzapp',
    'com.axisbank.mobile',
    'com.kotakbank.mobile',
    'com.indusind.mobile',

    // Communication (for bank SMS)
    'com.whatsapp',
    'com.truecaller',
  ];

  static Future<bool> requestNotificationAccess() async {
    debugPrint('🔔 NOTIFICATION: Requesting notification access...');
    final isGranted = await NotificationListenerService.isPermissionGranted();
    if (isGranted) {
      debugPrint('✅ NOTIFICATION: Permission already granted');
      return true;
    }
    debugPrint('⚠️ NOTIFICATION: Opening settings to grant permission');
    await NotificationListenerService.requestPermission();
    return false;
  }

  static Future<bool> isAutoDetectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_detect_transactions') ?? true;
  }

  static Future<void> setAutoDetectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_detect_transactions', enabled);
    if (enabled && !_isListening) {
      await startListening();
    } else if (!enabled && _isListening) {
      await stopListening();
    }
  }

  static Future<void> startListening([
    OnTransactionDetected? onTransactionDetected,
  ]) async {
    if (_isListening) {
      debugPrint('⚠️ NOTIFICATION: Already listening');
      return;
    }

    final isEnabled = await isAutoDetectionEnabled();
    if (!isEnabled) {
      debugPrint('⚠️ NOTIFICATION: Auto-detection disabled');
      return;
    }

    final isGranted = await NotificationListenerService.isPermissionGranted();
    debugPrint('🔍 NOTIFICATION: Permission status: $isGranted');
    if (!isGranted) {
      debugPrint(
        '❌ NOTIFICATION: Permission not granted - enable in Settings → Notification Access',
      );
      return;
    }

    debugPrint('🎧 NOTIFICATION: Starting notification listener...');

    try {
      _notificationSubscription = NotificationListenerService
          .notificationsStream
          .listen(
            (event) async {
              try {
                final result = await _handleNotification(event);
                if (result != null && onTransactionDetected != null) {
                  final transactionMap =
                      result['transactionMap'] as Map<String, Object?>;
                  final hash = result['hash'] as String;
                  await onTransactionDetected(transactionMap, hash);
                }
              } catch (e) {
                debugPrint('❌ NOTIFICATION: Error processing stream event: $e');
              }
            },
            onError: (error) {
              debugPrint('❌ NOTIFICATION: Stream error: $error');
            },
            onDone: () {
              debugPrint('⚠️ NOTIFICATION: Stream closed');
              _isListening = false;
            },
          );
    } catch (e) {
      debugPrint(
        '⚠️ NOTIFICATION: Could not attach to notificationsStream: $e',
      );
    }

    _nativeChannel.setMethodCallHandler((call) async {
      try {
        debugPrint(
          '📨 MethodChannel.call.method=${call.method} args=${call.arguments}',
        );
        if (call.method == 'onNotificationReceived' ||
            call.method == 'notification') {
          final args = call.arguments;
          Map<String, Object?> mapArgs = {};

          if (args is Map) {
            args.forEach((k, v) {
              mapArgs[k.toString()] = v;
            });
          }

          debugPrint('📨 MethodChannel event received: $mapArgs');

          final event = {
            'package': mapArgs['package'] ?? mapArgs['packageName'] ?? '',
            'title': mapArgs['title'] ?? '',
            'content':
                mapArgs['content'] ?? mapArgs['text'] ?? mapArgs['body'] ?? '',
          };

          final result = await _handleNotification(event);
          if (result != null && onTransactionDetected != null) {
            final transactionMap =
                result['transactionMap'] as Map<String, Object?>;
            final hash = result['hash'] as String;
            await onTransactionDetected(transactionMap, hash);
          }
        }
      } catch (e) {
        debugPrint('❌ NOTIFICATION: Error handling MethodChannel call: $e');
      }
    });

    _isListening = true;
    debugPrint('✅ NOTIFICATION: Listener started (stream + MethodChannel)');
  }

  static Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;
      _nativeChannel.setMethodCallHandler(null);
      _isListening = false;
      debugPrint('🛑 NOTIFICATION: Listener stopped');
    } catch (e) {
      debugPrint('❌ NOTIFICATION: Error stopping listener: $e');
    }
  }

  static Future<Map<String, Object?>?> _handleNotification(
    dynamic event,
  ) async {
    try {
      String packageName = '';
      String title = '';
      String content = '';
      final timestamp = DateTime.now();

      if (event is Map) {
        packageName =
            (event['package'] ?? event['packageName'] ?? event['pkg'])
                ?.toString() ??
            '';
        title = (event['title'] ?? event['t'] ?? '')?.toString() ?? '';
        content =
            (event['content'] ?? event['text'] ?? event['body'] ?? '')
                ?.toString() ??
            '';
      } else {
        try {
          final pn = event.packageName;
          final tt = event.title;
          final cc = event.content ?? event.text ?? event.bigText;
          packageName = pn?.toString() ?? '';
          title = tt?.toString() ?? '';
          content = cc?.toString() ?? '';
        } catch (_) {
          final s = event?.toString() ?? '';
          content = s;
        }
      }

      debugPrint('📬 NOTIFICATION: $packageName | $title | $content');

      final isFinancial = _isFromFinancialApp(packageName);
      debugPrint('   💰 Is financial: $isFinancial');
      if (!isFinancial) return null;

      final fullText = '$title $content'.trim();
      final txnData = _parseTransaction(fullText, packageName);
      if (txnData == null) {
        debugPrint('   ⏭️ No transaction parsed');
        return null;
      }

      final hash = _generateHash(fullText, timestamp);

      // Check if this EXACT notification was already processed (exact hash match)
      final isDuplicateHash = await DatabaseHelper.instance
          .isDuplicateTransaction(hash);
      if (isDuplicateHash) {
        debugPrint(
          '   ⚠️ Exact duplicate notification detected (same hash) - skipping',
        );
        return null;
      }

      // Check for similar transactions (same amount and type) in last 24 hours
      final similarTransactions = await DatabaseHelper.instance
          .findSimilarTransactions(
            amount: txnData['amount'] as double,
            type: txnData['type'] as String,
            hoursWindow: 24,
          );

      final transactionMap = <String, Object?>{
        'amount': txnData['amount'],
        'type': txnData['type'],
        'date': timestamp.toIso8601String(),
        'note': txnData['note'],
        'category': txnData['category'],
        'icon': txnData['icon'],
        'auto_detected': 1,
        'notification_source': packageName,
        'notification_hash': hash,
      };

      // If similar transactions exist, ALWAYS ask for confirmation
      if (similarTransactions.isNotEmpty) {
        debugPrint(
          '   ⚠️ Found ${similarTransactions.length} similar transaction(s) in last 24h',
        );
        for (var similar in similarTransactions) {
          debugPrint(
            '   Previous: ₹${similar['amount']} on ${similar['date']}',
          );
        }

        // Store as pending and ask user
        await DatabaseHelper.instance.storePendingTransaction(
          hash,
          transactionMap,
        );

        // Show confirmation notification
        await NotificationHelper.showDuplicateConfirmation(
          transactionHash: hash,
          amount: txnData['amount'] as double,
          type: txnData['type'] as String,
          category: txnData['category'] as String,
          similarCount: similarTransactions.length,
        );

        debugPrint('   📬 Waiting for user confirmation...');
        return null; // Don't add yet, waiting for user action
      }

      // No similar transaction - add directly without asking
      final id = await DatabaseHelper.instance.insertAutoTransaction(
        transactionMap,
      );
      if (id > 0) {
        debugPrint('✅ NOTIFICATION: Auto-transaction inserted (id=$id)');
        await NotificationHelper.showTransactionAdded(
          amount: txnData['amount'] as double,
          type: txnData['type'] as String,
          category: txnData['category'] as String,
        );
        return {'transactionMap': transactionMap, 'hash': hash};
      } else {
        debugPrint('⚠️ NOTIFICATION: Insert returned id=$id');
        return null;
      }
    } catch (e, st) {
      debugPrint('❌ NOTIFICATION: Exception: $e\n$st');
      return null;
    }
  }

  static bool _isFromFinancialApp(String packageName) {
    if (packageName.isEmpty) return true;
    if (_financialApps.contains(packageName)) return true;
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
    final lower = packageName.toLowerCase();
    for (final p in bankPatterns) {
      if (lower.contains(p)) return true;
    }
    return false;
  }

  // FIXED: Correct GPay logic - "paid you" = credit, "you paid" = debit
  static Map<String, dynamic>? _parseTransaction(String text, String source) {
    debugPrint('🔍 PARSING: "$text"');

    final lowerText = text.toLowerCase();
    bool isDebit = false;
    bool isCredit = false;

    // === CRITICAL LOGIC FOR GPAY & UPI APPS ===
    // GPay format: "[Name] paid you ₹X" = CREDIT (money IN)
    // GPay format: "You paid [Name] ₹X" = DEBIT (money OUT)

    // Check for "paid you" pattern (CREDIT - money received)
    if (lowerText.contains('paid you') ||
        lowerText.contains('sent you') ||
        lowerText.contains('transferred you') ||
        lowerText.contains('received from')) {
      isCredit = true;
      debugPrint('   💰 Pattern: Someone paid YOU → CREDIT');
    }
    // Check for "you paid" or "you sent" pattern (DEBIT - money sent)
    else if (lowerText.contains('you paid') ||
        lowerText.contains('you sent') ||
        lowerText.contains('you transferred') ||
        lowerText.contains('paid to') ||
        lowerText.contains('payment to')) {
      isDebit = true;
      debugPrint('   💸 Pattern: YOU paid someone → DEBIT');
    }
    // Bank SMS patterns (money debited FROM your account = DEBIT)
    else if (lowerText.contains('debited from your') ||
        lowerText.contains('withdrawn from your') ||
        lowerText.contains('deducted from your')) {
      isDebit = true;
      debugPrint('   💸 Pattern: Debited FROM your account → DEBIT');
    }
    // Bank SMS patterns (money credited TO your account = CREDIT)
    else if (lowerText.contains('credited to your') ||
        lowerText.contains('deposited to your') ||
        lowerText.contains('added to your')) {
      isCredit = true;
      debugPrint('   💰 Pattern: Credited TO your account → CREDIT');
    }
    // Refund/Cashback patterns (always CREDIT)
    else if (lowerText.contains('refund') ||
        lowerText.contains('cashback') ||
        lowerText.contains('reward')) {
      isCredit = true;
      debugPrint('   💰 Pattern: Refund/Cashback → CREDIT');
    }
    // Generic fallback patterns
    else {
      final hasDebitKeyword = _debitRegex.hasMatch(text);
      final hasCreditKeyword = _creditRegex.hasMatch(text);

      if (hasDebitKeyword && !hasCreditKeyword) {
        isDebit = true;
        debugPrint('   💸 Fallback: Debit keyword found → DEBIT');
      } else if (hasCreditKeyword && !hasDebitKeyword) {
        isCredit = true;
        debugPrint('   💰 Fallback: Credit keyword found → CREDIT');
      } else if (hasDebitKeyword && hasCreditKeyword) {
        // When both present, prefer debit (safer assumption for expenses)
        isDebit = true;
        debugPrint('   ⚠️ Both keywords found, defaulting to DEBIT');
      }
    }

    debugPrint('   Final decision - Debit: $isDebit, Credit: $isCredit');

    if (!isDebit && !isCredit) {
      debugPrint('   ❌ No transaction type detected');
      return null;
    }

    final amountMatch = _amountRegex.firstMatch(text);
    if (amountMatch == null) {
      debugPrint('   ❌ No amount found');
      return null;
    }

    final amountStr =
        (amountMatch.group(1) ??
                amountMatch.group(2) ??
                amountMatch.group(3) ??
                '')
            .replaceAll(',', '')
            .trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      debugPrint('   ❌ Invalid amount: $amountStr');
      return null;
    }

    final type = isDebit ? 'expense' : 'income';
    final category = _detectCategory(text, type);
    final icon = _getIconForCategory(category);

    debugPrint('   ✅ Parsed: ₹$amount as $type ($category)');

    return {
      'amount': amount,
      'type': type,
      'note':
          'Auto-detected from notification: ${text.length > 100 ? '${text.substring(0, 100)}...' : text}',
      'category': category,
      'icon': icon,
    };
  }

  static String _detectCategory(String text, String type) {
    final lowerText = text.toLowerCase();
    if (type == 'expense') {
      if (lowerText.contains('food') ||
          lowerText.contains('swiggy') ||
          lowerText.contains('zomato'))
        return 'Food';
      if (lowerText.contains('amazon') || lowerText.contains('flipkart'))
        return 'Shopping';
      if (lowerText.contains('uber') ||
          lowerText.contains('ola') ||
          lowerText.contains('fuel'))
        return 'Transport';
      if (lowerText.contains('bill') ||
          lowerText.contains('electricity') ||
          lowerText.contains('water'))
        return 'Bills';
      if (lowerText.contains('movie') || lowerText.contains('netflix'))
        return 'Entertainment';
      if (lowerText.contains('pharmacy') || lowerText.contains('hospital'))
        return 'Health';
      return 'Other';
    } else {
      if (lowerText.contains('salary')) return 'Salary';
      if (lowerText.contains('refund') || lowerText.contains('cashback'))
        return 'Refund';
      if (lowerText.contains('interest')) return 'Interest';
      return 'Other';
    }
  }

  static int _getIconForCategory(String category) {
    switch (category) {
      case 'Food':
        return 0xe56c;
      case 'Shopping':
        return 0xe8cc;
      case 'Transport':
        return 0xe531;
      case 'Bills':
        return 0xe8b0;
      case 'Entertainment':
        return 0xe404;
      case 'Health':
        return 0xe3f3;
      case 'Salary':
        return 0xe263;
      case 'Refund':
        return 0xe5d5;
      case 'Interest':
        return 0xe227;
      default:
        return 0xe8f4;
    }
  }

  static String _generateHash(String text, DateTime timestamp) {
    final combined = '$text${timestamp.millisecondsSinceEpoch}';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> testNotificationParsing(String testMessage) async {
    debugPrint('🧪 TEST PARSING: $testMessage');
    final result = _parseTransaction(testMessage, 'com.test.app');
    if (result != null) {
      debugPrint(
        '   ✅ Parsed: amount=${result['amount']} type=${result['type']}',
      );
    } else {
      debugPrint('   ❌ Not parsed');
    }
  }

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
