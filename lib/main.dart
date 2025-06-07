import 'dart:math' show min;
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('🔒 Initializing App Check...');
    try {
      if (kDebugMode) {
        debugPrint('🛠️ Debug mode detected, using debug providers');
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );

        // Set up debug token monitoring
        FirebaseAppCheck.instance.onTokenChange.listen(
          (token) {
            if (token != null) {
              final previewLength = min(10, token.length);
              debugPrint(
                  '🔑 Debug token received: ${token.substring(0, previewLength)}...');
            }
          },
          onError: (e) => debugPrint('⚠️ Debug token error: $e'),
        );

        debugPrint('✅ App Check initialized in debug mode');
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
        debugPrint('✅ App Check initialized in production mode');
      }
    } catch (e) {
      debugPrint('⚠️ App Check initialization failed: $e');
      if (kDebugMode) {
        debugPrint('''💡 Debug mode troubleshooting steps:
1. Verify debug token in Firebase Console and build.gradle.kts:
   - Go to Firebase Console -> App Check -> Apps
   - Debug token is set in build.gradle.kts
2. Check app package name matches Firebase registration
3. Ensure Firebase project is properly configured
''');
        debugPrint('Continuing without App Check in debug mode...');
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
