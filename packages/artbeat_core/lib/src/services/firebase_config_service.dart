import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for configuring Firebase settings and timeouts
class FirebaseConfigService {
  static final FirebaseConfigService _instance =
      FirebaseConfigService._internal();
  factory FirebaseConfigService() => _instance;
  FirebaseConfigService._internal();

  /// Configure Firebase settings for optimal performance
  Future<void> configureFirebase() async {
    try {
      // Configure Firestore settings with persistence enabled
      // and proper caching for offline support
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true, // This replaces enablePersistence
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        sslEnabled: true,
      );

      debugPrint('✅ Firebase configured successfully with persistence enabled');
    } catch (e) {
      debugPrint('❌ Error configuring Firebase: $e');
      if (e is FirebaseException) {
        if (e.code == 'failed-precondition') {
          // Multiple tabs open, persistence can only be enabled in one tab at a time
          debugPrint('Multiple tabs are open, offline persistence disabled');
        } else if (e.code == 'unimplemented') {
          // The current browser does not support persistence
          debugPrint('Current platform does not support offline persistence');
        }
      }
      // Continue even if configuration fails - app should still work online
    }
  }
}
