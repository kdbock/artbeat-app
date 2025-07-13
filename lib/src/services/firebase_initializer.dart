import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseInitializer {
  static bool _initialized = false;
  static final FirebaseInitializer _instance = FirebaseInitializer._internal();

  factory FirebaseInitializer() {
    return _instance;
  }

  FirebaseInitializer._internal();

  Future<void> ensureInitialized() async {
    if (_initialized) {
      debugPrint('🔥 Firebase already initialized, skipping initialization');
      return;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        _initialized = true;
        debugPrint(
          '🔥 Firebase already initialized (caught duplicate app error)',
        );
      } else {
        debugPrint('❌ Firebase initialization error: $e');
        rethrow;
      }
    }
  }
}
