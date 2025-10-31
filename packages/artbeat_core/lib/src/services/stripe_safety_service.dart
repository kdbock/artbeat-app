import 'dart:io';
import '../utils/logger.dart';

/// Service to safely handle Stripe payment flows with proper error handling and validation
class StripeSafetyService {
  static final StripeSafetyService _instance = StripeSafetyService._internal();
  factory StripeSafetyService() => _instance;
  StripeSafetyService._internal();

  static bool _isInitialized = false;
  static bool _stripeKeyLoaded = false;
  static String? _stripePublishableKey;
  static bool _isStripeAvailable = false;

  /// Initialize Stripe safety service with proper validation
  static Future<void> initialize({required String publishableKey}) async {
    try {
      if (_isInitialized) {
        AppLogger.info('🔒 Stripe Safety Service already initialized');
        return;
      }

      AppLogger.info('🔒 Initializing Stripe Safety Service...');

      // Validate key format
      if (publishableKey.isEmpty) {
        throw Exception('Stripe publishable key is empty');
      }

      if (!publishableKey.startsWith('pk_')) {
        AppLogger.warning(
          '⚠️ Stripe key does not start with "pk_" - may be invalid',
        );
      }

      _stripePublishableKey = publishableKey;
      _stripeKeyLoaded = true;

      // Check platform availability
      _isStripeAvailable = Platform.isAndroid || Platform.isIOS;

      if (!_isStripeAvailable) {
        AppLogger.warning('⚠️ Stripe not available on this platform');
      }

      _isInitialized = true;
      AppLogger.info('✅ Stripe Safety Service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to initialize Stripe Safety Service',
        error: e,
        stackTrace: stackTrace,
      );
      _isInitialized = false;
      rethrow;
    }
  }

  /// Safely attempt to create a payment method
  static Future<T?> safePaymentOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Pre-flight checks
      if (!_isInitialized) {
        throw Exception('Stripe Safety Service not initialized');
      }

      if (!_stripeKeyLoaded) {
        throw Exception('Stripe publishable key not loaded');
      }

      if (!_isStripeAvailable) {
        throw Exception('Stripe not available on this platform');
      }

      AppLogger.info('🔒 Starting safe payment operation: $operationName');

      // Execute operation with timeout
      final result = await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Payment operation timeout: $operationName',
            timeout,
          );
        },
      );

      AppLogger.info('✅ Payment operation succeeded: $operationName');
      return result;
    } on TimeoutException catch (e) {
      _handlePaymentError(operationName, 'Payment operation timed out', e);
      return null;
    } on PlatformException catch (e) {
      _handlePaymentError(operationName, 'Platform error: ${e.message}', e);
      return null;
    } on Exception catch (e, stackTrace) {
      _handlePaymentError(operationName, e.toString(), e, stackTrace);
      return null;
    }
  }

  /// Validate payment intent data before launching payment sheet
  static bool validatePaymentIntentData(Map<String, dynamic>? intentData) {
    try {
      if (intentData == null) {
        AppLogger.warning(
          '⚠️ Payment intent data is null - cannot proceed with payment',
        );
        return false;
      }

      final clientSecret = intentData['client_secret'];
      if (clientSecret == null ||
          (clientSecret is String && clientSecret.isEmpty)) {
        AppLogger.warning('⚠️ Missing client_secret in payment intent');
        return false;
      }

      AppLogger.info('✅ Payment intent validation successful');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error validating payment intent: $e');
      return false;
    }
  }

  /// Validate customer data before payment
  static bool validateCustomerData(Map<String, dynamic>? customerData) {
    try {
      if (customerData == null) {
        AppLogger.warning('⚠️ Customer data is null - using guest checkout');
        return true; // Guest checkout is allowed
      }

      final customerId = customerData['id'];
      if (customerId == null || (customerId is String && customerId.isEmpty)) {
        AppLogger.warning('⚠️ Missing customer ID in customer data');
        return false;
      }

      AppLogger.info('✅ Customer data validation successful');
      return true;
    } catch (e) {
      AppLogger.error('❌ Error validating customer data: $e');
      return false;
    }
  }

  /// Safely present payment sheet with validation
  static Future<PaymentSheetResult?> safePresentPaymentSheet({
    required Future<PaymentSheetResult> Function() presentFunction,
    Map<String, dynamic>? intentData,
    Map<String, dynamic>? customerData,
  }) async {
    try {
      // Validate intent data
      if (intentData != null && !validatePaymentIntentData(intentData)) {
        AppLogger.error(
          '❌ Payment sheet presentation aborted: Invalid intent data',
        );
        return PaymentSheetResult.failed;
      }

      // Validate customer data
      if (customerData != null && !validateCustomerData(customerData)) {
        AppLogger.error(
          '❌ Payment sheet presentation aborted: Invalid customer data',
        );
        return PaymentSheetResult.failed;
      }

      AppLogger.info('🔒 Presenting payment sheet safely');

      final result = await safePaymentOperation<PaymentSheetResult>(
        operation: presentFunction,
        operationName: 'present_payment_sheet',
        timeout: const Duration(seconds: 60),
      );

      return result ?? PaymentSheetResult.failed;
    } catch (e) {
      AppLogger.error('❌ Error presenting payment sheet: $e');
      return PaymentSheetResult.failed;
    }
  }

  /// Handle payment errors with appropriate logging
  static void _handlePaymentError(
    String operationName,
    String errorMessage,
    Object? error, [
    StackTrace? stackTrace,
  ]) {
    AppLogger.error(
      '❌ Payment operation failed: $operationName\n'
      'Error: $errorMessage',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Get Stripe key safely
  static String? getPublishableKey() {
    if (!_stripeKeyLoaded) {
      AppLogger.warning('⚠️ Stripe publishable key not loaded');
      return null;
    }
    return _stripePublishableKey;
  }

  /// Check if Stripe is ready for payment operations
  static bool get isReadyForPayments {
    return _isInitialized && _stripeKeyLoaded && _isStripeAvailable;
  }

  /// Check if Stripe is initialized
  static bool get isInitialized => _isInitialized;

  /// Get initialization status details
  static Map<String, bool> getStatusDetails() {
    return {
      'initialized': _isInitialized,
      'keyLoaded': _stripeKeyLoaded,
      'available': _isStripeAvailable,
      'readyForPayments': isReadyForPayments,
    };
  }

  /// Reset Stripe safety service (for testing or recovery)
  static void reset() {
    _isInitialized = false;
    _stripeKeyLoaded = false;
    _stripePublishableKey = null;
    _isStripeAvailable = false;
    AppLogger.info('🔒 Stripe Safety Service reset');
  }
}

/// Payment sheet result enum
enum PaymentSheetResult { completed, canceled, failed }

/// Custom exception for payment timeout
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => message;
}

/// Custom exception for platform-specific errors
class PlatformException implements Exception {
  final String? message;
  final String? code;
  final dynamic details;

  PlatformException({required this.message, this.code, this.details});

  @override
  String toString() => message ?? 'Unknown platform error';
}
