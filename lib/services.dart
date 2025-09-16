import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class ServiceHandler {
  factory ServiceHandler() => _instance;
  ServiceHandler._();
  static final _instance = ServiceHandler._();

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> initializeServices() async {
    try {
      AppLogger.info('🔧 Initializing app services...');

      // Verify Firebase App is initialized
      final app = Firebase.app();
      AppLogger.firebase('📱 Firebase App name: ${app.name}');

      // Skip App Check verification since it's already initialized in main.dart
      if (kDebugMode) {
        AppLogger.debug('🔒 Skipping App Check verification in debug mode');
      }

      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      AppLogger.auth('👤 Auth initialized: ${auth.currentUser?.uid ?? 'no user'}');

      AppLogger.info('✅ All services initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Error initializing services: $e');
      rethrow;
    }
  }
}
