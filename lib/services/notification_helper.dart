// lib/services/notification_helper.dart
// ignore: depend_on_referenced_packages
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'db_helper.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('✅ NOTIFICATION_HELPER: Initialized');
  }

  /// Request notification permission (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    debugPrint('🔔 Requesting notification permission...');

    final status = await Permission.notification.status;

    if (status.isGranted) {
      debugPrint('✅ Notification permission already granted');
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        debugPrint('✅ Notification permission granted');
        return true;
      } else {
        debugPrint('❌ Notification permission denied');
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      debugPrint(
        '⚠️ Notification permission permanently denied - opening settings',
      );
      await openAppSettings();
      return false;
    }

    return false;
  }

  static void _onNotificationTapped(NotificationResponse response) async {
    debugPrint(
      '📱 Notification tapped: ${response.payload}, action: ${response.actionId}',
    );

    if (response.payload == null) return;

    final hash = response.payload!;

    try {
      // Get pending transaction
      final pendingData = await DatabaseHelper.instance.getPendingTransaction(
        hash,
      );
      if (pendingData == null) {
        debugPrint('⚠️ No pending transaction found for hash: $hash');
        return;
      }

      if (response.actionId == 'yes' || response.actionId == null) {
        // User confirmed (either tapped "Yes" or notification body)
        debugPrint('✅ User confirmed duplicate transaction');
        final id = await DatabaseHelper.instance.insertAutoTransaction(
          pendingData,
        );
        if (id > 0) {
          debugPrint('✅ Duplicate transaction added (id=$id)');
          await NotificationHelper.showTransactionAdded(
            amount: pendingData['amount'] as double,
            type: pendingData['type'] as String,
            category: pendingData['category'] as String,
          );
        }
      } else if (response.actionId == 'no') {
        // User rejected
        debugPrint('❌ User rejected duplicate transaction');
      }

      // Clean up pending transaction
      await DatabaseHelper.instance.removePendingTransaction(hash);
    } catch (e) {
      debugPrint('❌ Error handling notification action: $e');
    }
  }

  /// Show duplicate confirmation notification with Yes/No buttons
  static Future<void> showDuplicateConfirmation({
    required String transactionHash,
    required double amount,
    required String type,
    required String category,
    int similarCount = 1,
  }) async {
    await initialize();

    const channelId = 'duplicate_confirmations';
    const channelName = 'Transaction Confirmations';
    const channelDesc = 'Notifications to confirm duplicate transactions';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'yes',
          '✅ Yes, Add',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'no',
          '❌ No, Ignore',
          showsUserInterface: false,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final typeIcon = type == 'expense' ? '💸' : '💰';
    final title = 'Possible Duplicate Transaction?';
    final body =
        '$typeIcon ₹$amount ($category)\n$similarCount similar transaction(s) found in last 24h.\nWould you like to add this transaction?';

    await _notifications.show(
      transactionHash.hashCode,
      title,
      body,
      notificationDetails,
      payload: transactionHash,
    );

    debugPrint(
      '🔔 Shown duplicate confirmation for ₹$amount (found $similarCount similar)',
    );
  }

  /// Show transaction added notification
  static Future<void> showTransactionAdded({
    required double amount,
    required String type,
    required String category,
  }) async {
    await initialize();

    const channelId = 'transaction_added';
    const channelName = 'Transaction Added';
    const channelDesc = 'Notifications when transactions are auto-detected';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final typeIcon = type == 'expense' ? '💸' : '💰';
    final title = 'Transaction Added';
    final body = '$typeIcon ₹$amount ($category)';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
    );
  }

  /// Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
