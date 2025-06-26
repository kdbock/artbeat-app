// filepath: /Users/kristybock/updated_artbeat_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'app.dart';

Future<void> main() async {
  // CRITICAL: Initialize Flutter bindings before ANYTHING else
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Disable AppCheck globally in debug mode before any Firebase initialization
    SecureFirebaseConfig.disableAppCheckInDebug();

    // Initialize configuration service to load environment variables
    await ConfigService.instance.initialize();

    // Use development-friendly Firebase initialization in debug mode
    await SecureFirebaseConfig.initializeFirebaseForDevelopment();

    debugPrint('🚀 App initialization completed successfully');
  } catch (e) {
    debugPrint('❌ App initialization failed: $e');
    // Still try to run the app even if initialization fails partially
  }

  // Start the app immediately - diagnostics can run in background
  runApp(MyApp());

  // Run diagnostics in background (non-blocking)
  if (kDebugMode) {
    _runBackgroundDiagnostics();
  }
}

// Run diagnostics in the background without blocking app startup
void _runBackgroundDiagnostics() {
  Future.delayed(Duration.zero, () async {
    try {
      await SecureFirebaseConfig.runFirebaseDiagnostics();
    } catch (e) {
      debugPrint('🔍 Background diagnostics failed: $e');
    }
  });
}
