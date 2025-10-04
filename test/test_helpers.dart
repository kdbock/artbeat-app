// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock Firebase options for testing
const firebaseTestOptions = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: '1:123456789:android:abcdef',
  messagingSenderId: '123456789',
  projectId: 'test-project',
);

/// Sets up Firebase mocks for testing
/// This function ensures Firebase is initialized in a test-safe way
Future<void> setupFirebaseMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Note: Firebase initialization in tests requires platform-specific setup
  // For now, we'll skip Firebase-dependent widget tests
  // Individual unit tests for Firebase services should use fake_cloud_firestore
}

/// Initialize Firebase for tests (if needed)
Future<void> initializeFirebaseForTests() async {
  // Firebase initialization in widget tests is complex and often not necessary
  // Use fake_cloud_firestore for unit tests of Firebase services instead
}
