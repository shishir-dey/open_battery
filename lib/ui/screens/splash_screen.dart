/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/ui/screens/splash_screen.dart
 * Description: Splash screen displayed on app launch with a fade-in animation before navigating to the scan screen.
 * Author: Shishir Dey
 * License: MIT
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'scan_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate quickly after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const ScanScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current brightness from app theme (not system) to avoid flash on startup
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      // Use system theme colors
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? CupertinoColors.black.withValues(alpha: 0.5)
                      : CupertinoColors.systemGrey4.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/icon.png', fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
