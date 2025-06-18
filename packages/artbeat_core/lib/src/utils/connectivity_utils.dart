// Connectivity utilities for the ARTbeat app

import '../services/connectivity_service.dart';

/// Utility class for network connectivity operations
class ConnectivityUtils {
  static final ConnectivityUtils _instance = ConnectivityUtils._internal();
  factory ConnectivityUtils() => _instance;

  ConnectivityUtils._internal();

  final ConnectivityService _connectivityService = ConnectivityService();

  /// Check if device has internet connectivity
  bool get hasInternetConnection => _connectivityService.isConnected;

  /// Check if the network connection is suitable for high-bandwidth operations
  bool isSuitableForHighBandwidthOperations() {
    if (!hasInternetConnection) return false;

    // Only allow high-bandwidth operations on WiFi or ethernet
    return _connectivityService.isConnectionFast();
  }

  /// Check if the network is suitable for uploading files
  bool isSuitableForUploading() {
    if (!hasInternetConnection) return false;

    // Only allow uploads on WiFi for better user experience
    return _connectivityService.connectionStatus == ConnectionStatus.wifi;
  }

  /// Check if the network is suitable for downloading files
  bool isSuitableForDownloading() {
    if (!hasInternetConnection) return false;

    // Only allow downloads on WiFi for better user experience
    return _connectivityService.connectionStatus == ConnectionStatus.wifi;
  }

  /// Get a human-readable connection type
  String getConnectionTypeName() {
    return _connectivityService.getConnectionType();
  }
}
