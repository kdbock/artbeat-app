import 'package:artbeat_core/artbeat_core.dart';

/// Service to prevent common crashes and handle errors gracefully
class CrashPreventionService {
  factory CrashPreventionService() => _instance;
  CrashPreventionService._internal();
  static final CrashPreventionService _instance =
      CrashPreventionService._internal();

  /// Safely execute an async operation with error handling
  static Future<T?> safeExecute<T>({
    required Future<T> Function() operation,
    String? operationName,
    T? fallbackValue,
    bool logErrors = true,
  }) async {
    try {
      return await operation();
    } on Object catch (e, stackTrace) {
      if (logErrors) {
        AppLogger.error(
          'Safe execution failed for ${operationName ?? 'unknown operation'}: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return fallbackValue;
    }
  }

  /// Safely execute a synchronous operation with error handling
  static T? safeExecuteSync<T>({
    required T Function() operation,
    String? operationName,
    T? fallbackValue,
    bool logErrors = true,
  }) {
    try {
      return operation();
    } on Object catch (e, stackTrace) {
      if (logErrors) {
        AppLogger.error(
          'Safe sync execution failed for ${operationName ?? 'unknown operation'}: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return fallbackValue;
    }
  }

  /// Validate and sanitize user input to prevent crashes
  static String sanitizeString(String? input, {String fallback = ''}) {
    if (input == null || input.isEmpty) return fallback;
    return input.trim();
  }

  /// Validate numeric input
  static double sanitizeDouble(dynamic input, {double fallback = 0.0}) {
    if (input == null) return fallback;

    if (input is double) {
      return input.isFinite ? input : fallback;
    }

    if (input is int) {
      return input.toDouble();
    }

    if (input is String) {
      final parsed = double.tryParse(input);
      return (parsed?.isFinite ?? false) ? parsed! : fallback;
    }

    return fallback;
  }

  /// Validate integer input
  static int sanitizeInt(dynamic input, {int fallback = 0}) {
    if (input == null) return fallback;

    if (input is int) return input;

    if (input is double) {
      return input.isFinite ? input.round() : fallback;
    }

    if (input is String) {
      final parsed = int.tryParse(input);
      return parsed ?? fallback;
    }

    return fallback;
  }

  /// Validate list input
  static List<T> sanitizeList<T>(dynamic input, {List<T>? fallback}) {
    fallback ??= <T>[];

    if (input == null) return fallback;

    if (input is List<T>) return input;

    if (input is List) {
      try {
        return input.cast<T>();
      } on Object catch (e) {
        AppLogger.warning('Failed to cast list: $e');
        return fallback;
      }
    }

    return fallback;
  }

  /// Validate map input
  static Map<String, dynamic> sanitizeMap(
    dynamic input, {
    Map<String, dynamic>? fallback,
  }) {
    fallback ??= <String, dynamic>{};

    if (input == null) return fallback;

    if (input is Map<String, dynamic>) return input;

    if (input is Map) {
      try {
        return Map<String, dynamic>.from(input);
      } on Object catch (e) {
        AppLogger.warning('Failed to convert map: $e');
        return fallback;
      }
    }

    return fallback;
  }

  /// Validate coordinates to prevent map crashes
  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;

    if (!latitude.isFinite || !longitude.isFinite) return false;

    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;

    return true;
  }

  /// Validate Stripe payment arguments to prevent crashes
  static bool validateStripePaymentArgs(Map<String, dynamic>? args) {
    if (args == null || args.isEmpty) {
      logCrashPrevention(
        operation: 'stripe_payment_validation',
        errorType: 'null_or_empty_args',
        additionalInfo: 'Payment arguments are null or empty',
      );
      return false;
    }

    // Check for common required fields based on crash reports
    final requiredFields = [
      'client_secret', // Required for most Stripe operations
      'payment_method', // Required for payment processing
      'amount', // Required for payment amount
    ];

    for (final field in requiredFields) {
      if (!args.containsKey(field) || args[field] == null) {
        logCrashPrevention(
          operation: 'stripe_payment_validation',
          errorType: 'missing_required_field',
          additionalInfo: 'Missing required field: $field',
        );
        return false;
      }
    }

    return true;
  }

  /// Validate Google Sign-In arguments to prevent null object crashes
  static bool validateGoogleSignInArgs(dynamic signInOptions) {
    if (signInOptions == null) {
      logCrashPrevention(
        operation: 'google_signin_validation',
        errorType: 'null_signin_options',
        additionalInfo: 'Google Sign-In options are null',
      );
      return false;
    }

    // Validate that required Sign-In configuration is present
    if (signInOptions is Map) {
      final hasClientId =
          signInOptions.containsKey('client_id') &&
          signInOptions['client_id'] != null;
      final hasScopes =
          signInOptions.containsKey('scopes') &&
          signInOptions['scopes'] != null;

      if (!hasClientId) {
        logCrashPrevention(
          operation: 'google_signin_validation',
          errorType: 'missing_client_id',
          additionalInfo: 'Google Sign-In client ID is missing',
        );
        return false;
      }

      if (!hasScopes) {
        logCrashPrevention(
          operation: 'google_signin_validation',
          errorType: 'missing_scopes',
          additionalInfo: 'Google Sign-In scopes are missing',
        );
        return false;
      }
    }

    return true;
  }

  /// Validate billing purchase data to prevent null PendingIntent crashes
  static bool validateBillingPurchaseData(dynamic purchaseData) {
    if (purchaseData == null) {
      logCrashPrevention(
        operation: 'billing_validation',
        errorType: 'null_purchase_data',
        additionalInfo: 'Billing purchase data is null',
      );
      return false;
    }

    // Check for PendingIntent in purchase data
    if (purchaseData is Map) {
      final pendingIntent =
          purchaseData['pending_intent'] ?? purchaseData['pendingIntent'];

      if (pendingIntent == null) {
        logCrashPrevention(
          operation: 'billing_validation',
          errorType: 'null_pending_intent',
          additionalInfo: 'PendingIntent is null in purchase data',
        );
        return false;
      }

      // Additional validation for PendingIntent structure
      if (pendingIntent is Map) {
        final intentSender =
            pendingIntent['intent_sender'] ?? pendingIntent['intentSender'];
        if (intentSender == null) {
          logCrashPrevention(
            operation: 'billing_validation',
            errorType: 'null_intent_sender',
            additionalInfo: 'IntentSender is null in PendingIntent',
          );
          return false;
        }
      }
    }

    return true;
  }

  /// Validate activity intent extras to prevent argument-related crashes
  static bool validateActivityIntentExtras(
    dynamic intentExtras,
    List<String> requiredExtras,
  ) {
    if (intentExtras == null) {
      logCrashPrevention(
        operation: 'activity_intent_validation',
        errorType: 'null_intent_extras',
        additionalInfo: 'Activity intent extras are null',
      );
      return false;
    }

    if (intentExtras is! Map) {
      logCrashPrevention(
        operation: 'activity_intent_validation',
        errorType: 'invalid_extras_format',
        additionalInfo: 'Intent extras are not in expected Map format',
      );
      return false;
    }

    for (final extra in requiredExtras) {
      if (!intentExtras.containsKey(extra) || intentExtras[extra] == null) {
        logCrashPrevention(
          operation: 'activity_intent_validation',
          errorType: 'missing_required_extra',
          additionalInfo: 'Missing required intent extra: $extra',
        );
        return false;
      }
    }

    return true;
  }

  /// Get user-friendly error message based on error type
  static String getUserFriendlyErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();

    // Stripe payment errors
    if (errorString.contains('stripe') ||
        errorString.contains('payment') ||
        errorString.contains('polling') ||
        errorString.contains('address') && errorString.contains('element') ||
        errorString.contains('cvc') ||
        errorString.contains('challenge') ||
        errorString.contains('bacs') ||
        errorString.contains('mandate')) {
      return 'Payment processing is temporarily unavailable. Please try again in a moment.';
    }

    // Google Sign-In errors
    if (errorString.contains('google') ||
        errorString.contains('signin') ||
        errorString.contains('sign-in') ||
        errorString.contains('auth') && errorString.contains('hub')) {
      return 'Sign-in service is temporarily unavailable. Please try again or use a different sign-in method.';
    }

    // Billing/In-App Purchase errors
    if (errorString.contains('billing') ||
        errorString.contains('purchase') ||
        errorString.contains('pendingintent') ||
        errorString.contains('proxybilling')) {
      return 'Purchase service is temporarily unavailable. Please try again later.';
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable')) {
      return 'Network connection issue. Please check your internet and try again.';
    }

    // Permission errors
    if (errorString.contains('permission')) {
      return 'Permission required. Please check your app settings.';
    }

    // Camera errors
    if (errorString.contains('camera')) {
      return 'Camera not available. Please check your device settings.';
    }

    // Location errors
    if (errorString.contains('location') || errorString.contains('gps')) {
      return 'Location services required. Please enable location access.';
    }

    // Firebase errors
    if (errorString.contains('firebase') || errorString.contains('firestore')) {
      return 'Service temporarily unavailable. Please try again later.';
    }

    // Authentication errors
    if (errorString.contains('auth') || errorString.contains('login')) {
      return 'Authentication required. Please log in and try again.';
    }

    // Data errors
    if (errorString.contains('not found') || errorString.contains('missing')) {
      return 'Requested data not found. It may have been removed.';
    }

    // Storage errors
    if (errorString.contains('storage') || errorString.contains('disk')) {
      return 'Storage issue. Please free up space and try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Log crash prevention metrics
  static void logCrashPrevention({
    required String operation,
    required String errorType,
    String? additionalInfo,
  }) {
    AppLogger.info(
      '🛡️ Crash prevented - Operation: $operation, Error: $errorType${additionalInfo != null ? ', Info: $additionalInfo' : ''}',
    );
  }

  /// Check if the app is in a stable state for critical operations
  static bool isAppStable() {
    try {
      // Add checks for app stability
      // This could include checking memory usage, network connectivity, etc.
      return true;
    } on Object catch (e) {
      AppLogger.error('Error checking app stability: $e');
      return false;
    }
  }

  /// Retry an operation with exponential backoff
  static Future<T?> retryOperation<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    String? operationName,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          AppLogger.error(
            'Operation failed after $maxRetries attempts: ${operationName ?? 'unknown'} - $e',
          );
          rethrow;
        }

        AppLogger.warning(
          'Operation attempt $attempts failed: ${operationName ?? 'unknown'} - $e. Retrying in ${delay.inMilliseconds}ms...',
        );

        await Future<void>.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }

    return null;
  }
}
