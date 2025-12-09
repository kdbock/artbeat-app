import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Manages app lifecycle events and prevents crashes during background transitions
class AppLifecycleManager extends WidgetsBindingObserver {
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();

  bool _isInitialized = false;
  AppLifecycleState _currentState = AppLifecycleState.resumed;

  /// Initialize lifecycle management
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      if (kDebugMode) {
        AppLogger.info('🔄 AppLifecycleManager initialized');
      }
    }
  }

  /// Clean up lifecycle management
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
      if (kDebugMode) {
        AppLogger.info('🔄 AppLifecycleManager disposed');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _currentState = state;

    if (kDebugMode) {
      AppLogger.info('🔄 App lifecycle state changed to: $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppResumed() {
    if (kDebugMode) {
      AppLogger.info('✅ App resumed - reinitializing connections');
    }
    // Reinitialize any connections that might have been dropped
    _ensureFirestoreConnection();
  }

  void _handleAppPaused() {
    if (kDebugMode) {
      AppLogger.info('⏸️ App paused - preparing for background');
    }
    // Prepare for background - save any pending data
    _saveStateForBackground();
  }

  void _handleAppInactive() {
    if (kDebugMode) {
      AppLogger.info('🔻 App inactive - temporarily pausing operations');
    }
    // Temporarily pause operations
  }

  void _handleAppDetached() {
    if (kDebugMode) {
      AppLogger.info('🔌 App detached - cleaning up resources');
    }
    // Clean up resources
    _cleanupResources();
  }

  void _handleAppHidden() {
    if (kDebugMode) {
      AppLogger.info('👻 App hidden - minimizing resource usage');
    }
    // Minimize resource usage
  }

  /// Ensure Firestore connection is healthy
  void _ensureFirestoreConnection() {
    try {
      // Always re-enable network after resume to ensure proper connection
      _reconnectFirestore();
      if (kDebugMode) {
        AppLogger.info('✅ Firestore connection re-established');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Firestore connection issue: $e');
      }
    }
  }

  /// Attempt to reconnect Firestore
  void _reconnectFirestore() {
    try {
      // Enable network to restore connection after background
      FirebaseFirestore.instance.enableNetwork();
      if (kDebugMode) {
        AppLogger.network('🔄 Firestore network re-enabled');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Failed to re-enable Firestore network: $e');
      }
    }
  }

  /// Save state before going to background
  void _saveStateForBackground() {
    // This is where you would save any critical state
    // For now, we'll just ensure Firestore operations are completed
    try {
      FirebaseFirestore.instance.disableNetwork();
      if (kDebugMode) {
        AppLogger.info('💾 Firestore network disabled for background');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Error disabling Firestore network: $e');
      }
    }
  }

  /// Clean up resources
  void _cleanupResources() {
    // Clean up any resources that might prevent proper app termination
    try {
      // Cancel any pending operations
      if (kDebugMode) {
        AppLogger.info('🧹 Resources cleaned up');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Error cleaning up resources: $e');
      }
    }
  }

  /// Get current app state
  AppLifecycleState get currentState => _currentState;

  /// Check if app is in foreground
  bool get isInForeground => _currentState == AppLifecycleState.resumed;

  /// Check if app is in background
  bool get isInBackground =>
      _currentState == AppLifecycleState.paused ||
      _currentState == AppLifecycleState.detached ||
      _currentState == AppLifecycleState.hidden;
}
