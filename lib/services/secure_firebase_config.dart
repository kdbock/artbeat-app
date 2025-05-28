import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat/firebase_options.dart';
import 'package:artbeat/utils/app_config.dart';

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

    final FirebaseOptions options = _getSecureOptions();
    debugPrint('Initializing new Firebase app "[DEFAULT]".');
    return Firebase.initializeApp(options: options);
  }

  /// Get secure Firebase options based on platform with API keys from env variables
  static FirebaseOptions _getSecureOptions() {
    // Get default options based on platform
    final defaultOptions = DefaultFirebaseOptions.currentPlatform;

    // Since we're in a private repository, we can use either env variables or default options
    try {
      // Check if we have API keys in the environment
      bool useEnvVars = false;
      try {
        final androidKey = AppConfig.firebaseAndroidApiKey;
        final iosKey = AppConfig.firebaseIosApiKey;
        useEnvVars = androidKey.isNotEmpty &&
            iosKey.isNotEmpty &&
            androidKey != 'placeholder_firebase_android_key' &&
            iosKey != 'placeholder_firebase_ios_key';
      } catch (_) {
        useEnvVars = false;
      }

      if (useEnvVars) {
        debugPrint('Using API keys from environment variables');
        if (defaultTargetPlatform == TargetPlatform.android) {
          return FirebaseOptions(
            apiKey: AppConfig.firebaseAndroidApiKey,
            appId: defaultOptions.appId,
            messagingSenderId: defaultOptions.messagingSenderId,
            projectId: defaultOptions.projectId,
            storageBucket: defaultOptions.storageBucket,
          );
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          return FirebaseOptions(
            apiKey: AppConfig.firebaseIosApiKey,
            appId: defaultOptions.appId,
            messagingSenderId: defaultOptions.messagingSenderId,
            projectId: defaultOptions.projectId,
            storageBucket: defaultOptions.storageBucket,
            iosBundleId: defaultOptions.iosBundleId,
          );
        }
      } else {
        // We're in a private repo, so using the original options is fine
        debugPrint('Using default Firebase options (original API keys)');
      }
    } catch (e) {
      // If we can't get API keys from environment variables, log a warning
      // and fall back to the default options (which still work in a private repo)
      debugPrint('⚠️ Warning: Using default Firebase options - $e');
    }

    return defaultOptions;
  }
}
