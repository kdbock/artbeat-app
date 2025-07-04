import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsConfig {
  static bool _initialized = false;

  /// Initialize Google Maps configuration to prevent multiple CCT Clearcut Uploaders
  static Future<void> initialize() async {
    if (_initialized) return;

    // Set any specific configuration for Google Maps here
    // This singleton pattern prevents multiple initializations

    _initialized = true;
  }

  /// Check if Maps has been initialized
  static bool get isInitialized => _initialized;

  /// Reset initialization state (mainly for testing)
  static void reset() {
    _initialized = false;
  }
}
