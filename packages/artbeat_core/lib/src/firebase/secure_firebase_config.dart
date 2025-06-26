import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:artbeat_core/firebase_options.dart' as fb_opts;

/// Provides secure initialization for Firebase with platform-specific handling
class SecureFirebaseConfig {
  const SecureFirebaseConfig._();

  static bool _initialized = false;
  static bool _appCheckInitialized = false;

  /// Initializes Firebase with proper options and platform-specific configuration
  static Future<FirebaseApp> initializeFirebase() async {
    if (_initialized) {
      return Firebase.app();
    }

    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('🔥 Firebase already initialized, using existing app');
        _initialized = true;
        return Firebase.app();
      }

      debugPrint('🔥 Initializing Firebase...');

      // Initialize Firebase first
      final app = await Firebase.initializeApp(
        options: fb_opts.DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('🔥 Firebase core initialized successfully');

      // Only initialize AppCheck in production mode AND if not already initialized
      if (!kDebugMode) {
        await _initializeAppCheck();
      } else {
        debugPrint('🛡️ AppCheck DISABLED in debug mode for development');
      }

      _initialized = true;
      debugPrint('🔥 Firebase initialization completed successfully');
      return app;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase initialization failed with FirebaseException: $e');
      if (e.code == 'duplicate-app') {
        debugPrint('🔥 Duplicate app detected, using existing instance');
        _initialized = true;
        return Firebase.app();
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Firebase initialization failed with unexpected error: $e');
      rethrow;
    }
  }

  /// Initialize Firebase for development with enhanced debugging
  static Future<FirebaseApp> initializeFirebaseForDevelopment() async {
    if (!kDebugMode) {
      // In production, use the standard initialization
      return initializeFirebase();
    }

    debugPrint('🔧 Initializing Firebase for DEVELOPMENT mode...');
    debugPrint('🔧 Current Firebase apps count: ${Firebase.apps.length}');
    debugPrint('🔧 _initialized state: $_initialized');

    if (_initialized) {
      debugPrint('🔥 Firebase already initialized in development mode');
      return Firebase.app();
    }

    try {
      // Note: We assume Flutter bindings are already initialized by the caller
      // This method should only be called after WidgetsFlutterBinding.ensureInitialized()
      debugPrint(
        '🔧 Proceeding with Firebase initialization (Flutter bindings assumed initialized)',
      );

      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint(
          '🔥 Firebase already initialized by another component, using existing app',
        );
        debugPrint('🔥 Existing app name: ${Firebase.app().name}');
        _initialized = true;
        return Firebase.app();
      }

      debugPrint('🔥 Initializing Firebase core for the first time...');

      // Initialize Firebase first
      final app = await Firebase.initializeApp(
        options: fb_opts.DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('🔥 Firebase core initialized successfully');
      debugPrint('🛡️ AppCheck DISABLED for development (simulator-friendly)');

      // Skip AppCheck entirely in development
      // This prevents all the DeviceCheckProvider errors in simulator

      _initialized = true;
      debugPrint(
        '🔥 Firebase development initialization completed successfully',
      );
      debugPrint(
        '🎯 Ready for development - AppCheck warnings expected and safe to ignore',
      );

      return app;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase development initialization failed: $e');
      if (e.code == 'duplicate-app') {
        debugPrint('🔥 Duplicate app detected, using existing instance');
        _initialized = true;
        return Firebase.app();
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Firebase development initialization failed: $e');
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

  /// Reset initialization state (for testing/development only)
  static void resetInitializationState() {
    if (kDebugMode) {
      _initialized = false;
      _appCheckInitialized = false;
      debugPrint('🔄 Firebase initialization state reset');
    }
  }

  /// Check if Firebase is properly initialized
  static bool get isInitialized => _initialized && Firebase.apps.isNotEmpty;

  /// Get current Firebase app instance safely
  static FirebaseApp? get currentApp {
    try {
      return Firebase.apps.isNotEmpty ? Firebase.app() : null;
    } catch (e) {
      debugPrint('⚠️ Error getting current Firebase app: $e');
      return null;
    }
  }

  /// Initialize Firebase App Check with better error handling for simulators
  static Future<void> _initializeAppCheck() async {
    // Skip AppCheck entirely in debug mode to avoid all simulator issues
    if (kDebugMode) {
      debugPrint('🛡️ AppCheck DISABLED in debug mode for development');
      return;
    }

    // Check if AppCheck is already initialized
    if (_appCheckInitialized) {
      debugPrint('🛡️ AppCheck already initialized, skipping');
      return;
    }

    debugPrint('🛡️ Attempting to initialize AppCheck for production...');

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );
      _appCheckInitialized = true;
      debugPrint('🛡️ AppCheck initialized successfully for production');
    } catch (e) {
      debugPrint('⚠️ AppCheck initialization failed: $e');
      // Continue without AppCheck in case of any errors
      // Firebase services will still work with placeholder tokens
    }
  }

  /// Disable AppCheck globally in debug mode (call this early in main())
  static void disableAppCheckInDebug() {
    if (kDebugMode) {
      _appCheckInitialized = true; // Mark as initialized to prevent activation
      debugPrint('🛡️ AppCheck disabled globally for debug mode');
    }
  }

  /// Check if AppCheck should be skipped
  static bool get shouldSkipAppCheck => kDebugMode || _appCheckInitialized;

  /// Test Firebase connectivity and provide diagnostic information
  static Future<Map<String, dynamic>> runFirebaseDiagnostics() async {
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'isDebugMode': kDebugMode,
      'platform': defaultTargetPlatform.toString(),
    };

    try {
      // Check if Firebase is initialized
      diagnostics['firebaseInitialized'] = isInitialized;
      diagnostics['firebaseAppsCount'] = Firebase.apps.length;

      if (isInitialized) {
        final app = Firebase.app();
        diagnostics['firebaseAppName'] = app.name;
        diagnostics['firebaseAppOptions'] = {
          'projectId': app.options.projectId,
          'appId': app.options.appId,
          'apiKey':
              app.options.apiKey.substring(0, 10) +
              '...', // Partial for security
        };

        // Test Firestore connectivity
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.enableNetwork();
          diagnostics['firestoreConnectivity'] = 'enabled';
        } catch (e) {
          diagnostics['firestoreError'] = e.toString();
        }

        // Test Firebase Storage
        try {
          final storage = FirebaseStorage.instance;
          // Just test if we can access the storage instance
          storage.ref().child('test'); // Test reference creation
          diagnostics['storageConnectivity'] = 'accessible';
        } catch (e) {
          diagnostics['storageError'] = e.toString();
        }

        // Test Firebase Auth
        try {
          final auth = FirebaseAuth.instance;
          diagnostics['authUser'] = auth.currentUser?.uid ?? 'anonymous';
        } catch (e) {
          diagnostics['authError'] = e.toString();
        }
      }
    } catch (e) {
      diagnostics['diagnosticError'] = e.toString();
    }

    // Print diagnostics for debugging
    debugPrint('🔍 Firebase Diagnostics: $diagnostics');
    return diagnostics;
  }
}
