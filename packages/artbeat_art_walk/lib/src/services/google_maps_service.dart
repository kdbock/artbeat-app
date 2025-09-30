import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:device_info_plus/device_info_plus.dart';

/// Service for handling Google Maps initialization and configuration
class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  factory GoogleMapsService() => _instance;
  GoogleMapsService._internal();

  bool _initialized = false;
  bool _initializing = false;
  int _initRetryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  bool _isEmulator = false;

  String? get _mapsApiKey => ConfigService.instance.googleMapsApiKey;

  // Reduced complexity map style that works better on emulators
  static const String _emulatorMapStyleJson = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    }
  ]
  ''';

  // Standard map style for physical devices
  static const String _defaultMapStyleJson = '''
  [
    {
      "featureType": "all",
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.stroke",
      "stylers": [{"lightness": -80}]
    }
  ]
  ''';

  /// Check if the device is running in an emulator
  Future<bool> _checkIfEmulator() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // Check various properties that indicate an emulator
        return androidInfo.isPhysicalDevice == false ||
            androidInfo.model.contains('sdk') ||
            androidInfo.model.contains('google_sdk') ||
            androidInfo.model.contains('emulator') ||
            androidInfo.model.contains('Android SDK');
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        // Check if it's a simulator
        return !iosInfo.isPhysicalDevice;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error checking if device is emulator: $e');
      return false; // Default to assuming it's not an emulator
    }
  }

  /// Get the appropriate map style JSON based on device type
  Future<String> get defaultMapStyle async {
    try {
      // First check if we have a custom style in assets
      try {
        final style = await rootBundle.loadString('assets/map_style.json');
        return style;
      } catch (e) {
        // Asset not found, use built-in styles
        _isEmulator = await _checkIfEmulator();
        if (_isEmulator) {
          AppLogger.debug('🔍 Using simplified map style for emulator');
          return _emulatorMapStyleJson;
        } else {
          return _defaultMapStyleJson;
        }
      }
    } catch (e) {
      AppLogger.error('⚠️ Error determining map style: $e');
      return _defaultMapStyleJson;
    }
  }

  /// Initialize Google Maps with secure configuration and retry logic
  Future<bool> initializeMaps() async {
    if (_mapsApiKey == null) {
      AppLogger.error('❌ Google Maps API key not found in configuration');
      return false;
    }

    debugPrint(
      '🔑 Google Maps API key found: ${_mapsApiKey!.substring(0, 20)}...',
    );
    AppLogger.info('🔑 API key length: ${_mapsApiKey!.length}');

    if (_initialized) {
      AppLogger.info('🗺️ Google Maps already initialized');
      return true;
    }

    if (_initializing) {
      AppLogger.info('🗺️ Google Maps initialization already in progress');
      return false;
    }

    _initializing = true;

    // Check if we're running in an emulator
    _isEmulator = await _checkIfEmulator();
    if (_isEmulator) {
      debugPrint(
        '🔍 Running in emulator environment - using optimized settings',
      );
    }

    while (_initRetryCount < _maxRetries) {
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          AppLogger.info('🗺️ Initializing Google Maps for Android...');

          final mapsImplementation = GoogleMapsFlutterAndroid();

          // Use a more compatible renderer for emulators
          final renderer = _isEmulator
              ? AndroidMapRenderer
                    .latest // Use latest renderer for all devices
              : AndroidMapRenderer.latest; // Better for physical devices

          AppLogger.info('🗺️ Using renderer: $renderer');
          await mapsImplementation.initializeWithRenderer(renderer);

          _initialized = true;
          _initializing = false;
          return true;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          // iOS doesn't require runtime initialization
          _initialized = true;
          _initializing = false;
          return true;
        }

        AppLogger.error('❌ Unsupported platform for Google Maps');
        return false;
      } catch (e) {
        _initRetryCount++;
        if (_initRetryCount < _maxRetries) {
          debugPrint(
            '⚠️ Maps initialization attempt $_initRetryCount failed: $e',
          );
          await Future<void>.delayed(_retryDelay);

          // If we've tried with the latest renderer and it failed, try with surface renderer
          if (_initRetryCount == 2 &&
              defaultTargetPlatform == TargetPlatform.android &&
              !_isEmulator) {
            AppLogger.warning(
              '⚠️ Falling back to surface renderer for stability',
            );
            try {
              final fallbackImplementation = GoogleMapsFlutterAndroid();
              await fallbackImplementation.initializeWithRenderer(
                AndroidMapRenderer.latest,
              );
              _initialized = true;
              _initializing = false;
              return true;
            } catch (fallbackError) {
              AppLogger.error('❌ Surface renderer also failed: $fallbackError');
            }
          }
          continue;
        }
        debugPrint(
          '❌ Maps initialization failed after $_maxRetries attempts: $e',
        );
        _initializing = false;
        return false;
      }
    }

    _initializing = false;
    return false;
  }

  /// Check if maps are initialized
  bool get isInitialized => _initialized;

  /// Check if running on emulator
  bool get isEmulator => _isEmulator;
}
