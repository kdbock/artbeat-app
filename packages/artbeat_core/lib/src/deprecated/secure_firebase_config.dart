import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:artbeat_core/firebase_options.dart' as fb_opts;

/// Class for managing secure Firebase configuration
class SecureFirebaseConfig {
  /// Initialize Firebase with secure options
  static Future<FirebaseApp> initializeFirebase() async {
    // Check if Firebase app already exists
    if (Firebase.apps.isNotEmpty) {
      debugPrint(
          'Firebase app "[DEFAULT]" already initialized. Returning existing instance.');
      return Firebase.app(); // Return existing app
    }

    // Apply platform-specific fixes before initialization
    if (Platform.isIOS) {
      // On iOS, ensure we have proper initialization
      debugPrint(
          '🍎 iOS platform detected, applying iOS-specific configuration');

      // For iOS, set the default platform locale to force proper collection initialization
      WidgetsFlutterBinding.ensureInitialized();
    }

    final FirebaseOptions options = _getSecureOptions();
    debugPrint(
        'Initializing new Firebase app "[DEFAULT]" with platform-specific options.');

    try {
      return await Firebase.initializeApp(options: options);
    } catch (e) {
      debugPrint('❌ Firebase initialization error with specific options: $e');
      // Check if an app got registered despite the error, or if it's a different issue.
      if (Firebase.apps.isEmpty) {
        debugPrint(
            '⚠️ Attempting to re-initialize with default options as no app was registered...');
        try {
          return await Firebase.initializeApp(); // Fallback to default options
        } catch (e2) {
          debugPrint(
              '❌ Firebase initialization failed with default options as well: $e2');
          rethrow; // Re-throw the error from the fallback initialization
        }
      } else {
        // An app (likely "[DEFAULT]") is already registered, possibly by the failed attempt.
        debugPrint(
            '⚠️ An app is already registered despite the error. Returning existing instance. Original error: $e');
        return Firebase.app(); // Return the existing app.
      }
    }
  }

  /// Get secure Firebase options based on platform
  static FirebaseOptions _getSecureOptions() {
    // Get default options based on platform - always use these
    final defaultOptions = fb_opts.DefaultFirebaseOptions.currentPlatform;

    if (Platform.isIOS) {
      debugPrint(
          'Using iOS Firebase options with BUNDLE_ID: com.wordnerd.artbeat');
    } else if (Platform.isAndroid) {
      debugPrint('Using Android Firebase options');
    }

    debugPrint(
        'Firebase options from firebase_options.dart loaded successfully');
    return defaultOptions;
  }
}
