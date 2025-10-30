// Copyright (c) 2025 ArtBeat. All rights reserved.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase test configuration for widget tests
class FirebaseTestSetup {
  static late FakeFirebaseFirestore _fakeFirestore;
  static late MockFirebaseAuth _mockAuth;
  static bool _isInitialized = false;

  /// Initialize Firebase for testing environment
  static Future<void> initializeFirebaseForTesting() async {
    if (_isInitialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize fake Firebase services first
    _fakeFirestore = FakeFirebaseFirestore();
    _mockAuth = MockFirebaseAuth();

    try {
      // Only initialize if not already initialized
      if (Firebase.apps.isEmpty) {
        // Use setupFirebaseAuthMocks() to properly mock Firebase in tests
        // Note: This should be called before Firebase.initializeApp()

        // Set up Firebase test options
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: '1:123456789:android:test-app-id',
            messagingSenderId: '123456789',
            projectId: 'test-project-id',
            authDomain: 'test-project.firebaseapp.com',
            storageBucket: 'test-project.appspot.com',
          ),
        );
      }
    } on Exception catch (e) {
      // If Firebase initialization fails in test environment, continue with mocks
      // Suppress output in test environment
      debugPrint('Firebase initialization warning in test: $e');
    }

    _isInitialized = true;
  }

  /// Get mock FirebaseAuth instance for testing
  static MockFirebaseAuth get mockAuth {
    if (!_isInitialized) {
      throw StateError(
        'Firebase not initialized for testing. Call initializeFirebaseForTesting() first.',
      );
    }
    return _mockAuth;
  }

  /// Get fake Firestore instance for testing
  static FakeFirebaseFirestore get fakeFirestore {
    if (!_isInitialized) {
      throw StateError(
        'Firebase not initialized for testing. Call initializeFirebaseForTesting() first.',
      );
    }
    return _fakeFirestore;
  }

  /// Create a mock user for testing
  static MockUser createMockUser({
    String uid = 'test-uid',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isEmailVerified = true,
  }) => MockUser(
    uid: uid,
    email: email,
    displayName: displayName,
    isEmailVerified: isEmailVerified,
  );

  /// Set up authenticated user for testing
  static Future<void> signInTestUser({
    String uid = 'test-uid',
    String email = 'test@example.com',
    String displayName = 'Test User',
  }) async {
    final user = createMockUser(
      uid: uid,
      email: email,
      displayName: displayName,
    );
    // Set the mock auth to return this user
    _mockAuth = MockFirebaseAuth(mockUser: user, signedIn: true);
  }

  /// Sign out test user
  static Future<void> signOutTestUser() async {
    await _mockAuth.signOut();
  }

  /// Reset Firebase test state
  static Future<void> reset() async {
    if (_isInitialized) {
      await _mockAuth.signOut();
      _fakeFirestore = FakeFirebaseFirestore();
      _mockAuth = MockFirebaseAuth();
    }
  }

  /// Clean up after tests
  static Future<void> cleanup() async {
    if (_isInitialized) {
      await reset();
      _isInitialized = false;
    }
  }
}

/// Test helper mixin for Firebase-dependent widgets
mixin FirebaseTestMixin {
  /// Set up Firebase before each test
  Future<void> setUpFirebase() async {
    await FirebaseTestSetup.initializeFirebaseForTesting();
  }

  /// Clean up Firebase after each test
  Future<void> tearDownFirebase() async {
    await FirebaseTestSetup.reset();
  }
}
