import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  factory FirebaseInitializer() => _instance;

  FirebaseInitializer._internal();
  static bool _initialized = false;
  static final FirebaseInitializer _instance = FirebaseInitializer._internal();

  Future<void> ensureInitialized() async {
    if (_initialized) {
      AppLogger.firebase(
        '🔥 Firebase already initialized, skipping initialization',
      );
      return;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
      AppLogger.firebase('✅ Firebase initialized successfully');
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        _initialized = true;
        debugPrint(
          '🔥 Firebase already initialized (caught duplicate app error)',
        );
      } else {
        AppLogger.error('❌ Firebase initialization error: $e');
        rethrow;
      }
    }
  }
}
