import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/services/search/search_history.dart';
import 'package:artbeat_core/src/services/search/search_cache.dart';

class TestConfig {
  static const bool useEmulator = true;
  static String get host => Platform.isAndroid ? '10.0.2.2' : 'localhost';

  // Get singleton instances
  static final SearchCache searchCache = SearchCache();
  static final SearchHistory searchHistory = SearchHistory();

  static Future<void> setupTestEnvironment() async {
    try {
      await Firebase.initializeApp();
      if (useEmulator) {
        await _setupEmulators();
      }
      await _setupPlatformSpecifics();
      await _setupSearchServices();
    } catch (e) {
      debugPrint('Error setting up test environment: $e');
      rethrow;
    }
  }

  static Future<void> _setupEmulators() async {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }

  static Future<void> _setupPlatformSpecifics() async {
    if (Platform.isIOS) {
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.deviceCheck,
      );
    } else if (Platform.isAndroid) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
    }
  }

  static Future<void> _setupSearchServices() async {
    await searchCache.clear();
    await searchHistory.clearHistory();

    // Initialize with test data
    await FirebaseFirestore.instance.collection('artwork').add({
      'title': 'Test Artwork',
      'artist': 'Test Artist',
      'medium': 'Digital',
      'createdAt': DateTime.now(),
    });
  }

  static Future<void> cleanupTestEnvironment() async {
    await searchCache.clear();
    await searchHistory.clearHistory();
    if (useEmulator) {
      await _cleanupEmulatorData();
    }
  }

  static Future<void> _cleanupEmulatorData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      // Clear test collections
      await Future.wait([
        _clearCollection(firestore.collection('artwork')),
        _clearCollection(firestore.collection('artists')),
        _clearCollection(firestore.collection('search_history')),
      ]);

      // Clear test storage
      await _clearTestStorage(storage);
    } catch (e) {
      debugPrint('Error cleaning up test environment: $e');
      rethrow;
    }
  }

  static Future<void> _clearCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> _clearTestStorage(FirebaseStorage storage) async {
    try {
      final testRef = storage.ref().child('test');
      await testRef.delete();
    } catch (e) {
      debugPrint('Storage cleanup warning: $e');
    }
  }

  static Future<void> performTestLogin(WidgetTester tester) async {
    const testEmail = 'test@example.com';
    const testPassword = 'Test@123';

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
    } catch (e) {
      // User might already exist
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
    }
  }
}
