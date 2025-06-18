import 'package:flutter/foundation.dart';

/// Service for Firebase diagnostics and error logging
class FirebaseDiagnosticService {
  static final FirebaseDiagnosticService _instance =
      FirebaseDiagnosticService._internal();

  factory FirebaseDiagnosticService() => _instance;

  FirebaseDiagnosticService._internal();

  /// Log an error message
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('❌ ERROR: $message');
    if (error != null) {
      debugPrint('Error details: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Log an info message
  void logInfo(String message) {
    debugPrint('ℹ️ INFO: $message');
  }

  /// Log a warning message
  void logWarning(String message, {Object? warning}) {
    debugPrint('⚠️ WARNING: $message');
    if (warning != null) {
      debugPrint('Warning details: $warning');
    }
  }

  /// Record a custom event
  void recordEvent(String eventName, {Map<String, dynamic>? parameters}) {
    debugPrint('📊 EVENT: $eventName');
    if (parameters != null) {
      debugPrint('Parameters: $parameters');
    }
  }
}
