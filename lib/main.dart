// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'config/maps_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize config service first
    await ConfigService.instance.initialize();
    if (kDebugMode) {
      print('✅ ConfigService initialized');
    }

    // Initialize Maps configuration
    await MapsConfig.initialize();
    if (kDebugMode) {
      print('✅ Maps configuration initialized');
    }

    // Reset Firebase state on hot restart in debug mode
    if (kDebugMode) {
      SecureFirebaseConfig.resetInitializationState();
    }

    // Ensure Firebase is properly initialized
    if (kDebugMode) {
      print('🔥 Ensuring Firebase initialization...');
    }

    await SecureFirebaseConfig.ensureInitialized(
      teamId: 'H49R32NPY6',
      debug: kDebugMode,
    );

    if (kDebugMode) {
      print('✅ Firebase initialization completed successfully');
    }

    if (kDebugMode) {
      // Print Firebase status for debugging
      final status = SecureFirebaseConfig.getStatus();
      print('🔍 Firebase Status: $status');
      print('🔍 Firebase apps count: ${Firebase.apps.length}');
      if (Firebase.apps.isNotEmpty) {
        print(
          '🔍 Firebase app names: ${Firebase.apps.map((app) => app.name).toList()}',
        );
      }
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Firebase initialization failed: $e');
      print('❌ Stack trace: $stackTrace');
    }

    // Handle duplicate app errors specifically
    if (e.toString().contains('duplicate-app') ||
        e.toString().contains('already exists')) {
      if (kDebugMode) {
        print(
          '🔥 Duplicate app error caught in main, proceeding with app launch',
        );
      }
      // Continue with app launch since Firebase is already initialized
    } else {
      // For other errors, show error dialog
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Error: ${e.toString()}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => main(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }
  }

  runApp(MyApp());
}
