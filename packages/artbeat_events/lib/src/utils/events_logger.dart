import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logging utility for the ARTbeat Events package
/// Provides secure, production-ready logging with proper level filtering
class EventsLogger {
  static final Logger _logger = Logger(
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
    printer: kDebugMode
        ? PrettyPrinter(dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart)
        : SimplePrinter(),
    output: ConsoleOutput(),
  );

  /// Log debug information (only in debug mode)
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log informational messages
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log severe/fatal errors
  static void severe(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Service-specific logger for event analytics operations
  static void eventAnalytics(
    String operation, {
    String? details,
    Object? error,
  }) {
    final message =
        'EventAnalytics: $operation${details != null ? ' - $details' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }

  /// Service-specific logger for event service operations
  static void eventService(String operation, {String? details, Object? error}) {
    final message =
        'EventService: $operation${details != null ? ' - $details' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }

  /// Service-specific logger for ticket operations
  static void ticketService(
    String operation, {
    String? details,
    Object? error,
  }) {
    final message =
        'TicketService: $operation${details != null ? ' - $details' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }
}
