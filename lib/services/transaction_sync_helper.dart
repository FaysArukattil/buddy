import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'db_helper.dart';

class TransactionSyncHelper {
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Sync transactions from native Android SharedPreferences to Flutter database
  static Future<void> syncNativeTransactions() async {
    debugPrint('🔄 SYNC: Starting transaction sync from native storage...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      int syncedCount = 0;
      int skippedCount = 0;

      for (final key in allKeys) {
        // Look for transaction keys from native code (format: txn_HASH)
        if (key.startsWith('txn_')) {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null) {
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;

              // Extract hash from key
              final hash = key.substring(4); // Remove 'txn_' prefix

              // Check if this transaction already exists in database
              final exists = await DatabaseHelper.instance
                  .isDuplicateTransaction(hash);

              if (!exists) {
                // Add to database
                final transactionMap = {
                  'amount': data['amount'] as double? ?? 0.0,
                  'type': data['type'] as String? ?? 'expense',
                  'date':
                      data['date'] as String? ??
                      DateTime.now().toIso8601String(),
                  'note':
                      data['note'] as String? ??
                      'Auto-detected from notification',
                  'category': data['category'] as String? ?? 'Other',
                  'icon': data['icon'] as int? ?? 0xe8f4,
                  'auto_detected': 1,
                  'notification_source': data['source'] as String? ?? 'unknown',
                  'notification_hash': hash,
                };

                final id = await DatabaseHelper.instance.insertTransaction(
                  transactionMap,
                );

                if (id > 0) {
                  syncedCount++;
                  debugPrint(
                    '   ✅ SYNC: Synced transaction: ₹${data['amount']} (${data['category']})',
                  );

                  // Optionally remove from SharedPreferences after successful sync
                  // await prefs.remove(key);
                } else {
                  skippedCount++;
                  debugPrint('   ⚠️ SYNC: Failed to sync: ₹${data['amount']}');
                }
              } else {
                skippedCount++;
                debugPrint(
                  '   ⏭️ SYNC: Already exists in DB: ₹${data['amount']}',
                );

                // Optionally clean up already synced transactions
                // await prefs.remove(key);
              }
            } catch (e) {
              debugPrint(
                '   ❌ SYNC: Error parsing transaction from key $key: $e',
              );
              skippedCount++;
            }
          }
        }
      }

      // Update last sync timestamp
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint(
        '✅ SYNC: Complete - $syncedCount synced, $skippedCount skipped',
      );

      if (syncedCount > 0) {
        debugPrint(
          '🎉 SYNC: Successfully added $syncedCount new transactions to database!',
        );
      }
    } catch (e) {
      debugPrint('❌ SYNC: Error during sync: $e');
    }
  }

  /// Get count of native transactions not yet synced
  static Future<int> getUnsyncedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      int count = 0;

      for (final key in allKeys) {
        if (key.startsWith('txn_')) {
          final hash = key.substring(4);
          final exists = await DatabaseHelper.instance.isDuplicateTransaction(
            hash,
          );
          if (!exists) {
            count++;
          }
        }
      }

      debugPrint('📊 SYNC: Found $count unsynced transactions');
      return count;
    } catch (e) {
      debugPrint('❌ SYNC: Error counting unsynced: $e');
      return 0;
    }
  }

  /// Get all pending transactions (awaiting user confirmation)
  static Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      final List<Map<String, dynamic>> pending = [];

      for (final key in allKeys) {
        if (key.startsWith('pending_')) {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null) {
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final hash = key.substring(8); // Remove 'pending_' prefix
              data['hash'] = hash;
              pending.add(data);
            } catch (e) {
              debugPrint('❌ SYNC: Error parsing pending transaction: $e');
            }
          }
        }
      }

      debugPrint('📋 SYNC: Found ${pending.length} pending transactions');
      return pending;
    } catch (e) {
      debugPrint('❌ SYNC: Error getting pending transactions: $e');
      return [];
    }
  }

  /// Clean up old synced transactions from native storage
  static Future<void> cleanupSyncedTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      int cleaned = 0;

      for (final key in allKeys) {
        if (key.startsWith('txn_')) {
          final hash = key.substring(4);
          final exists = await DatabaseHelper.instance.isDuplicateTransaction(
            hash,
          );

          // If it exists in database, remove from SharedPreferences
          if (exists) {
            await prefs.remove(key);
            cleaned++;
          }
        }
      }

      debugPrint(
        '🧹 SYNC: Cleaned up $cleaned synced transactions from native storage',
      );
    } catch (e) {
      debugPrint('❌ SYNC: Error during cleanup: $e');
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('❌ SYNC: Error getting last sync time: $e');
      return null;
    }
  }

  /// Full sync with cleanup
  static Future<int> performFullSync() async {
    debugPrint('🔄 SYNC: Starting full sync...');

    // First sync all transactions
    await syncNativeTransactions();

    // Get count of newly synced
    final unsyncedCount = await getUnsyncedCount();

    // Clean up synced transactions
    await cleanupSyncedTransactions();

    debugPrint('✅ SYNC: Full sync complete');
    return unsyncedCount;
  }
}
