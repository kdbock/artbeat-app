import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat/services/auth_profile_service.dart';

class SplashScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      // Increased duration to 3 seconds
      // Check if user is already signed in
      checkAuthAndNavigate();
    });
  }

  // Check authentication status and navigate accordingly
  void checkAuthAndNavigate() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      if (currentUser != null) {
        // User is signed in, ensure they have a Firestore profile
        await AuthProfileService.migrateExistingUsers();

        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // No user signed in, navigate to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover, // This will cover the entire screen
          ),
        ),
      ),
    );
  }
}
