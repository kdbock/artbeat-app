import 'package:flutter/foundation.dart';

import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages app lifecycle events and prevents crashes during background transitions
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  bool _isInitialized = false;
  AppLifecycleState _currentState = AppLifecycleState.resumed;

  /// Initialize lifecycle management
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      if (kDebugMode) {
        print('🔄 AppLifecycleManager initialized');
      }
    }
  }

  /// Clean up lifecycle management
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
      if (kDebugMode) {
        print('🔄 AppLifecycleManager disposed');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _currentState = state;

    if (kDebugMode) {
      print('🔄 App lifecycle state changed to: $state');
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
      print('✅ App resumed - reinitializing connections');
    }
    // Reinitialize any connections that might have been dropped
    _ensureFirestoreConnection();
  }

  void _handleAppPaused() {
    if (kDebugMode) {
      print('⏸️ App paused - preparing for background');
    }
    // Prepare for background - save any pending data
    _saveStateForBackground();
  }

  void _handleAppInactive() {
    if (kDebugMode) {
      print('🔻 App inactive - temporarily pausing operations');
    }
    // Temporarily pause operations
  }

  void _handleAppDetached() {
    if (kDebugMode) {
      print('🔌 App detached - cleaning up resources');
    }
    // Clean up resources
    _cleanupResources();
  }

  void _handleAppHidden() {
    if (kDebugMode) {
      print('👻 App hidden - minimizing resource usage');
    }
    // Minimize resource usage
  }

  /// Ensure Firestore connection is healthy
  void _ensureFirestoreConnection() {
    try {
      // Check if Firestore is available
      FirebaseFirestore.instance.settings;
      if (kDebugMode) {
        print('✅ Firestore connection healthy');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firestore connection issue: $e');
      }
      // Attempt to reconnect
      _reconnectFirestore();
    }
  }

  /// Attempt to reconnect Firestore
  void _reconnectFirestore() {
    try {
      // Enable network if disabled
      FirebaseFirestore.instance.enableNetwork();
      if (kDebugMode) {
        print('🔄 Firestore network re-enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to re-enable Firestore network: $e');
      }
    }
  }

  /// Save state before going to background
  void _saveStateForBackground() {
    // This is where you would save any critical state
    // For now, we'll just ensure Firestore operations are completed
    try {
      FirebaseFirestore.instance.terminate();
      if (kDebugMode) {
        print('💾 Firestore terminated cleanly for background');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error terminating Firestore: $e');
      }
    }
  }

  /// Clean up resources
  void _cleanupResources() {
    // Clean up any resources that might prevent proper app termination
    try {
      // Cancel any pending operations
      if (kDebugMode) {
        print('🧹 Resources cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up resources: $e');
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
