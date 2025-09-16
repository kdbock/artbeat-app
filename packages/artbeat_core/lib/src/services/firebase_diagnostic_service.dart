import '../utils/logger.dart';

/// Service for Firebase diagnostics and error logging
class FirebaseDiagnosticService {
  static final FirebaseDiagnosticService _instance =
      FirebaseDiagnosticService._internal();

  factory FirebaseDiagnosticService() => _instance;

  FirebaseDiagnosticService._internal();

  /// Log an error message
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.error('❌ ERROR: $message');
    if (error != null) {
      AppLogger.error('Error details: $error');
    }
    if (stackTrace != null) {
      AppLogger.info('Stack trace: $stackTrace');
    }
  }

  /// Log an info message
  void logInfo(String message) {
    AppLogger.info('ℹ️ INFO: $message');
  }

  /// Log a warning message
  void logWarning(String message, {Object? warning}) {
    AppLogger.warning('⚠️ WARNING: $message');
    if (warning != null) {
      AppLogger.warning('Warning details: $warning');
    }
  }

  /// Record a custom event
  void recordEvent(String eventName, {Map<String, dynamic>? parameters}) {
    AppLogger.analytics('📊 EVENT: $eventName');
    if (parameters != null) {
      AppLogger.info('Parameters: $parameters');
    }
  }
}
