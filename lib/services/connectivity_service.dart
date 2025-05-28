import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  // Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Stream controller for connectivity changes
  final _connectivityStreamController =
      StreamController<ConnectivityResult>.broadcast();

  // Current connectivity status
  ConnectivityResult _currentStatus = ConnectivityResult.none;

  // Getters
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityStreamController.stream;
  ConnectivityResult get currentStatus => _currentStatus;
  bool get isConnected => _currentStatus != ConnectivityResult.none;

  // Initialize the service and start listening to connectivity changes
  Future<void> initialize() async {
    // Check initial connectivity
    final results = await Connectivity().checkConnectivity();
    // Use the first result or default to none if empty
    _currentStatus =
        results.isNotEmpty ? results.first : ConnectivityResult.none;
    _connectivityStreamController.add(_currentStatus);

    // Listen for changes
    Connectivity().onConnectivityChanged.listen((results) {
      // Use the first result or default to none if empty
      _currentStatus =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _connectivityStreamController.add(_currentStatus);
    });
  }

  // Display a snackbar when connectivity changes
  static void showConnectivitySnackBar(
      BuildContext context, ConnectivityResult result) {
    final snackBar = SnackBar(
      content: Text(
        result == ConnectivityResult.none
            ? 'You are offline. Some features may not be available.'
            : 'You are back online.',
      ),
      backgroundColor:
          result == ConnectivityResult.none ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Dispose the stream controller
  void dispose() {
    _connectivityStreamController.close();
  }
}
