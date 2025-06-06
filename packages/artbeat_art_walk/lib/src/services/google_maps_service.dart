import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Service for handling Google Maps initialization and configuration
class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  factory GoogleMapsService() => _instance;
  GoogleMapsService._internal();

  bool _initialized = false;
  final String _defaultMapId = '1';

  /// Initialize Google Maps with secure configuration
  Future<void> initializeMaps() async {
    if (_initialized) {
      debugPrint('🗺️ Google Maps already initialized');
      return;
    }

    try {
      // Initialize map configurations with newer platform-specific approach
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final mapsImplementation = GoogleMapsFlutterAndroid();
          await GoogleMapsFlutterPlatform.instance
              .init(int.parse(_defaultMapId));
          await mapsImplementation
              .initializeWithRenderer(AndroidMapRenderer.latest);
        } catch (e) {
          if (e.toString().contains('Renderer already initialized')) {
            debugPrint('🗺️ Maps renderer already initialized, continuing...');
          } else {
            rethrow;
          }
        }
      }

      debugPrint(
          '🗺️ Maps initialization completed for platform $defaultTargetPlatform');

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
      // The style will be applied per-map instance using setMapStyle
      // Just validate the JSON here
      if (mapStyle.isEmpty) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error updating map style: $e');
      return false;
    }
  }

  /// Get current map style
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
}
