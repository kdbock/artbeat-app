import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_profile/artbeat_profile.dart' show CreateProfileScreen;
import '../constants/routes.dart';

/// Bridge screen that redirects to the full profile creation screen
/// This screen exists to satisfy the auth flow routing but delegates
/// to the comprehensive profile creation screen in artbeat_profile
class ProfileCreateScreen extends StatelessWidget {
  const ProfileCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AuthRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Redirect to the comprehensive profile creation screen
    return CreateProfileScreen(
      userId: user.uid,
      onProfileCreated: () {
        // Navigate to dashboard after profile creation
        Navigator.pushReplacementNamed(context, AuthRoutes.dashboard);
      },
    );
  }
}
