// lib/main.dart
import 'package:flutter/material.dart';
import 'package:buddy/views/screens/onboarding/splashscreen/splash_screen.dart';
import 'package:buddy/utils/colors.dart';
import 'package:buddy/services/notification_service.dart';
import 'package:buddy/services/notification_helper.dart';
import 'package:buddy/services/db_helper.dart';

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

  // 2. Initialize Notification Helper (for showing notifications)
  try {
    await NotificationHelper.initialize();
    debugPrint('✅ APP: Notification helper initialized');
  } catch (e) {
    debugPrint('❌ APP: Notification helper initialization failed: $e');
  }

  // 3. Request notification permissions
  try {
    await NotificationHelper.requestNotificationPermission();
    debugPrint('✅ APP: Notification permissions requested');
  } catch (e) {
    debugPrint('⚠️ APP: Notification permission request failed: $e');
  }

  // 4. Check if auto-detection is enabled
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
