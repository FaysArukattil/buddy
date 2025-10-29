import 'package:flutter/material.dart';
import 'views/screens/onboarding/splashscreen/splash_screen.dart';
import 'utils/colors.dart';
import 'services/db_helper.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseHelper.instance.initdb();
  debugPrint('✅ MAIN: Database initialized');
  
  // Initialize notification service
  await _initializeNotificationService();
  
  runApp(const MyApp());
}

Future<void> _initializeNotificationService() async {
  try {
    // Just start listening if permission is already granted
    // Don't request permission automatically on app start
    await NotificationService.startListening();
    debugPrint('✅ MAIN: Notification service initialized');
  } catch (e) {
    debugPrint('⚠️ MAIN: Notification service not started (permission may not be granted): $e');
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
