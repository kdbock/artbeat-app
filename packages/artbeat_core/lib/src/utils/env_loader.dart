import 'logger.dart';

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
      // TODO: Load from secure environment configuration
      // For production, these should come from:
      // - Flutter's --dart-define flags during build
      // - Platform-specific secure storage
      // - Remote config (Firebase Remote Config)
      // NEVER hardcode production secrets!

      _envVars.addAll({
        'API_BASE_URL': const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.artbeat.app',
        ),
        'GOOGLE_MAPS_API_KEY': const String.fromEnvironment(
          'GOOGLE_MAPS_API_KEY',
          defaultValue: '',
        ),
        'STRIPE_PUBLISHABLE_KEY': const String.fromEnvironment(
          'STRIPE_PUBLISHABLE_KEY',
          defaultValue: '',
        ),
        'FIREBASE_REGION': const String.fromEnvironment(
          'FIREBASE_REGION',
          defaultValue: 'us-central1',
        ),
      });

      AppLogger.info('✅ Environment variables loaded successfully');
    } catch (e) {
      AppLogger.error('❌ Error loading environment variables: $e');
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
