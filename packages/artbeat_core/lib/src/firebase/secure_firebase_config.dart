import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/firebase_options.dart' as fb_opts;

/// Handles Firebase initialization and App Check configuration
class SecureFirebaseConfig {
  const SecureFirebaseConfig._();

  static bool _initialized = false;
  static bool _appCheckInitialized = false;
  static Duration? _tokenTTL;
  static bool _debug = false;
  static String? _teamId;

  /// Configure App Check settings
  static Future<void> configureAppCheck({
    required String teamId,
    Duration? tokenTTL,
    bool debug = false,
  }) async {
    _teamId = teamId;
    _tokenTTL = tokenTTL;
    _debug = debug;

    if (kDebugMode) {
      print('🔐 App Check configured - Team ID: $teamId, Debug: $debug');
    }
  }

  /// Initialize Firebase with proper configuration
  static Future<FirebaseApp> initializeFirebase() async {
    if (_initialized) {
      if (kDebugMode) {
        print('🔥 Firebase already initialized via SecureFirebaseConfig');
      }
      return Firebase.app();
    }

    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      if (kDebugMode) {
        print(
          '🔥 Firebase apps already exist (${Firebase.apps.length} apps), using existing app: ${Firebase.app().name}',
        );
      }
      // Even if Firebase is already initialized, we should still initialize App Check if not done
      if (!_appCheckInitialized) {
        await _initializeAppCheck();
      }
      return Firebase.app();
    }

    try {
      if (kDebugMode) {
        print('🔥 Initializing Firebase with options...');
      }

      final app = await Firebase.initializeApp(
        options: fb_opts.DefaultFirebaseOptions.currentPlatform,
      );

      if (kDebugMode) {
        print('🔥 Firebase core initialized successfully');
      }

      await _initializeAppCheck();
      _initialized = true;

      if (kDebugMode) {
        print('✅ Complete Firebase initialization finished');
      }

      return app;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }

      // If it's a duplicate app error, that means Firebase is already initialized
      // This can happen in hot reload scenarios
      if (e.toString().contains('duplicate-app') ||
          e.toString().contains('already exists')) {
        if (kDebugMode) {
          print(
            '🔥 Firebase already initialized (caught duplicate app error), using existing app',
          );
        }
        _initialized = true;
        if (!_appCheckInitialized) {
          await _initializeAppCheck();
        }
        return Firebase.app();
      }

      rethrow;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized && Firebase.apps.isNotEmpty;

  /// Get current Firebase app instance
  static FirebaseApp? get currentApp {
    try {
      return Firebase.apps.isNotEmpty ? Firebase.app() : null;
    } catch (_) {
      return null;
    }
  }

  /// Initialize App Check
  static Future<void> _initializeAppCheck() async {
    if (_appCheckInitialized) {
      if (kDebugMode) {
        print('🔐 App Check already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔐 Initializing App Check...');
        print('🔐 Debug mode: $_debug');
        print('🔐 Team ID: $_teamId');

        // Always use debug provider in debug mode
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          webProvider: ReCaptchaV3Provider(
            '6LeiHc...',
          ), // Add your reCAPTCHA site key
        );

        // Get and log the debug token
        final token = await FirebaseAppCheck.instance.getToken();
        if (token != null) {
          print('🔐 Debug token: $token');
        }
      } else {
        // Production mode - use secure providers
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
          webProvider: ReCaptchaV3Provider(
            '6LeiHc...',
          ), // Add your reCAPTCHA site key
        );
      }

      if (kDebugMode) {
        print('🔐 App Check activated successfully');
      }

      _appCheckInitialized = true;

      if (_tokenTTL != null) {
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
        try {
          await FirebaseAppCheck.instance.getToken(true);
          if (kDebugMode) {
            print('🔐 App Check token retrieved successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '⚠️ App Check token retrieval failed (may be expected in debug): $e',
            );
          }
        }
      }

      _appCheckInitialized = true;
      if (kDebugMode) {
        print('✅ App Check initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ App Check initialization error: $e');
        print('⚠️ This may be expected in debug mode');
      }
      // Don't throw in debug mode to allow development
      if (!kDebugMode) {
        rethrow;
      }
      _appCheckInitialized = true; // Mark as initialized to avoid retries
    }
  }

  /// Reset initialization state (useful for hot restart)
  static void resetInitializationState() {
    _initialized = false;
    _appCheckInitialized = false;
    if (kDebugMode) {
      print('🔄 SecureFirebaseConfig initialization state reset');
    }
  }

  /// Ensure Firebase is properly initialized, handling edge cases
  static Future<FirebaseApp> ensureInitialized({
    String? teamId,
    bool? debug,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        // No Firebase apps exist, need full initialization
        if (teamId != null) {
          await configureAppCheck(teamId: teamId, debug: debug ?? kDebugMode);
        }
        return await initializeFirebase();
      } else {
        // Firebase apps exist, just ensure our state is correct
        if (!_initialized) {
          _initialized = true;
          if (kDebugMode) {
            print(
              '🔥 Firebase apps already exist, updating SecureFirebaseConfig state',
            );
          }
        }

        // Configure App Check if needed and parameters are provided
        if (!_appCheckInitialized && teamId != null) {
          await configureAppCheck(teamId: teamId, debug: debug ?? kDebugMode);
          await _initializeAppCheck();
        }

        return Firebase.app();
      }
    } catch (e) {
      // Handle any edge cases where Firebase.app() fails
      if (e.toString().contains('duplicate-app') ||
          e.toString().contains('already exists')) {
        if (kDebugMode) {
          print('🔥 Handled duplicate app error in ensureInitialized');
        }
        _initialized = true;
        if (!_appCheckInitialized && teamId != null) {
          await configureAppCheck(teamId: teamId, debug: debug ?? kDebugMode);
          await _initializeAppCheck();
        }
        return Firebase.app();
      }
      rethrow;
    }
  }

  /// Get basic Firebase status information
  static Map<String, dynamic> getStatus() => {
    'initialized': _initialized,
    'appCheckInitialized': _appCheckInitialized,
    'appsCount': Firebase.apps.length,
    'debug': _debug,
    'teamId': _teamId,
    'tokenTTL': _tokenTTL?.inMinutes,
    'hasCurrentApp': currentApp != null,
    'appNames': Firebase.apps.map((app) => app.name).toList(),
  };

  /// Test Firebase Storage access (for debugging -13020 errors)
  static Future<bool> testStorageAccess() async {
    if (!_initialized) {
      if (kDebugMode) {
        print('⚠️ Firebase not initialized for storage test');
      }
      return false;
    }

    try {
      final storage = FirebaseStorage.instance;

      // Try to list files in a simple directory
      final ref = storage.ref().child('test');
      await ref.listAll();

      if (kDebugMode) {
        print('✅ Firebase Storage access test passed');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Storage access test failed: $e');
        if (e.toString().contains('-13020')) {
          print('💡 Error -13020 indicates App Check authentication issue');
          print('💡 This is often expected in debug mode');
        }
      }
      return false;
    }
  }
}
