import 'package:flutter/foundation.dart';
import 'env_loader.dart';

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
        debugPrint('❌ Missing required environment variable: $key');
        isValid = false;
      }
    }

    if (isValid) {
      debugPrint('✅ All required environment variables are set');
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
      debugPrint('❌ Invalid API URL format: ${e.toString()}');
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
    debugPrint('🔍 Environment Diagnostics:');
    debugPrint('API URL: ${_envLoader.get('API_BASE_URL')}');
    debugPrint('Firebase Region: ${_envLoader.get('FIREBASE_REGION')}');
    debugPrint(
      'Has Google Maps API Key: ${_envLoader.has('GOOGLE_MAPS_API_KEY')}',
    );
    debugPrint('Has Stripe Key: ${_envLoader.has('STRIPE_PUBLISHABLE_KEY')}');
  }
}
