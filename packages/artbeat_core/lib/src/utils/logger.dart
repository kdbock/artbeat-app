import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized logging service for ARTbeat application
///
/// This service provides a unified logging interface that:
/// - Uses proper logging levels instead of print statements
/// - Filters logs based on build mode (debug vs release)
/// - Provides structured logging with context
/// - Integrates with Flutter's developer tools
class AppLogger {
  static final Map<String, Logger> _loggers = {};
  static bool _initialized = false;

  /// Initialize the logging system
  static void initialize({bool enableInRelease = false}) {
    if (_initialized) return;

    // Configure logging level based on build mode
    if (kDebugMode || enableInRelease) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        _handleLogRecord(record);
      });
    } else {
      // In release mode, only log warnings and errors unless explicitly enabled
      Logger.root.level = Level.WARNING;
      Logger.root.onRecord.listen((record) {
        _handleLogRecord(record);
      });
    }

    _initialized = true;
  }

  /// Get a logger instance for a specific class or module
  static Logger getLogger(String name) {
    if (!_initialized) {
      initialize();
    }

    return _loggers.putIfAbsent(name, () => Logger(name));
  }

  /// Handle log records and format them appropriately
  static void _handleLogRecord(LogRecord record) {
    // Use developer.log for better integration with Flutter DevTools
    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }

  /// Convenience methods for common logging patterns
  static void debug(
    String message, {
    String? logger,
    Object? error,
    StackTrace? stackTrace,
  }) {
    getLogger(logger ?? 'App').fine(message, error, stackTrace);
  }

  static void info(
    String message, {
    String? logger,
    Object? error,
    StackTrace? stackTrace,
  }) {
    getLogger(logger ?? 'App').info(message, error, stackTrace);
  }

  static void warning(
    String message, {
    String? logger,
    Object? error,
    StackTrace? stackTrace,
  }) {
    getLogger(logger ?? 'App').warning(message, error, stackTrace);
  }

  static void error(
    String message, {
    String? logger,
    Object? error,
    StackTrace? stackTrace,
  }) {
    getLogger(logger ?? 'App').severe(message, error, stackTrace);
  }

  /// Log Firebase operations
  static void firebase(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    getLogger('Firebase').info(message, error, stackTrace);
  }

  /// Log authentication operations
  static void auth(String message, {Object? error, StackTrace? stackTrace}) {
    getLogger('Auth').info(message, error, stackTrace);
  }

  /// Log network operations
  static void network(String message, {Object? error, StackTrace? stackTrace}) {
    getLogger('Network').info(message, error, stackTrace);
  }

  /// Log UI operations
  static void ui(String message, {Object? error, StackTrace? stackTrace}) {
    getLogger('UI').fine(message, error, stackTrace);
  }

  /// Log performance metrics
  static void performance(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    getLogger('Performance').info(message, error, stackTrace);
  }

  /// Log analytics events
  static void analytics(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    getLogger('Analytics').info(message, error, stackTrace);
  }
}

/// Extension to make logging easier in classes
extension LoggerExtension on Object {
  Logger get logger => AppLogger.getLogger(runtimeType.toString());
}

/// Mixin to add logging capabilities to any class
mixin LoggingMixin {
  Logger get logger => AppLogger.getLogger(runtimeType.toString());

  void logDebug(String message, [Object? error, StackTrace? stackTrace]) {
    logger.fine(message, error, stackTrace);
  }

  void logInfo(String message, [Object? error, StackTrace? stackTrace]) {
    logger.info(message, error, stackTrace);
  }

  void logWarning(String message, [Object? error, StackTrace? stackTrace]) {
    logger.warning(message, error, stackTrace);
  }

  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    logger.severe(message, error, stackTrace);
  }
}
