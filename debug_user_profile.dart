// Debug script to check and fix user profile issues
// Run this with: flutter run debug_user_profile.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DebugUserProfileApp());
}

class DebugUserProfileApp extends StatelessWidget {
  const DebugUserProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug User Profile',
      theme: ArtbeatTheme.lightTheme,
      home: const DebugUserProfileScreen(),
    );
  }
}

class DebugUserProfileScreen extends StatefulWidget {
  const DebugUserProfileScreen({super.key});

  @override
  State<DebugUserProfileScreen> createState() => _DebugUserProfileScreenState();
}

class _DebugUserProfileScreenState extends State<DebugUserProfileScreen> {
  String _debugInfo = 'Loading...';
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    final StringBuffer info = StringBuffer();

    try {
      // Check Firebase Auth user
      final authUser = FirebaseAuth.instance.currentUser;
      info.writeln('=== FIREBASE AUTH USER ===');
      if (authUser != null) {
        info.writeln('✅ User is authenticated');
        info.writeln('UID: ${authUser.uid}');
        info.writeln('Email: ${authUser.email}');
        info.writeln('Display Name: ${authUser.displayName}');
        info.writeln('Photo URL: ${authUser.photoURL}');
        info.writeln('Email Verified: ${authUser.emailVerified}');
      } else {
        info.writeln('❌ No authenticated user');
        setState(() {
          _debugInfo = info.toString();
        });
        return;
      }

      info.writeln('\n=== FIRESTORE USER DOCUMENT ===');

      // Check Firestore user document
      final userModel = await _userService.getUserById(authUser!.uid);
      if (userModel != null) {
        info.writeln('✅ User document exists in Firestore');
        info.writeln('ID: ${userModel.id}');
        info.writeln('Email: ${userModel.email}');
        info.writeln('Full Name: ${userModel.fullName}');
        info.writeln('Profile Image: ${userModel.profileImageUrl}');
        info.writeln('User Type: ${userModel.userType}');
        info.writeln('Created At: ${userModel.createdAt}');
      } else {
        info.writeln('❌ User document NOT found in Firestore');
        info.writeln('This is the problem! Creating it now...');

        // Try to create the user document
        try {
          await _userService.createNewUser(
            uid: authUser.uid,
            email: authUser.email ?? '',
            displayName: authUser.displayName ?? 'ARTbeat User',
          );

          // Check again
          final newUserModel = await _userService.getUserById(authUser.uid);
          if (newUserModel != null) {
            info.writeln('✅ User document created successfully!');
            info.writeln('New document ID: ${newUserModel.id}');
          } else {
            info.writeln('❌ Failed to create user document');
          }
        } catch (e) {
          info.writeln('❌ Error creating user document: $e');
        }
      }
    } catch (e) {
      info.writeln('❌ Error during debug: $e');
    }

    setState(() {
      _debugInfo = info.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkUserProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Profile Debug Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkUserProfile,
                child: const Text('Refresh Debug Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
