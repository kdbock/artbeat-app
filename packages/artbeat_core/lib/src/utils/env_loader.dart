import 'package:flutter/foundation.dart';

/// Utility class for loading environment variables and configuration
class EnvLoader {
  static final EnvLoader _instance = EnvLoader._internal();
  factory EnvLoader() => _instance;

  EnvLoader._internal();

  /// Map of environment variables
  final Map<String, String> _envVars = {};

  /// Initialize environment variables
  Future<void> init() async {
    try {
      // This would normally load from a .env file or other source
      // For now, we'll just hardcode some default values for testing
      _envVars.addAll({
        'API_BASE_URL': 'https://api.artbeat.app',
        'GOOGLE_MAPS_API_KEY': 'YOUR_MAPS_API_KEY',
        'STRIPE_PUBLISHABLE_KEY':
            'pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2',
        'FIREBASE_REGION': 'us-central1',
      });

      debugPrint('✅ Environment variables loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading environment variables: $e');
    }
  }

  /// Get an environment variable value
  String get(String key, {String defaultValue = ''}) {
    return _envVars[key] ?? defaultValue;
  }

  /// Check if an environment variable exists
  bool has(String key) {
    return _envVars.containsKey(key);
  }

  /// Get all environment variables
  Map<String, String> getAll() {
    return Map.unmodifiable(_envVars);
  }
}
