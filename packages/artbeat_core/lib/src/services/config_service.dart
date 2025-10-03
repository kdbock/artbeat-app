import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Service for managing configuration and environment variables securely
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();

  ConfigService._();

  bool _isInitialized = false;

  /// Initialize the config service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _isInitialized = true;
      if (kDebugMode) {
        AppLogger.info('✅ ConfigService initialized successfully');
      }
    } catch (e) {
      // Log the error but don't fail the app initialization
      if (kDebugMode) {
        AppLogger.warning('⚠️ Failed to load .env file: $e');
        AppLogger.info('💡 App will continue with default configuration');
      }
      // Mark as initialized even if .env loading failed to prevent retries
      _isInitialized = true;
      // Don't rethrow - allow app to continue without .env file
    }
  }

  /// Get a configuration value securely
  String? get(String key) {
    try {
      return dotenv.env[key];
    } catch (e) {
      AppLogger.error('Error getting config value for $key: $e');
      return null;
    }
  }

  /// Get Firebase options securely
  Map<String, String?> get firebaseConfig => {
    'apiKey': get('FIREBASE_API_KEY'),
    'appId': get('FIREBASE_APP_ID'),
    'messagingSenderId': get('FIREBASE_MESSAGING_SENDER_ID'),
    'projectId': get('FIREBASE_PROJECT_ID'),
    'storageBucket': get('FIREBASE_STORAGE_BUCKET'),
  };

  /// Get Google Maps API key securely
  String? get googleMapsApiKey => get('GOOGLE_MAPS_API_KEY');

  /// Get Firebase App Check debug token securely
  String? get firebaseAppCheckDebugToken =>
      get('FIREBASE_APP_CHECK_DEBUG_TOKEN');
}
