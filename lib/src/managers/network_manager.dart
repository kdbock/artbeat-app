import 'dart:async';
import 'dart:io';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manages network connectivity and Firebase connection health
class NetworkManager {
  factory NetworkManager() => _instance;
  NetworkManager._internal();
  static final NetworkManager _instance = NetworkManager._internal();

  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();
  Timer? _connectionTimer;
  bool _isConnected = true;
  bool _isInitialized = false;

  /// Stream of network connection status
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Initialize network monitoring
  void initialize() {
    if (!_isInitialized) {
      _startNetworkMonitoring();
      _isInitialized = true;
      if (kDebugMode) {
        AppLogger.network('🌐 NetworkManager initialized');
      }
    }
  }

  /// Dispose network monitoring
  void dispose() {
    _connectionTimer?.cancel();
    _connectionStreamController.close();
    _isInitialized = false;
    if (kDebugMode) {
      AppLogger.network('🌐 NetworkManager disposed');
    }
  }

  /// Start monitoring network connectivity
  void _startNetworkMonitoring() {
    // Check connection every 30 seconds
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnection();
    });

    // Initial check
    _checkConnection();
  }

  /// Check network and Firebase connection
  Future<void> _checkConnection() async {
    try {
      // Check internet connectivity
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Internet is available, now check Firebase
        await _checkFirebaseConnection();
      } else {
        _updateConnectionStatus(false, 'No internet connection');
      }
    } catch (e) {
      _updateConnectionStatus(false, 'Internet connection failed: $e');
    }
  }

  /// Check Firebase connection specifically
  Future<void> _checkFirebaseConnection() async {
    try {
      // Try to access Firestore
      await FirebaseFirestore.instance
          .collection('_health_check')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      _updateConnectionStatus(true, 'Connected');
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Firebase connection failed: $e');
      }

      // Try to re-enable network if it was disabled
      try {
        await FirebaseFirestore.instance.enableNetwork();
        _updateConnectionStatus(true, 'Reconnected');
      } catch (enableError) {
        _updateConnectionStatus(false, 'Firebase connection failed: $e');
      }
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(bool connected, String message) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionStreamController.add(connected);

      if (kDebugMode) {
        print(
          '🌐 Network status changed: ${connected ? "Connected" : "Disconnected"} - $message',
        );
      }
    }
  }

  /// Force a connection check
  Future<bool> checkConnectionNow() async {
    await _checkConnection();
    return _isConnected;
  }

  /// Try to reconnect to Firebase
  Future<bool> reconnectFirebase() async {
    try {
      if (kDebugMode) {
        AppLogger.firebase('🔄 Attempting to reconnect to Firebase...');
      }

      await FirebaseFirestore.instance.enableNetwork();
      await _checkFirebaseConnection();

      if (kDebugMode) {
        AppLogger.firebase('✅ Firebase reconnection successful');
      }

      return _isConnected;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Firebase reconnection failed: $e');
      }
      return false;
    }
  }
}

/// Widget to show network status
class NetworkStatusWidget extends StatefulWidget {

  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.showOfflineMessage = true,
  });
  final Widget child;
  final bool showOfflineMessage;

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  late StreamSubscription<bool> _connectionSubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    NetworkManager().initialize();
    _connectionSubscription = NetworkManager().connectionStream.listen((
      connected,
    ) {
      setState(() {
        _isConnected = connected;
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        widget.child,
        if (!_isConnected && widget.showOfflineMessage)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'No internet connection',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      NetworkManager().checkConnectionNow();
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
}
