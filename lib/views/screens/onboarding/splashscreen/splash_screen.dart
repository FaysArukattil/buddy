// ignore_for_file: use_build_context_synchronously

import 'package:buddy/utils/colors.dart';
import 'package:buddy/views/screens/bottomnavbarscreen/bottom_navbar_screen.dart';
import 'package:buddy/views/screens/onboarding/onborading_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    // Ensure the gradient is painted before animation starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isReady = true);
    });

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 100));
        await navigateToNext();
      }
    });
  }

  Future<void> navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool("is_logged_in") ?? false;

    if (!mounted) return;

    final nextPage = isLoggedIn
        ? const BottomNavbarScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => nextPage,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubicEmphasized,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-paint gradient to avoid initial white flash
    return Container(
      color: AppColors.primaryGradient.colors.first,
      child: AnimatedOpacity(
        opacity: _isReady ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Scaffold(
          backgroundColor: Colors.transparent, // Prevents white background
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/jsonlottie/Coinlottie.json',
                    controller: _controller,
                    width: 230,
                    height: 230,
                    fit: BoxFit.contain,
                    animate: false,
                    frameRate: FrameRate.max,
                    onLoaded: (composition) async {
                      // Short warm-up to ensure no choppy start
                      await Future.delayed(const Duration(milliseconds: 50));
                      _controller
                        ..duration =
                            composition.duration *
                            0.8 // Slightly faster
                        ..forward();
                    },
                  ),
                  const SizedBox(height: 22),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
                    ),
                    child: const Text(
                      "Buddy",
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
