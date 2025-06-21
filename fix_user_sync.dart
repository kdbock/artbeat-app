// Fix User Sync - Run this to sync authenticated users with Firestore
// Usage: flutter run fix_user_sync.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FixUserSyncApp());
}

class FixUserSyncApp extends StatelessWidget {
  const FixUserSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fix User Sync',
      theme: ArtbeatTheme.lightTheme,
      home: const FixUserSyncScreen(),
    );
  }
}

class FixUserSyncScreen extends StatefulWidget {
  const FixUserSyncScreen({super.key});

  @override
  State<FixUserSyncScreen> createState() => _FixUserSyncScreenState();
}

class _FixUserSyncScreenState extends State<FixUserSyncScreen> {
  String _status = 'Ready to fix user sync...';
  bool _isWorking = false;
  final UserService _userService = UserService();

  Future<void> _fixUserSync() async {
    setState(() {
      _isWorking = true;
      _status = 'Starting user sync fix...\n';
    });

    try {
      // Check current authenticated user
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        setState(() {
          _status += '❌ No authenticated user found. Please login first.\n';
          _isWorking = false;
        });
        return;
      }

      setState(() {
        _status += '✅ Found authenticated user: ${authUser.uid}\n';
        _status += '📧 Email: ${authUser.email}\n';
        _status += '👤 Display Name: ${authUser.displayName}\n';
      });

      // Check if user document exists in Firestore
      final existingUser = await _userService.getUserById(authUser.uid);
      if (existingUser != null) {
        setState(() {
          _status += '✅ User document already exists in Firestore\n';
          _status += '📄 Document ID: ${existingUser.id}\n';
          _status += '👤 Full Name: ${existingUser.fullName}\n';
          _status += '📧 Email: ${existingUser.email}\n';
          _status += '🎯 User Type: ${existingUser.userType}\n';
          _status += '\n✅ No sync needed - user is already properly synced!\n';
          _isWorking = false;
        });
        return;
      }

      // User document doesn't exist - create it
      setState(() {
        _status += '⚠️ User document NOT found in Firestore\n';
        _status += '🔧 Creating user document...\n';
      });

      // Create the user document
      await _userService.createNewUser(
        uid: authUser.uid,
        email: authUser.email ?? '',
        displayName: authUser.displayName ?? 'ARTbeat User',
      );

      setState(() {
        _status += '✅ User document creation completed\n';
      });

      // Verify creation
      final newUser = await _userService.getUserById(authUser.uid);
      if (newUser != null) {
        setState(() {
          _status += '🎉 SUCCESS! User document created and verified\n';
          _status += '📄 New Document ID: ${newUser.id}\n';
          _status += '👤 Full Name: ${newUser.fullName}\n';
          _status += '📧 Email: ${newUser.email}\n';
          _status += '🎯 User Type: ${newUser.userType}\n';
          _status += '\n✅ User sync is now complete!\n';
          _status += '\n🎯 You can now use "View Profile" successfully!\n';
        });
      } else {
        setState(() {
          _status += '❌ FAILED: User document still not found after creation\n';
          _status +=
              '🔍 This indicates a Firestore permissions or configuration issue\n';
        });
      }
    } catch (e) {
      setState(() {
        _status += '❌ ERROR during sync: $e\n';
        _status += '🔍 Check Firestore rules and permissions\n';
      });
    }

    setState(() {
      _isWorking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix User Sync'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Sync Fixer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This tool will sync your authenticated user with the Firestore database.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Status display
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
                    _status,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isWorking ? null : _fixUserSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isWorking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Working...'),
                        ],
                      )
                    : const Text(
                        'Fix User Sync Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
