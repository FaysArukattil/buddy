// lib/main.dart
import 'package:flutter/material.dart';
import 'package:buddy/views/screens/onboarding/splashscreen/splash_screen.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/services/notification_service.dart';
import 'package:buddy/services/notification_helper.dart';
import 'package:buddy/services/db_helper.dart';
import 'package:buddy/services/transaction_sync_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 APP: Starting initialization...');

  // 1. Initialize Database
  try {
    await DatabaseHelper.instance.initdb();
    debugPrint('✅ APP: Database initialized');
  } catch (e) {
    debugPrint('❌ APP: Database initialization failed: $e');
  }

  // 2. Sync native transactions to Flutter database
  try {
    await TransactionSyncHelper.syncNativeTransactions();
    final unsyncedCount = await TransactionSyncHelper.getUnsyncedCount();
    final pendingCount =
        (await TransactionSyncHelper.getPendingTransactions()).length;
    debugPrint(
      '✅ APP: Transaction sync complete - $unsyncedCount unsynced, $pendingCount pending',
    );
  } catch (e) {
    debugPrint('⚠️ APP: Transaction sync failed: $e');
  }

  // 3. Initialize Notification Helper (for showing notifications)
  try {
    await NotificationHelper.initialize();
    debugPrint('✅ APP: Notification helper initialized');
  } catch (e) {
    debugPrint('❌ APP: Notification helper initialization failed: $e');
  }

  // 4. Request notification permissions
  try {
    await NotificationHelper.requestNotificationPermission();
    debugPrint('✅ APP: Notification permissions requested');
  } catch (e) {
    debugPrint('⚠️ APP: Notification permission request failed: $e');
  }

  // 5. Check if auto-detection is enabled
  try {
    final isAutoDetectionEnabled =
        await NotificationService.isAutoDetectionEnabled();
    debugPrint('ℹ️ APP: Auto-detection enabled: $isAutoDetectionEnabled');

    if (isAutoDetectionEnabled) {
      // Check if we have notification listener access
      final hasAccess = await NotificationService.requestNotificationAccess();

      if (hasAccess) {
        // Start listening for notifications
        await NotificationService.startListening();
        debugPrint('✅ APP: Notification listener started');
      } else {
        debugPrint('⚠️ APP: Notification listener access not granted');
      }
    } else {
      debugPrint('ℹ️ APP: Auto-detection disabled, not starting listener');
    }
  } catch (e) {
    debugPrint('⚠️ APP: Failed to start notification listener: $e');
  }

  debugPrint('🎉 APP: Initialization complete\n');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('📱 APP: Observer attached');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('📱 APP: Observer removed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('📱 APP: Lifecycle state changed to: $state');

    // Sync when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 APP: App resumed - syncing transactions...');
      _syncTransactions();
    }
  }

  Future<void> _syncTransactions() async {
    try {
      await TransactionSyncHelper.syncNativeTransactions();
      final unsyncedCount = await TransactionSyncHelper.getUnsyncedCount();

      if (unsyncedCount == 0) {
        debugPrint('✅ APP: All transactions synced successfully');
      } else {
        debugPrint('⚠️ APP: Still have $unsyncedCount unsynced transactions');
      }
    } catch (e) {
      debugPrint('❌ APP: Error during sync: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
