import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddy/services/auth_service.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/bottom_navbar_screen.dart';
import 'package:buddy/views/screens/onboarding/onborading_screen.dart';
import 'package:buddy/views/screens/onboarding/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        debugPrint(
          '🔍 AUTH WRAPPER: connectionState=${snapshot.connectionState}, '
          'hasData=${snapshot.hasData}, user=${snapshot.data?.uid}',
        );

        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ AUTH WRAPPER: Waiting for auth state...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in (including guest), show main app
        if (snapshot.hasData) {
          debugPrint('✅ AUTH WRAPPER: User authenticated, showing home');
          return const BottomNavbarScreen();
        }

        // No user - check if they've seen onboarding
        debugPrint('❌ AUTH WRAPPER: No user, checking onboarding status');
        return FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasSeenOnboarding = onboardingSnapshot.data ?? false;

            if (hasSeenOnboarding) {
              debugPrint('ℹ️ AUTH WRAPPER: Onboarding seen, showing login');
              return const LoginScreen();
            } else {
              debugPrint('ℹ️ AUTH WRAPPER: First time, showing onboarding');
              return const OnboardingScreen();
            }
          },
        );
      },
    );
  }
}