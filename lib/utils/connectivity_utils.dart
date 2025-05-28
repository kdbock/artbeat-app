import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectivityUtils {
  static final ConnectivityUtils _instance = ConnectivityUtils._internal();
  static ConnectivityUtils get instance => _instance;

  // Private constructor
  ConnectivityUtils._internal();

  final _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  Future<void> initialize() async {
    // Initialize Firestore for offline persistence
    await _configureFirestoreOfflineMode();

    // Get the current connectivity status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for future changes
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _configureFirestoreOfflineMode() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('✅ Firestore offline persistence configured successfully');
    } catch (e) {
      debugPrint('❌ Error configuring Firestore offline persistence: $e');
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // If no results or only 'none', we're offline
    bool isOffline = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);

    _controller.add(
        isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online);
  }

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    // We're online if we have any result that isn't 'none'
    return results.any((result) => result != ConnectivityResult.none);
  }

  static void showConnectivitySnackBar(
      BuildContext context, ConnectivityStatus status,
      {VoidCallback? onRetry}) {
    final snackBar = SnackBar(
      content: Text(
        status == ConnectivityStatus.offline
            ? 'You are offline. Some features may not be available.'
            : 'You are back online.',
      ),
      backgroundColor:
          status == ConnectivityStatus.offline ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
      action: status == ConnectivityStatus.offline && onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void dispose() {
    _controller.close();
  }
}

enum ConnectivityStatus { online, offline }

// Extension methods to make working with connectivity easier
extension ConnectivityStatusExtension on ConnectivityStatus {
  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
}
