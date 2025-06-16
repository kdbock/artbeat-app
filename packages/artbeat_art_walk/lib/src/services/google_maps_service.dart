import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  String? get _mapsApiKey => ConfigService.instance.googleMapsApiKey;

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

  /// Get the default map style JSON
  Future<String> get defaultMapStyle async {
    try {
      // Try to load from assets first
      final style = await rootBundle.loadString('assets/map_style.json');
      return style;
    } catch (e) {
      debugPrint('⚠️ Using fallback map style: $e');
      return _defaultMapStyleJson;
    }
  }

  /// Initialize Google Maps with secure configuration and retry logic
  Future<bool> initializeMaps() async {
    if (_mapsApiKey == null) {
      debugPrint('❌ Google Maps API key not found in configuration');
      return false;
    }

    if (_initialized) {
      debugPrint('🗺️ Google Maps already initialized');
      return true;
    }

    if (_initializing) {
      debugPrint('🗺️ Google Maps initialization already in progress');
      return false;
    }

    _initializing = true;

    while (_initRetryCount < _maxRetries) {
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          debugPrint('🗺️ Initializing Google Maps for Android...');

          final mapsImplementation = GoogleMapsFlutterAndroid();
          await mapsImplementation
              .initializeWithRenderer(AndroidMapRenderer.latest);

          _initialized = true;
          _initializing = false;
          return true;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          // iOS doesn't require runtime initialization
          _initialized = true;
          _initializing = false;
          return true;
        }

        debugPrint('❌ Unsupported platform for Google Maps');
        return false;
      } catch (e) {
        _initRetryCount++;
        if (_initRetryCount < _maxRetries) {
          debugPrint(
              '⚠️ Maps initialization attempt $_initRetryCount failed: $e');
          await Future.delayed(_retryDelay);
          continue;
        }
        debugPrint(
            '❌ Maps initialization failed after $_maxRetries attempts: $e');
        _initializing = false;
        return false;
      }
    }

    _initializing = false;
    return false;
  }

  /// Check if maps are initialized
  bool get isInitialized => _initialized;
}
