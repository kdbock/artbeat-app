import 'package:flutter/foundation.dart';

/// Configuration manager for dynamic settings behavior
/// Implementation Date: September 5, 2025
class SettingsConfiguration {
  static final SettingsConfiguration _instance =
      SettingsConfiguration._internal();
  factory SettingsConfiguration() => _instance;
  SettingsConfiguration._internal();

  // Cache configuration
  Duration _cacheExpiryDuration = const Duration(minutes: 5);
  int _maxCacheSize = 100;
  bool _enablePersistentCache = true;

  // Performance configuration
  bool _enablePerformanceTracking = kDebugMode;
  int _slowOperationThreshold = 1000; // milliseconds
  bool _enableOptimisticUpdates = true;

  // Network configuration
  Duration _networkTimeout = const Duration(seconds: 30);
  int _maxRetryAttempts = 3;
  Duration _retryDelay = const Duration(seconds: 2);

  // Feature flags
  bool _enableRealtimeUpdates = true;
  bool _enableBatchUpdates = true;
  bool _enableCompressionForLargeData = true;
  bool _enableAnalytics = true;

  // Security configuration
  bool _enableEncryptionAtRest = false;
  bool _requireReauthenticationForSensitiveOperations = true;
  Duration _sessionTimeout = const Duration(hours: 24);

  // UI configuration
  bool _enableProgressIndicators = true;
  bool _enableErrorSnackbars = true;
  Duration _snackbarDuration = const Duration(seconds: 4);

  // Getters
  Duration get cacheExpiryDuration => _cacheExpiryDuration;
  int get maxCacheSize => _maxCacheSize;
  bool get enablePersistentCache => _enablePersistentCache;
  bool get enablePerformanceTracking => _enablePerformanceTracking;
  int get slowOperationThreshold => _slowOperationThreshold;
  bool get enableOptimisticUpdates => _enableOptimisticUpdates;
  Duration get networkTimeout => _networkTimeout;
  int get maxRetryAttempts => _maxRetryAttempts;
  Duration get retryDelay => _retryDelay;
  bool get enableRealtimeUpdates => _enableRealtimeUpdates;
  bool get enableBatchUpdates => _enableBatchUpdates;
  bool get enableCompressionForLargeData => _enableCompressionForLargeData;
  bool get enableAnalytics => _enableAnalytics;
  bool get enableEncryptionAtRest => _enableEncryptionAtRest;
  bool get requireReauthenticationForSensitiveOperations =>
      _requireReauthenticationForSensitiveOperations;
  Duration get sessionTimeout => _sessionTimeout;
  bool get enableProgressIndicators => _enableProgressIndicators;
  bool get enableErrorSnackbars => _enableErrorSnackbars;
  Duration get snackbarDuration => _snackbarDuration;

  /// Configure cache settings
  void configureCaching({
    Duration? expiryDuration,
    int? maxCacheSize,
    bool? enablePersistentCache,
  }) {
    if (expiryDuration != null) _cacheExpiryDuration = expiryDuration;
    if (maxCacheSize != null) _maxCacheSize = maxCacheSize;
    if (enablePersistentCache != null)
      _enablePersistentCache = enablePersistentCache;
  }

  /// Configure performance settings
  void configurePerformance({
    bool? enableTracking,
    int? slowOperationThreshold,
    bool? enableOptimisticUpdates,
  }) {
    if (enableTracking != null) _enablePerformanceTracking = enableTracking;
    if (slowOperationThreshold != null)
      _slowOperationThreshold = slowOperationThreshold;
    if (enableOptimisticUpdates != null)
      _enableOptimisticUpdates = enableOptimisticUpdates;
  }

  /// Configure network settings
  void configureNetwork({
    Duration? timeout,
    int? maxRetryAttempts,
    Duration? retryDelay,
  }) {
    if (timeout != null) _networkTimeout = timeout;
    if (maxRetryAttempts != null) _maxRetryAttempts = maxRetryAttempts;
    if (retryDelay != null) _retryDelay = retryDelay;
  }

