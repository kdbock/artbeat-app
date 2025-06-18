import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/firebase_options.dart' as fb_opts;

/// Provides secure initialization for Firebase with platform-specific handling
class SecureFirebaseConfig {
  const SecureFirebaseConfig._();

  static bool _initialized = false;

  /// Initializes Firebase with proper options and platform-specific configuration
  static Future<FirebaseApp> initializeFirebase() async {
    if (_initialized && Firebase.apps.isNotEmpty) {
      return Firebase.app();
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        return Firebase.app();
      }

      // Initialize Firebase first
      final app = await Firebase.initializeApp(
        options: fb_opts.DefaultFirebaseOptions.currentPlatform,
      );

      // Then initialize App Check with platform-specific providers
      await FirebaseAppCheck.instance.activate(
        // Use DeviceCheck provider for iOS, Play Integrity for Android
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );

      _initialized = true;
      return app;
    } on FirebaseException catch (e) {
      debugPrint('Firebase initialization failed: $e');
      if (e.code == 'duplicate-app') {
        _initialized = true;
        return Firebase.app();
      }
      rethrow;
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Utility method to check if running in debug mode
  static bool isDebugMode() {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }
}
