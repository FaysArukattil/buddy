// lib/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';

typedef OnTransactionDetected =
    Future<void> Function(Map<String, Object?> transactionMap, String hash);

class NotificationService {
  // METHOD CHANNEL NAME MATCHES MainActivity.kt
  static const MethodChannel _nativeChannel = MethodChannel(
    'notification_channel',
  );

  static StreamSubscription? _notificationSubscription;
  static bool _isListening = false;

  // Regex patterns
  static final RegExp _debitRegex = RegExp(
    r'\b(debited|spent|purchase|paid|withdrawn|debit|payment|sent|transferred)\b',
    caseSensitive: false,
  );

  static final RegExp _creditRegex = RegExp(
    r'\b(credited|received|deposit|income|credit|refund|cashback)\b',
    caseSensitive: false,
  );

  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?\s?|INR\s?|₹\s?)([0-9,]+\.?[0-9]*)|([0-9,]+\.?[0-9]*)\s?(?:Rs\.?|INR|₹)|(?:amount|amt|sum)[\s:]*(?:Rs\.?\s?|INR\s?|₹\s?)?([0-9,]+\.?[0-9]*)',
    caseSensitive: false,
  );

  static final List<String> _financialApps = [
    'com.google.android.apps.messaging',
    'com.android.messaging',
    'com.samsung.android.messaging',
    'com.android.mms',
    'com.textra',
    'com.phonepe.app',
    'com.google.android.apps.nbu.paisa.user',
    'in.org.npci.upiapp',
    'net.one97.paytm',
    'com.amazon.mShop.android.shopping',
    'in.amazon.mShop.android.shopping',
    'com.mobikwik_new',
    'com.freecharge.android',
    'com.sbi.SBIFreedomPlus',
    'com.icicibank.mobile.iciciappathon',
    'com.hdfcbank.payzapp',
    'com.axisbank.mobile',
    'com.kotakbank.mobile',
    'com.indusind.mobile',
    'com.whatsapp',
    'com.truecaller',
  ];

  /// Request notification listener permission
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

  /// Check if auto-detection is enabled
  static Future<bool> isAutoDetectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_detect_transactions') ?? true;
  }

  /// Enable / disable auto-detection
  static Future<void> setAutoDetectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_detect_transactions', enabled);
    if (enabled && !_isListening) {
      await startListening();
    } else if (!enabled && _isListening) {
      await stopListening();
    }
  }

  /// Start listening - accepts optional callback:
  /// onTransactionDetected(Map<String,Object?> transactionMap, String hash)
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

    // 1) Listen to the notification_listener_service stream (if available)
    try {
      _notificationSubscription = NotificationListenerService
          .notificationsStream
          .listen(
            (event) async {
              try {
                final result = await _handleNotification(event);
                // If result is not null, optionally propagate to callback
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

    // 2) Also listen to native MethodChannel calls from MainActivity (fallback)
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

  /// Stop listening
  static Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;
      // Remove method handler (optional)
      _nativeChannel.setMethodCallHandler(null);
      _isListening = false;
      debugPrint('🛑 NOTIFICATION: Listener stopped');
    } catch (e) {
      debugPrint('❌ NOTIFICATION: Error stopping listener: $e');
    }
  }

  /// Returns { 'transactionMap': Map, 'hash': String } when inserted, else null
  static Future<Map<String, Object?>?> _handleNotification(
    dynamic event,
  ) async {
    try {
      // Support both plugin event objects and plain Maps from MethodChannel
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
      final isDuplicate = await DatabaseHelper.instance.isDuplicateTransaction(
        hash,
      );
      if (isDuplicate) {
        debugPrint('   ⚠️ Duplicate detected (hash) - skipping');
        return null;
      }

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

      final id = await DatabaseHelper.instance.insertAutoTransaction(
        transactionMap,
      );
      if (id > 0) {
        debugPrint('✅ NOTIFICATION: Auto-transaction inserted (id=$id)');
        _showTransactionAddedFeedback(txnData);
        return {'transactionMap': transactionMap, 'hash': hash};
      } else {
        debugPrint(
          '⚠️ NOTIFICATION: Insert returned id=$id (possibly duplicate or error)',
        );
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

  static Map<String, dynamic>? _parseTransaction(String text, String source) {
    final isDebit = _debitRegex.hasMatch(text);
    final isCredit = _creditRegex.hasMatch(text);
    if (!isDebit && !isCredit) return null;

    final amountMatch = _amountRegex.firstMatch(text);
    if (amountMatch == null) return null;

    final amountStr =
        (amountMatch.group(1) ??
                amountMatch.group(2) ??
                amountMatch.group(3) ??
                '')
            .replaceAll(',', '')
            .trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    final type = isDebit ? 'expense' : 'income';
    final category = _detectCategory(text, type);
    final icon = _getIconForCategory(category);

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

  static void _showTransactionAddedFeedback(Map<String, dynamic> data) {
    debugPrint(
      '💬 FEEDBACK: Transaction added - ${data['type']} ₹${data['amount']}',
    );
  }

  /// Optional debug helper - test parsing locally
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

  /// Get debug info
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
