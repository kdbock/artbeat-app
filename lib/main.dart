import 'dart:async';
import 'dart:math' show pow;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'app.dart';

// Global key to update loading status
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint('📱 Configuring system UI...');
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    debugPrint('🔥 Initializing Firebase Core...');
    FirebaseApp app;
    try {
      app = Firebase.app();
      debugPrint('✅ Firebase already initialized');
    } catch (e) {
      app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized for the first time');
    }
    await app.setAutomaticDataCollectionEnabled(true);

    debugPrint('🔒 Initializing App Check...');
    try {
      if (kDebugMode) {
        const debugToken = 'fae8ac60-fccf-486c-9844-3e3dbdb9ea3f';
        debugPrint('🔑 Using App Check debug token: $debugToken');

        // Enable token auto-refresh before activation
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

        // Initialize App Check in debug mode with exponential backoff
        int attempt = 0;
        const maxAttempts = 3;
        while (attempt < maxAttempts) {
          try {
            if (attempt > 0) {
              // Exponential backoff: 2s, 4s, 8s
              final backoffDuration =
                  Duration(seconds: pow(2, attempt + 1).toInt());
              debugPrint(
                  '⏳ Waiting ${backoffDuration.inSeconds}s before retry...');
              await Future.delayed(backoffDuration);
            }

            await FirebaseAppCheck.instance.activate(
              androidProvider: AndroidProvider.debug,
              appleProvider: AppleProvider.debug,
            );
            debugPrint('✅ App Check initialized successfully');
            break;
          } catch (e) {
            attempt++;
            if (attempt >= maxAttempts) {
              rethrow;
            }
            debugPrint('⚠️ App Check attempt $attempt failed: $e');
          }
        }
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
      }
    } catch (e) {
      debugPrint('⚠️ App Check initialization failed: $e');
      if (kDebugMode) {
        debugPrint('''
💡 Debug mode troubleshooting steps:
1. Verify debug token in Firebase Console:
   - Go to Firebase Console -> App Check -> Apps
   - Register debug token: fae8ac60-fccf-486c-9844-3e3dbdb9ea3f
2. Check app package name matches Firebase registration
3. Ensure Firebase project is properly configured

Continuing without App Check in debug mode...''');
      } else {
        rethrow;
      }
    }

    debugPrint('✅ All services initialized successfully');
    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint('❌ Fatal error during initialization: $e');
    debugPrint('Stack trace: $stack');
    runApp(const ErrorApp());
  }
}
