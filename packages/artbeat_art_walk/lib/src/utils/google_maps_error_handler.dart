import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Helper class to handle Google Maps errors, especially in emulators
class GoogleMapsErrorHandler {
  /// Check if running on an emulator
  static Future<bool> isEmulator() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice == false ||
            androidInfo.model.contains('sdk') ||
            androidInfo.model.contains('emulator');
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking if device is emulator: $e');
      return false;
    }
  }

  /// Apply emulator optimizations to Google Map
  static Future<void> optimizeMapForEmulator(
    GoogleMapController controller,
  ) async {
    try {
      // Apply map style optimizations for emulators
      await controller.setMapStyle('''
      [
        {
          "featureType": "poi",
          "stylers": [{"visibility": "off"}]
        },
        {
          "featureType": "transit",
          "stylers": [{"visibility": "off"}]
        },
        {
          "featureType": "road",
          "elementType": "labels",
          "stylers": [{"visibility": "simplified"}]
        }
      ]
      ''');

      // Set a lower zoom level
      await controller.moveCamera(CameraUpdate.zoomTo(10));

      debugPrint('✅ Applied emulator optimizations to map');
    } catch (e) {
      debugPrint('❌ Failed to optimize map for emulator: $e');
    }
  }

  /// Handle map loading timeout
  static Future<void> handleMapTimeout(BuildContext context) async {
    final isRunningOnEmulator = await isEmulator();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRunningOnEmulator
              ? 'Map tile loading timeout. Emulator performance may be limited.'
              : 'Map loading timed out. Check your internet connection.',
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (context) => Navigator.of(context).widget as Widget,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Get optimized map options for emulators
  static GoogleMapOptions getOptimizedMapOptions() {
    return GoogleMapOptions(
      compassEnabled: false,
      mapToolbarEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}

/// Container for GoogleMap options
class GoogleMapOptions {
  final bool compassEnabled;
  final bool mapToolbarEnabled;
  final bool tiltGesturesEnabled;
  final bool zoomControlsEnabled;

  GoogleMapOptions({
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
    this.tiltGesturesEnabled = true,
    this.zoomControlsEnabled = true,
  });
}
