// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize config service first
    await ConfigService.instance.initialize();
    if (kDebugMode) {
      print('✅ ConfigService initialized');
    }

    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        print('🔥 Starting Firebase initialization...');
      }

      // IMPORTANT: Configure App Check BEFORE Firebase initialization
      await SecureFirebaseConfig.configureAppCheck(
        teamId: 'H49R32NPY6',
        debug: kDebugMode,
      );

      // Initialize Firebase after App Check is configured
      await SecureFirebaseConfig.initializeFirebase();

      if (kDebugMode) {
        print('✅ Firebase initialization completed successfully');
      }
    } else {
      if (kDebugMode) {
        print(
          '🔥 Firebase already initialized, skipping SecureFirebaseConfig initialization',
        );
      }
    }

    if (kDebugMode) {
      // Print Firebase status for debugging
      final status = SecureFirebaseConfig.getStatus();
      print('🔍 Firebase Status: $status');
      print('🔍 Firebase apps count: ${Firebase.apps.length}');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Firebase initialization failed: $e');
      print('❌ Stack trace: $stackTrace');
    } else {
      rethrow;
    }
  }

  runApp(MyApp());
}
