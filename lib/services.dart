import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class ServiceHandler {
  static final _instance = ServiceHandler._();
  factory ServiceHandler() => _instance;
  ServiceHandler._();

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> initializeServices() async {
    try {
      debugPrint('🔧 Initializing app services...');

      // Verify Firebase App is initialized
      final app = Firebase.app();
      debugPrint('📱 Firebase App name: ${app.name}');

      // Skip App Check verification since it's already initialized in main.dart
      if (kDebugMode) {
        debugPrint('🔒 Skipping App Check verification in debug mode');
      }

      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      debugPrint('👤 Auth initialized: ${auth.currentUser?.uid ?? 'no user'}');

      debugPrint('✅ All services initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing services: $e');
      rethrow;
    }
  }
}
