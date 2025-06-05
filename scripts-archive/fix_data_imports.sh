#!/bin/zsh

echo "Creating data directory and NC zip code database in core package..."

# Create the data directory in the core package
mkdir -p "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/data"

# Create the NC zip code database file
cat > "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/data/nc_zip_code_db.dart" << 'EOL'
// NC Zip Code Database moved from the main app to the artbeat_core package

class NCZipCodeDatabase {
  // Singleton instance
  static final NCZipCodeDatabase _instance = NCZipCodeDatabase._internal();
  factory NCZipCodeDatabase() => _instance;
  NCZipCodeDatabase._internal();
  
  // Constants for regions
  static const String MOUNTAIN = 'Mountain';
  static const String PIEDMONT = 'Piedmont';
  static const String COASTAL = 'Coastal';
  
  // Map NC zip codes to regions
  Map<String, String> get zipToRegion => {
    '27006': PIEDMONT,
    '27007': PIEDMONT,
    '27009': PIEDMONT,
    // Add more zip codes here as needed
    '28801': MOUNTAIN, // Asheville
    '27601': PIEDMONT, // Raleigh
    '28403': COASTAL,  // Wilmington
  };
  
  // Get the region for a zip code
  String getRegionForZipCode(String zipCode) {
    return zipToRegion[zipCode] ?? 'Unknown';
  }
  
  // Get all zip codes for a region
  List<String> getZipCodesForRegion(String region) {
    return zipToRegion.entries
        .where((entry) => entry.value == region)
        .map((entry) => entry.key)
        .toList();
  }
}

// Model class for NC regions
class NCRegionModel {
  final String name;
  final List<String> counties;
  final List<String> zipCodes;
  
  NCRegionModel({
    required this.name, 
    required this.counties, 
    required this.zipCodes
  });
}
EOL

# Create an export file for the data directory
cat > "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/data/data.dart" << 'EOL'
// artbeat_core data export file
// Generated on $(date)

export 'nc_zip_code_db.dart';
EOL

# Create location utilities in the core package
cat > "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/utils/location_utils.dart" << 'EOL'
// Location utilities for the ARTbeat app

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationUtils {
  // Singleton instance
  static final LocationUtils _instance = LocationUtils._internal();
  factory LocationUtils() => _instance;
  static LocationUtils get instance => _instance;
  LocationUtils._internal();
  
  // Get the current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    
    return await Geolocator.getCurrentPosition();
  }
  
  // Get the zip code from a geo point
  Future<String?> getZipCodeFromGeoPoint(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude
      );
      
      if (placemarks.isNotEmpty) {
        return placemarks.first.postalCode;
      }
    } catch (e) {
      print('Error getting zip code: $e');
    }
    
    return null;
  }
}
EOL

# Create connectivity utilities in the core package
cat > "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/utils/connectivity_utils.dart" << 'EOL'
// Connectivity utilities for the ARTbeat app

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityUtils {
  // Singleton instance
  static final ConnectivityUtils _instance = ConnectivityUtils._internal();
  factory ConnectivityUtils() => _instance;
  static ConnectivityUtils get instance => _instance;
  ConnectivityUtils._internal();
  
  // Check if the device is connected to the internet
  Future<bool> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  // Stream of connectivity changes
  Stream<ConnectivityResult> get connectivityStream => 
      Connectivity().onConnectivityChanged;
}
EOL

# Create app config in the core package
cat > "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/utils/app_config.dart" << 'EOL'
// App configuration for the ARTbeat app

class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  static AppConfig get instance => _instance;
  AppConfig._internal();
  
  // API keys
  final String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  final String googleDirectionsApiKey = 'YOUR_GOOGLE_DIRECTIONS_API_KEY';
  
  // Feature flags
  bool get enableArtWalkFeature => true;
  bool get enableNotifications => true;
  bool get enableAnalytics => true;
  
  // App settings
  final String appName = 'ARTbeat';
  final String appVersion = '1.0.0';
  final String buildNumber = '1';
  
  // API endpoints
  final String apiBaseUrl = 'https://api.artbeat.com';
}
EOL

echo "Created data directory and NC zip code database in core package!"
