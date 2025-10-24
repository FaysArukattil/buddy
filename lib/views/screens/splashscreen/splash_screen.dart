// ignore_for_file: use_build_context_synchronously

import 'package:buddy/utils/colors.dart';
import 'package:buddy/views/screens/home_screen.dart';
import 'package:buddy/views/screens/onboarding/onborading_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checklogin();
  }

  Future<void> checklogin() async {
    final pref = await SharedPreferences.getInstance();
    Future.delayed(Duration(seconds: 3), () {
      final isloggedin = pref.getBool("is_logged_in") ?? false;
      if (isloggedin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/lottie/jsonlottie/Coinlottie.json',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20),
              // App Name
              Text(
                "Buddy",
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