  /// Configure feature flags
  void configureFeatures({
    bool? enableRealtimeUpdates,
    bool? enableBatchUpdates,
    bool? enableCompressionForLargeData,
    bool? enableAnalytics,
  }) {
    if (enableRealtimeUpdates != null)
      _enableRealtimeUpdates = enableRealtimeUpdates;
    if (enableBatchUpdates != null) _enableBatchUpdates = enableBatchUpdates;
    if (enableCompressionForLargeData != null)
      _enableCompressionForLargeData = enableCompressionForLargeData;
    if (enableAnalytics != null) _enableAnalytics = enableAnalytics;
  }

  /// Configure security settings
  void configureSecurity({
    bool? enableEncryptionAtRest,
    bool? requireReauthenticationForSensitiveOperations,
    Duration? sessionTimeout,
  }) {
    if (enableEncryptionAtRest != null)
      _enableEncryptionAtRest = enableEncryptionAtRest;
    if (requireReauthenticationForSensitiveOperations != null) {
      _requireReauthenticationForSensitiveOperations =
          requireReauthenticationForSensitiveOperations;
    }
    if (sessionTimeout != null) _sessionTimeout = sessionTimeout;
  }

  /// Configure UI settings
  void configureUI({
    bool? enableProgressIndicators,
    bool? enableErrorSnackbars,
    Duration? snackbarDuration,
  }) {
    if (enableProgressIndicators != null)
      _enableProgressIndicators = enableProgressIndicators;
    if (enableErrorSnackbars != null)
      _enableErrorSnackbars = enableErrorSnackbars;
    if (snackbarDuration != null) _snackbarDuration = snackbarDuration;
  }

  /// Get all configuration as a map
  Map<String, dynamic> toMap() {
    return {
      'cache': {
        'expiryDuration': _cacheExpiryDuration.inMilliseconds,
        'maxCacheSize': _maxCacheSize,
        'enablePersistentCache': _enablePersistentCache,
      },
      'performance': {
        'enableTracking': _enablePerformanceTracking,
        'slowOperationThreshold': _slowOperationThreshold,
        'enableOptimisticUpdates': _enableOptimisticUpdates,
      },
      'network': {
        'timeout': _networkTimeout.inMilliseconds,
        'maxRetryAttempts': _maxRetryAttempts,
        'retryDelay': _retryDelay.inMilliseconds,
      },
      'features': {
        'enableRealtimeUpdates': _enableRealtimeUpdates,
        'enableBatchUpdates': _enableBatchUpdates,
        'enableCompressionForLargeData': _enableCompressionForLargeData,
        'enableAnalytics': _enableAnalytics,
      },
      'security': {
        'enableEncryptionAtRest': _enableEncryptionAtRest,
        'requireReauthenticationForSensitiveOperations':
            _requireReauthenticationForSensitiveOperations,
        'sessionTimeout': _sessionTimeout.inMilliseconds,
      },
      'ui': {
        'enableProgressIndicators': _enableProgressIndicators,
        'enableErrorSnackbars': _enableErrorSnackbars,
        'snackbarDuration': _snackbarDuration.inMilliseconds,
      },
    };
  }

