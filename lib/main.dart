// lib/main.dart
import 'package:flutter/material.dart';
import 'package:buddy/views/screens/onboarding/splashscreen/splash_screen.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/services/notification_service.dart';
import 'package:buddy/services/db_helper.dart';
import 'package:buddy/repositories/transaction_repository.dart';
import 'package:buddy/models/transaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure DB initialized
  await DatabaseHelper.instance.initdb();

  // Initialize notification service and pass a callback
  await _initializeNotificationService();

  runApp(const MyApp());
}

Future<void> _initializeNotificationService() async {
  try {
    debugPrint('🚀 MAIN: Initializing notification service...');

    final repo = TransactionRepository();

    // Start listening and provide callback that saves to repository
    await NotificationService.startListening((transactionMap, hash) async {
      try {
        debugPrint('💾 MAIN: Received transaction from notification service');

        // Convert map -> TransactionModel
        final txModel = TransactionModel(
          amount: (transactionMap['amount'] as num).toDouble(),
          type: transactionMap['type'] as String,
          date: DateTime.parse(transactionMap['date'] as String),
          note: transactionMap['note'] as String?,
          category: transactionMap['category'] as String,
          icon: (transactionMap['icon'] as num).toInt(),
          autoDetected:
              (transactionMap['auto_detected'] == 1) ||
              (transactionMap['auto_detected'] == true),
          notificationSource: transactionMap['notification_source'] as String?,
          notificationHash: hash,
        );

        // Save via repository
        final id = await repo.addAutoDetected(
          txModel,
          notificationSource: txModel.notificationSource ?? 'unknown',
          notificationHash: hash,
        );

        if (id > 0) {
          debugPrint('✅ MAIN: Transaction saved successfully (id=$id)');
        } else {
          debugPrint('⚠️ MAIN: Transaction not saved (probably duplicate)');
        }
      } catch (e) {
        debugPrint('❌ MAIN: Error saving transaction: $e');
      }
    });

    debugPrint('✅ MAIN: Notification service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ MAIN: Notification service failed to start: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
