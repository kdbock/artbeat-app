import 'package:flutter/foundation.dart';
import 'env_loader.dart';
import 'logger.dart';

/// Utility class for validating environment variables
class EnvValidator {
  static final EnvValidator _instance = EnvValidator._internal();
  factory EnvValidator() => _instance;

  EnvValidator._internal();

  final EnvLoader _envLoader = EnvLoader();

  /// Required environment variables for the application
  final List<String> _requiredVars = [
    'API_BASE_URL',
    'STRIPE_PUBLISHABLE_KEY',
    'FIREBASE_REGION',
  ];

  /// Validate that all required environment variables are set
  bool validateRequiredVars() {
    bool isValid = true;
    for (final key in _requiredVars) {
      if (!_envLoader.has(key) || _envLoader.get(key).isEmpty) {
        AppLogger.error('❌ Missing required environment variable: $key');
        isValid = false;
      }
    }

    if (isValid) {
      AppLogger.info('✅ All required environment variables are set');
    }

    return isValid;
  }

  /// Validate API URL format
  bool validateApiUrl() {
    try {
      final apiUrl = _envLoader.get('API_BASE_URL');
      Uri.parse(apiUrl);
      return true;
    } catch (e) {
      AppLogger.error('❌ Invalid API URL format: ${e.toString()}');
      return false;
    }
  }

  /// Validate all environment variables
  bool validateAll() {
    final List<bool> validations = [validateRequiredVars(), validateApiUrl()];

    return !validations.contains(false);
  }

  /// Print environment diagnostics
  void printDiagnostics() {
    AppLogger.debug('🔍 Environment Diagnostics:');
    AppLogger.info('API URL: ${_envLoader.get('API_BASE_URL')}');
    AppLogger.firebase('Firebase Region: ${_envLoader.get('FIREBASE_REGION')}');
    debugPrint(
      'Has Google Maps API Key: ${_envLoader.has('GOOGLE_MAPS_API_KEY')}',
    );
    AppLogger.info(
      'Has Stripe Key: ${_envLoader.has('STRIPE_PUBLISHABLE_KEY')}',
    );
  }
}
