import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:artbeat/utils/app_config.dart';

/// Utility class to validate environment variables during app startup
class EnvValidator {
  static final Logger _logger = Logger();

  /// Validates that all required environment variables are present
  /// Returns true if all required variables are present, otherwise false
  static bool validateRequiredEnvVars() {
    try {
      _logger.i('Validating environment variables...');

      // List of required environment variables to check
      final requiredVars = [
        'FIREBASE_ANDROID_API_KEY',
        'FIREBASE_IOS_API_KEY',
        'GOOGLE_MAPS_API_KEY'
      ];

      // Check each required variable
      for (final varName in requiredVars) {
        final value = AppConfig.get(varName);
        if (value.isEmpty) {
          _logger.e('Required environment variable not found: $varName');
          return false;
        }
      }

      // Check if we're using placeholder values
      if (AppConfig.isUsingPlaceholders) {
        _logger.w('Using placeholder values for API keys');
        return false;
      }

      _logger.i('Environment variables validation successful');
      return true;
    } catch (e) {
      _logger.e('Error validating environment variables: $e');
      return false;
    }
  }

  /// Displays a warning dialog if any required environment variables are missing
  static void showWarningIfNeeded(BuildContext context) {
    if (!validateRequiredEnvVars()) {
      // Only show warning dialog in debug mode
      if (kDebugMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('API Key Setup Required'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You are using placeholder values for API keys.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To fix this:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Create a .env file in the project root'),
                    const Text('2. Add your API keys following this format:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FIREBASE_ANDROID_API_KEY=your_key_here'),
                          Text('FIREBASE_IOS_API_KEY=your_key_here'),
                          Text('GOOGLE_MAPS_API_KEY=your_key_here'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('For more information, please see:'),
                    const Text('API_KEY_MANAGEMENT.md'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue Anyway'),
                ),
              ],
            ),
          );
        });
      }
    }
  }
}
