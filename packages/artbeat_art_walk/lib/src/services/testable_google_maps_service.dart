import 'package:flutter/foundation.dart';

/// Interface for platform-specific maps implementation
abstract class IMapsImplementation {
  Future<void> initializeWithRenderer(String renderer);
}

/// Interface for maps platform
abstract class IGoogleMapsPlatform {
  Future<void> init(int mapId);
}

/// Testable service for handling Google Maps initialization and configuration
class TestableGoogleMapsService {
  final IGoogleMapsPlatform? _mapsPlatform;
  final IMapsImplementation? _mapsImplementation;
  final TargetPlatform _platform;

  bool _initialized = false;
  final String _defaultMapId = '1';
  String _currentMapStyle = '';

  TestableGoogleMapsService({
    IGoogleMapsPlatform? mapsPlatform,
    IMapsImplementation? mapsImplementation,
    TargetPlatform? platform,
  })  : _mapsPlatform = mapsPlatform,
        _mapsImplementation = mapsImplementation,
        _platform = platform ?? defaultTargetPlatform {
    _currentMapStyle = defaultMapStyle;
  }

  /// Initialize Google Maps with secure configuration
  Future<void> initializeMaps() async {
    if (_initialized) {
      debugPrint('🗺️ Google Maps already initialized');
      return;
    }

    try {
      // Initialize map configurations with newer platform-specific approach
      if (_platform == TargetPlatform.android) {
        try {
          if (_mapsPlatform != null && _mapsImplementation != null) {
            await _mapsPlatform!.init(int.parse(_defaultMapId));
            await _mapsImplementation!.initializeWithRenderer('latest');
          }
        } catch (e) {
          if (e.toString().contains('Renderer already initialized')) {
            debugPrint('🗺️ Maps renderer already initialized, continuing...');
          } else {
            rethrow;
          }
        }
      }

      debugPrint('🗺️ Maps initialization completed for platform $_platform');

      // Default map style customizations will be applied per-map instance
      await updateMapStyle(defaultMapStyle);

      _initialized = true;
      debugPrint('🗺️ Google Maps initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Google Maps: $e');
      rethrow;
    }
  }

  /// Update map style with custom JSON
  Future<bool> updateMapStyle(String mapStyle) async {
    try {
      if (mapStyle.isEmpty) {
        return false;
      }
      _currentMapStyle = mapStyle;
      return true;
    } catch (e) {
      debugPrint('❌ Error updating map style: $e');
      return false;
    }
  }

  /// Get current map style
  String get currentMapStyle => _currentMapStyle;

  /// Get default map style
  String get defaultMapStyle {
    // Light theme by default
    return '''[
      {
        "featureType": "landscape",
        "elementType": "all",
        "stylers": [{"color": "#f2f2f2"}]
      },
      {
        "featureType": "poi",
        "elementType": "all",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "elementType": "all", 
        "stylers": [{"visibility": "off"}]
      }
    ]''';
  }

  /// Check if maps are initialized
  bool get isInitialized => _initialized;

  /// Reset the initialization status (for testing)
  void resetInitialization() {
    _initialized = false;
  }
}
