/// Configuration utility class for accessing environment variables securely
/// This class provides a centralized way to access environment variables and API keys
/// without hardcoding them in the application code.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class AppConfig {
  static final Logger _logger = Logger();

  // Fallback values for development only
  // These are placeholders and should never contain actual API keys
  static const Map<String, String> _fallbacks = {
    'FIREBASE_ANDROID_API_KEY': 'placeholder_firebase_android_key',
    'FIREBASE_IOS_API_KEY': 'placeholder_firebase_ios_key',
    'GOOGLE_MAPS_API_KEY': 'placeholder_google_maps_key',
  };

  /// Gets a value from environment variables with error handling
  static String get(String key, {String defaultValue = ''}) {
    try {
      final value = dotenv.env[key];

      if (value == null || value.isEmpty || value == 'placeholder_value') {
        // In debug mode, use fallback values
        if (kDebugMode) {
          final fallback = _fallbacks[key] ?? defaultValue;
          if (fallback.isNotEmpty) {
            _logger.w(
                'Environment variable $key not found, using fallback for development');
            return fallback;
          }
        } else if (defaultValue.isNotEmpty) {
          _logger.w('Environment variable $key not found, using default value');
          return defaultValue;
        }

        _logger
            .e('Environment variable $key not found and no default provided');
        throw Exception('Environment variable $key not found');
      }
      return value;
    } catch (e) {
      _logger.e('Error accessing environment variable $key: $e');
      if (defaultValue.isNotEmpty) {
        return defaultValue;
      }
      rethrow;
    }
  }

  // Firebase API keys
  static String get firebaseAndroidApiKey => get('FIREBASE_ANDROID_API_KEY');
  static String get firebaseIosApiKey => get('FIREBASE_IOS_API_KEY');

  // Google Maps API key
  static String get googleMapsApiKey => get('GOOGLE_MAPS_API_KEY');

  // Check if using placeholder values (useful for displaying warnings)
  static bool get isUsingPlaceholders {
    final keys = [
      'FIREBASE_ANDROID_API_KEY',
      'FIREBASE_IOS_API_KEY',
      'GOOGLE_MAPS_API_KEY'
    ];

    // For private repository, we might be using the real keys directly
    final hasEnvFile = dotenv.env.isNotEmpty;

    if (!hasEnvFile) {
      // If no .env file exists, we need to rely on hardcoded values which is okay in a private repo
      return false;
    }

    for (final key in keys) {
      final value = dotenv.env[key];
      if (value == null || value.isEmpty || value == 'placeholder_value') {
        return true;
      }
    }
    return false;
  }
}
