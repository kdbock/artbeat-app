import 'dart:async';
import '../utils/logger.dart';

/// Service to handle crash recovery and initialization retries
class CrashRecoveryService {
  static final CrashRecoveryService _instance =
      CrashRecoveryService._internal();
  factory CrashRecoveryService() => _instance;
  CrashRecoveryService._internal();

  static const int maxRetries = 3;
  static const Duration initialBackoff = Duration(milliseconds: 100);
  static const double backoffMultiplier = 2.0;

  final Map<String, int> _failureCount = {};
  final Map<String, DateTime> _lastFailureTime = {};

  /// Execute an operation with automatic retry on failure
  Future<T?> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxAttempts = maxRetries,
    Duration initialDelay = initialBackoff,
    bool exponentialBackoff = true,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;
    Exception? lastException;

    while (attempt < maxAttempts) {
      try {
        AppLogger.info(
          '🔄 Attempting operation: $operationName (attempt ${attempt + 1}/$maxAttempts)',
        );

        final result = await operation().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException(
              '$operationName timed out',
              const Duration(seconds: 30),
            );
          },
        );

        // Success - reset failure count
        _failureCount[operationName] = 0;
        _lastFailureTime.remove(operationName);

        AppLogger.info('✅ Operation succeeded: $operationName');
        return result;
      } on TimeoutException catch (e) {
        lastException = e;
        AppLogger.warning(
          '⏱️ Timeout on attempt ${attempt + 1}: $operationName',
        );
        attempt++;
      } on Exception catch (e) {
        lastException = e;
        AppLogger.warning(
          '⚠️ Error on attempt ${attempt + 1}: $operationName\n'
          'Error: ${e.toString()}',
        );
        attempt++;
      }

      // If not the last attempt, wait before retrying
      if (attempt < maxAttempts) {
        AppLogger.info(
          '⏳ Waiting ${currentDelay.inMilliseconds}ms before retry...',
        );
        await Future<void>.delayed(currentDelay);

        if (exponentialBackoff) {
          currentDelay = Duration(
            milliseconds: (currentDelay.inMilliseconds * backoffMultiplier)
                .toInt(),
          );
        }
      }
    }

    // All retries failed
    _recordFailure(operationName);
    AppLogger.error(
      '❌ Operation failed after $maxAttempts attempts: $operationName\n'
      'Last error: ${lastException?.toString()}',
      error: lastException,
    );
    return null;
  }

  /// Check if an operation should be retried based on failure history
  bool shouldRetry(String operationName) {
    final failureCount = _failureCount[operationName] ?? 0;
    if (failureCount >= maxRetries) {
      return false;
    }

    final lastFailure = _lastFailureTime[operationName];
    if (lastFailure == null) {
      return true;
    }

    // Calculate backoff time based on failure count
    final backoffDuration = Duration(
      milliseconds: (initialBackoff.inMilliseconds * (1 << failureCount))
          .toInt(),
    );
    final timeSinceFailure = DateTime.now().difference(lastFailure);

    return timeSinceFailure.inMilliseconds >= backoffDuration.inMilliseconds;
  }

  /// Record a failure for an operation
  void _recordFailure(String operationName) {
    _failureCount[operationName] = (_failureCount[operationName] ?? 0) + 1;
    _lastFailureTime[operationName] = DateTime.now();
  }

  /// Reset failure tracking for an operation
  void resetFailureTracking(String operationName) {
    _failureCount.remove(operationName);
    _lastFailureTime.remove(operationName);
  }

  /// Reset all failure tracking
  void resetAll() {
    _failureCount.clear();
    _lastFailureTime.clear();
  }

  /// Get failure statistics
  Map<String, dynamic> getFailureStats(String operationName) {
    return {
      'failureCount': _failureCount[operationName] ?? 0,
      'shouldRetry': shouldRetry(operationName),
      'lastFailure': _lastFailureTime[operationName],
    };
  }

  /// Execute multiple operations with recovery
  Future<Map<String, dynamic>> executeMultipleWithRecovery({
    required Map<String, Future<void> Function()> operations,
    bool failFast = false,
  }) async {
    final results = <String, dynamic>{};
    final errors = <String, Exception>{};

    for (final entry in operations.entries) {
      final name = entry.key;
      final operation = entry.value;

      try {
        AppLogger.info('🔄 Executing: $name');
        await operation();
        results[name] = true;
        AppLogger.info('✅ Completed: $name');
      } catch (e) {
        final exception = Exception(e.toString());
        errors[name] = exception;
        AppLogger.error('❌ Failed: $name\nError: $e');

        if (failFast) {
          break;
        }
      }
    }

    results['errors'] = errors;
    results['failureCount'] = errors.length;
    results['successCount'] = operations.length - errors.length;

    return results;
  }

  /// Execute initialization with panic recovery
  Future<bool> executeInitializationWithPanicRecovery<T>({
    required Future<T> Function() initialization,
    required String initName,
    bool throwOnFailure = false,
  }) async {
    try {
      AppLogger.info('🚀 Starting initialization: $initName');

      final result = await executeWithRetry(
        operation: initialization,
        operationName: initName,
        maxAttempts: maxRetries,
      );

      if (result != null) {
        AppLogger.info('✅ Initialization successful: $initName');
        return true;
      } else {
        AppLogger.error('❌ Initialization failed: $initName');
        if (throwOnFailure) {
          throw Exception('Initialization failed: $initName');
        }
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '🚨 Panic: Initialization crash during: $initName',
        error: e,
        stackTrace: stackTrace,
      );

      if (throwOnFailure) {
        rethrow;
      }
      return false;
    }
  }

  /// Warm-up critical services to catch initialization issues early
  Future<Map<String, bool>> warmUpServices({
    required List<String> serviceNames,
    required Map<String, Future<bool> Function()> serviceInitializers,
  }) async {
    AppLogger.info('🔥 Warming up critical services...');

    final results = <String, bool>{};

    for (final serviceName in serviceNames) {
      if (!serviceInitializers.containsKey(serviceName)) {
        AppLogger.warning('⚠️ No initializer for service: $serviceName');
        results[serviceName] = false;
        continue;
      }

      try {
        AppLogger.info('🔄 Warming up: $serviceName');
        final initialized = await serviceInitializers[serviceName]!();
        results[serviceName] = initialized;

        if (initialized) {
          AppLogger.info('✅ Warmed up: $serviceName');
        } else {
          AppLogger.warning('⚠️ Failed to warm up: $serviceName');
        }
      } catch (e) {
        AppLogger.error('❌ Error warming up $serviceName: $e');
        results[serviceName] = false;
      }
    }

    return results;
  }
}

/// Custom exception for timeout
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => message;
}

/// Crash recovery configuration
class CrashRecoveryConfig {
  final int maxRetries;
  final Duration initialBackoff;
  final double backoffMultiplier;
  final Duration operationTimeout;
  final bool enableExponentialBackoff;
  final bool enableAutoWarmup;

  const CrashRecoveryConfig({
    this.maxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 100),
    this.backoffMultiplier = 2.0,
    this.operationTimeout = const Duration(seconds: 30),
    this.enableExponentialBackoff = true,
    this.enableAutoWarmup = true,
  });
}
