import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// A helper class for loading environment files in different ways depending on the platform
class EnvLoader {
  static final Logger _logger = Logger();

  /// Loads environment variables from an asset file and returns the content as a string.
  static Future<String?> loadEnvStringFromAssets() async {
    _logger.i('Attempting to load .env from rootBundle...');
    try {
      // Load the .env file from assets
      final envString = await rootBundle.loadString('.env');
      _logger.i(
          '.env loaded successfully from rootBundle. Length: ${envString.length}');
      return envString;
    } catch (e) {
      _logger
          .e('Failed to load .env from rootBundle: $e. Type: ${e.runtimeType}');

      // Create a fallback env string for development if loading fails
      if (kDebugMode) {
        _logger.w('Creating fallback environment string for development');
        return '''
# Auto-generated fallback environment file
FIREBASE_ANDROID_API_KEY=placeholder_value
FIREBASE_IOS_API_KEY=placeholder_value
GOOGLE_MAPS_API_KEY=placeholder_value
''';
      }
      // In non-debug mode, or if fallback is not desired, return null or rethrow.
      // For now, returning null to allow AppConfig to handle fallbacks.
      return null;
    }
  }
}
