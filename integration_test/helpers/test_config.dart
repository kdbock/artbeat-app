import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class TestConfig {
  static const useEmulator = true;
  static String get host => Platform.isAndroid ? '10.0.2.2' : 'localhost';

  static Future<void> setupTestFirebase() async {
    try {
      // Wait for Firebase initialization
      await Firebase.initializeApp();

      if (useEmulator) {
        debugPrint('🔧 Setting up Firebase emulators...');
        await _connectToEmulators();
      }

      debugPrint('✅ Firebase test configuration complete');
    } catch (e) {
      debugPrint('❌ Error setting up Firebase test configuration: $e');
      rethrow;
    }
  }

  static Future<void> _connectToEmulators() async {
    try {
      // Configure Auth emulator
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);

      // Configure Firestore emulator
      FirebaseFirestore.instance.settings = Settings(
        host: '$host:8080',
        sslEnabled: false,
        persistenceEnabled: false,
      );

      // Configure Storage emulator
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);

      debugPrint('✅ Connected to Firebase emulators');
    } catch (e) {
      debugPrint('❌ Error connecting to emulators: $e');
      rethrow;
    }
  }

  static Future<void> cleanupTestData() async {
    try {
      debugPrint('🧹 Cleaning up test data...');

      // Clean up user and related data
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user's captures
        final captures = await FirebaseFirestore.instance
            .collection('captures')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in captures.docs) {
          await doc.reference.delete();
          // Delete associated storage file if it exists
          try {
            await FirebaseStorage.instance
                .ref('capture_images/${user.uid}/${doc.id}')
                .delete();
          } catch (e) {
            // Ignore storage errors during cleanup
            debugPrint('Storage cleanup warning: $e');
          }
        }

        // Delete user profile data
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
        } catch (e) {
          debugPrint('User profile cleanup warning: $e');
        }

        // Delete user account
        await user.delete();
      }

      // Sign out if needed
      await FirebaseAuth.instance.signOut();

      debugPrint('✅ Test data cleanup complete');
    } catch (e) {
      debugPrint('❌ Error during test cleanup: $e');
      // Don't rethrow cleanup errors as they shouldn't fail the test
    }
  }

  static Future<bool> verifyEmulatorConnection() async {
    try {
      if (!useEmulator) return true;

      // Verify Auth emulator
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password',
        );
      } catch (e) {
        // This should fail with an auth error, not a connection error
        if (e is! FirebaseAuthException) throw e;
      }

      // Verify Firestore emulator
      await FirebaseFirestore.instance
          .collection('_test_')
          .add({'test': true}).then((doc) => doc.delete());

      // Verify Storage emulator
      final testRef = FirebaseStorage.instance.ref('_test_/test.txt');
      await testRef.putString('test').then((_) => testRef.delete());

      debugPrint('✅ Emulator connection verified');
      return true;
    } catch (e) {
      debugPrint('❌ Emulator connection failed: $e');
      return false;
    }
  }
}
