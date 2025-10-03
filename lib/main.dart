// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'dart:io';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/maps_config.dart';
import 'in_app_purchase_setup.dart';
import 'src/managers/app_lifecycle_manager.dart';
import 'src/services/app_permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging system first
  AppLogger.initialize();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    CrashPreventionService.logCrashPrevention(
      operation: 'flutter_framework',
      errorType: details.exception.runtimeType.toString(),
      additionalInfo: details.exception.toString(),
    );

    AppLogger.error(
      'Flutter framework error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Handle errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashPreventionService.logCrashPrevention(
      operation: 'platform_error',
      errorType: error.runtimeType.toString(),
      additionalInfo: error.toString(),
    );

    AppLogger.error('Platform error: $error', error: error, stackTrace: stack);
    return true;
  };

  // Start performance monitoring
  PerformanceMonitor.startTimer('app_startup');

  try {
    // Initialize app lifecycle manager (non-blocking)
    AppLifecycleManager().initialize();

    // Initialize critical services in parallel
    final List<Future<void>> criticalInitializations = [
      ConfigService.instance.initialize(),
      MapsConfig.initialize(),
      EnvLoader().init(),
    ];

    // Reset Firebase state on hot restart in debug mode
    if (kDebugMode) {
      SecureFirebaseConfig.resetInitializationState();
    }

    // Wait for critical services
    await Future.wait(criticalInitializations);

    // Initialize Firebase (most critical)
    await SecureFirebaseConfig.ensureInitialized(
      teamId: 'H49R32NPY6',
      debug: kDebugMode,
    );

    // Initialize non-critical services in background after app starts
    _initializeNonCriticalServices();

    // Initialize app permissions
    _initializeAppPermissions();

    // End startup timing
    PerformanceMonitor.endTimer('app_startup');

    if (kDebugMode) {
      // Log Firebase status for debugging
      final status = SecureFirebaseConfig.getStatus();
      if (status['initialized'] == true) {
        AppLogger.firebase('✅ Firebase confirmed ready');
        AppLogger.firebase(
          '🔍 Firebase app names: ${Firebase.apps.map((app) => app.name).toList()}',
        );
      }
    }
  } on Object catch (e, stackTrace) {
    // Use crash prevention service for better error handling
    CrashPreventionService.logCrashPrevention(
      operation: 'app_initialization',
      errorType: e.runtimeType.toString(),
      additionalInfo: e.toString(),
    );

    if (kDebugMode) {
      AppLogger.error(
        '❌ Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      AppLogger.error('❌ Error type: ${e.runtimeType}');
      AppLogger.error('❌ Error details: ${e.toString()}');
      if (e is FileSystemException) {
        AppLogger.error('❌ File system error - Path: ${e.path}');
        AppLogger.error('❌ File system error - Message: ${e.message}');
      }
      // Print to console for immediate visibility
      print('❌❌❌ INITIALIZATION ERROR ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }

    // Handle duplicate app errors specifically
    if (e.toString().contains('duplicate-app') ||
        e.toString().contains('already exists')) {
      if (kDebugMode) {
        AppLogger.warning(
          '🔥 Duplicate app error caught in main, proceeding with app launch',
        );
      }
      // Continue with app launch since Firebase is already initialized
    } else {
      // For other errors, show user-friendly error message
      final userFriendlyMessage =
          CrashPreventionService.getUserFriendlyErrorMessage(e);
      String errorDetails = userFriendlyMessage;

      if (kDebugMode) {
        errorDetails += '\n\nDebug info: ${e.toString()}';
        if (e is FileSystemException) {
          errorDetails += '\nFile: ${e.path}\nMessage: ${e.message}';
        }
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
                  const ElevatedButton(onPressed: main, child: Text('Retry')),
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

/// Initialize non-critical services in background to avoid blocking app startup
void _initializeNonCriticalServices() {
  Future.delayed(const Duration(milliseconds: 100), () async {
    // Initialize image management service
    try {
      await ImageManagementService().initialize();
      if (kDebugMode) {
        AppLogger.info('✅ Image management service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Image management service initialization failed: $e');
      }
      // Don't fail the entire app for image service
    }

    // Initialize messaging notification service
    try {
      await messaging.NotificationService().initialize();
      if (kDebugMode) {
        AppLogger.info('✅ Messaging notification service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error(
          '❌ Messaging notification service initialization failed: $e',
        );
      }
      // Don't fail the entire app for notification service
    }

    // Initialize in-app purchase service
    try {
      await InAppPurchaseSetup().initialize();
      if (kDebugMode) {
        AppLogger.info('✅ In-app purchase service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ In-app purchase service initialization failed: $e');
      }
      // Don't fail the entire app for purchase service
    }
  });
}

/// Initialize app permissions in background to request essential permissions
void _initializeAppPermissions() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await AppPermissionService().initializePermissions();
      if (kDebugMode) {
        AppLogger.info('✅ App permissions service initialized');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ App permissions service initialization failed: $e');
      }
      // Don't fail the entire app for permission service
    }
  });
}
