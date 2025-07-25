// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;

import 'config/maps_config.dart';
import 'app.dart';
import 'src/managers/app_lifecycle_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize app lifecycle manager
    AppLifecycleManager().initialize();
    if (kDebugMode) {
      print('✅ AppLifecycleManager initialized');
    }

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

    // Initialize image management service
    try {
      await ImageManagementService().initialize();
      if (kDebugMode) {
        print('✅ Image management service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Image management service initialization failed: $e');
      }
      // Don't fail the entire app for image service
    }

    // Initialize messaging notification service
    try {
      await messaging.NotificationService().initialize();
      if (kDebugMode) {
        print('✅ Messaging notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Messaging notification service initialization failed: $e');
      }
      // Don't fail the entire app for notification service
    }

    if (kDebugMode) {
      // Print Firebase status for debugging
      final status = SecureFirebaseConfig.getStatus();
      if (status['initialized'] == true) {
        print('✅ Firebase confirmed ready');
        print(
          '🔍 Firebase app names: ${Firebase.apps.map((app) => app.name).toList()}',
        );
      }
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Initialization failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is FileSystemException) {
        print('❌ File system error - Path: ${e.path}');
        print('❌ File system error - Message: ${e.message}');
      }
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
      // For other errors, show error dialog with more details
      String errorDetails = e.toString();
      if (e is FileSystemException) {
        errorDetails = 'File not found: ${e.path}\nMessage: ${e.message}';
      }

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
                  Text('Error: $errorDetails', textAlign: TextAlign.center),
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