  /// Load configuration from a map
  void fromMap(Map<String, dynamic> map) {
    final cache = map['cache'] as Map<String, dynamic>?;
    if (cache != null) {
      _cacheExpiryDuration = Duration(
        milliseconds:
            (cache['expiryDuration'] as int?) ??
            _cacheExpiryDuration.inMilliseconds,
      );
      _maxCacheSize = (cache['maxCacheSize'] as int?) ?? _maxCacheSize;
      _enablePersistentCache =
          (cache['enablePersistentCache'] as bool?) ?? _enablePersistentCache;
    }

    final performance = map['performance'] as Map<String, dynamic>?;
    if (performance != null) {
      _enablePerformanceTracking =
          (performance['enableTracking'] as bool?) ??
          _enablePerformanceTracking;
      _slowOperationThreshold =
          (performance['slowOperationThreshold'] as int?) ??
          _slowOperationThreshold;
      _enableOptimisticUpdates =
          (performance['enableOptimisticUpdates'] as bool?) ??
          _enableOptimisticUpdates;
    }

    final network = map['network'] as Map<String, dynamic>?;
    if (network != null) {
      _networkTimeout = Duration(
        milliseconds:
            (network['timeout'] as int?) ?? _networkTimeout.inMilliseconds,
      );
      _maxRetryAttempts =
          (network['maxRetryAttempts'] as int?) ?? _maxRetryAttempts;
      _retryDelay = Duration(
        milliseconds:
            (network['retryDelay'] as int?) ?? _retryDelay.inMilliseconds,
      );
    }

    final features = map['features'] as Map<String, dynamic>?;
    if (features != null) {
      _enableRealtimeUpdates =
          (features['enableRealtimeUpdates'] as bool?) ??
          _enableRealtimeUpdates;
      _enableBatchUpdates =
          (features['enableBatchUpdates'] as bool?) ?? _enableBatchUpdates;
      _enableCompressionForLargeData =
          (features['enableCompressionForLargeData'] as bool?) ??
          _enableCompressionForLargeData;
      _enableAnalytics =
          (features['enableAnalytics'] as bool?) ?? _enableAnalytics;
    }

    final security = map['security'] as Map<String, dynamic>?;
    if (security != null) {
      _enableEncryptionAtRest =
          (security['enableEncryptionAtRest'] as bool?) ??
          _enableEncryptionAtRest;
      _requireReauthenticationForSensitiveOperations =
          (security['requireReauthenticationForSensitiveOperations']
              as bool?) ??
          _requireReauthenticationForSensitiveOperations;
      _sessionTimeout = Duration(
        milliseconds:
            (security['sessionTimeout'] as int?) ??
            _sessionTimeout.inMilliseconds,
      );
    }

    final ui = map['ui'] as Map<String, dynamic>?;
    if (ui != null) {
      _enableProgressIndicators =
          (ui['enableProgressIndicators'] as bool?) ??
          _enableProgressIndicators;
      _enableErrorSnackbars =
          (ui['enableErrorSnackbars'] as bool?) ?? _enableErrorSnackbars;
      _snackbarDuration = Duration(
        milliseconds:
            (ui['snackbarDuration'] as int?) ??
            _snackbarDuration.inMilliseconds,
      );
    }
  }

  /// Reset to default configuration
  void resetToDefaults() {
    _cacheExpiryDuration = const Duration(minutes: 5);
    _maxCacheSize = 100;
    _enablePersistentCache = true;
    _enablePerformanceTracking = kDebugMode;
    _slowOperationThreshold = 1000;
    _enableOptimisticUpdates = true;
    _networkTimeout = const Duration(seconds: 30);
    _maxRetryAttempts = 3;
    _retryDelay = const Duration(seconds: 2);
    _enableRealtimeUpdates = true;
    _enableBatchUpdates = true;
    _enableCompressionForLargeData = true;
    _enableAnalytics = true;
    _enableEncryptionAtRest = false;
    _requireReauthenticationForSensitiveOperations = true;
    _sessionTimeout = const Duration(hours: 24);
    _enableProgressIndicators = true;
    _enableErrorSnackbars = true;
    _snackbarDuration = const Duration(seconds: 4);
  }

  /// Configure for production environment
  void configureForProduction() {
    _enablePerformanceTracking = false;
    _enableAnalytics = true;
    _enableEncryptionAtRest = true;
    _requireReauthenticationForSensitiveOperations = true;
    _slowOperationThreshold = 2000;
    _maxRetryAttempts = 5;
  }

  /// Configure for development environment
  void configureForDevelopment() {
    _enablePerformanceTracking = true;
    _enableAnalytics = false;
    _enableEncryptionAtRest = false;
    _requireReauthenticationForSensitiveOperations = false;
    _slowOperationThreshold = 500;
    _maxRetryAttempts = 2;
  }

  /// Configure for testing environment
  void configureForTesting() {
    _enablePerformanceTracking = false;
    _enableAnalytics = false;
    _enableRealtimeUpdates = false;
    _enableEncryptionAtRest = false;
    _requireReauthenticationForSensitiveOperations = false;
    _cacheExpiryDuration = const Duration(seconds: 1);
    _networkTimeout = const Duration(seconds: 5);
    _maxRetryAttempts = 1;
  }
}
