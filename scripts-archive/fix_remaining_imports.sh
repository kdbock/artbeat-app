#!/bin/zsh

echo "Starting to fix remaining import issues..."

# Function to add missing semicolons to imports
fix_semicolons() {
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec grep -l "import 'package:artbeat_core/artbeat_core.dart'$" {} \; | while read -r file; do
    echo "Fixing missing semicolons in $file"
    sed -i '' "s|import 'package:artbeat_core/artbeat_core.dart'$|import 'package:artbeat_core/artbeat_core.dart';|g" "$file"
  done
}

# Function to fix conflicting UserService imports
fix_user_service_conflicts() {
  echo "Fixing UserService import conflicts in main.dart"
  
  # Create a UserService export in artbeat_core that others can import
  mkdir -p /Users/kristybock/artbeat/packages/artbeat_core/lib/src/exports
  cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/exports/user_service_export.dart << 'EOL'
// Export the user service as the main app's UserService
export '../services/user_service.dart';
EOL

  # Update artbeat_core.dart to export the proper service
  if ! grep -q "exports/user_service_export.dart" "/Users/kristybock/artbeat/packages/artbeat_core/lib/artbeat_core.dart"; then
    sed -i '' "/export 'src\/services\/services.dart';/a\\
export 'src\/exports\/user_service_export.dart';" "/Users/kristybock/artbeat/packages/artbeat_core/lib/artbeat_core.dart"
  fi
  
  # Remove duplicate UserService from calendar and capture modules
  find /Users/kristybock/artbeat/packages -path "*/src/services/user_service.dart" ! -path "*/artbeat_core/*" -type f -exec rm {} \;
  
  # Update imports in files that were using the duplicate UserService
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec grep -l "import '../services/user_service.dart';" {} \; | while read -r file; do
    echo "Updating UserService import in $file"
    sed -i '' "s|import '../services/user_service.dart';|import 'package:artbeat_core/artbeat_core.dart';|g" "$file"
  done
}

# Function to fix package locations for widgets and services
fix_package_locations() {
  echo "Moving widgets from incorrect locations to proper module locations"
  
  # Update imports that reference old file paths
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec grep -l "import 'package:artbeat/" {} \; | while read -r file; do
    echo "Fixing import references in $file"
    
    # Fix references to lib/widgets/
    sed -i '' "s|import 'package:artbeat/widgets/|import 'package:artbeat_core/src/widgets/|g" "$file"
    
    # Fix references to lib/services/
    sed -i '' "s|import 'package:artbeat/services/art_walk_service.dart';|import 'package:artbeat_art_walk/src/services/art_walk_service.dart';|g" "$file"
    sed -i '' "s|import 'package:artbeat/services/community_service.dart';|import 'package:artbeat_community/src/services/community_service.dart';|g" "$file"
    sed -i '' "s|import 'package:artbeat/services/commission_service.dart';|import 'package:artbeat_artist/src/services/commission_service.dart';|g" "$file"
    
    # Fix references to lib/data/
    sed -i '' "s|import 'package:artbeat/data/nc_zip_code_db.dart';|import 'package:artbeat_core/src/data/nc_zip_code_db.dart';|g" "$file"
    
    # Fix references to lib/screens/
    sed -i '' "s|import 'package:artbeat/screens/|import 'package:artbeat_core/src/screens/|g" "$file"
  done
  
  # Fix specific art_walk related imports
  find /Users/kristybock/artbeat/packages/artbeat_art_walk -name "*.dart" -type f -exec grep -l "art_walk_map_screen_fixed.dart" {} \; | while read -r file; do
    echo "Fixing art_walk_map_screen import in $file"
    sed -i '' "s|export 'art_walk_map_screen_fixed.dart';|export 'art_walk_map_screen.dart';|g" "$file"
    
    # Remove the fixed file to avoid conflicts
    if [ -f "/Users/kristybock/artbeat/packages/artbeat_art_walk/lib/src/screens/art_walk_map_screen_fixed.dart" ]; then
      rm "/Users/kristybock/artbeat/packages/artbeat_art_walk/lib/src/screens/art_walk_map_screen_fixed.dart"
    fi
  done
}

# Fix NC Region definitions to avoid duplication
fix_nc_region_models() {
  echo "Fixing NC Region model conflicts"
  
  # Create a proper NC models file if it doesn't exist
  mkdir -p /Users/kristybock/artbeat/packages/artbeat_core/lib/src/models
  if [ ! -f "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/models/nc_region_model.dart" ]; then
    cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/models/nc_region_model.dart << 'EOL'
class NCRegionModel {
  final String name;
  final List<String> counties;
  final int artworkCount;
  final int artistCount;
  final int eventCount;

  const NCRegionModel({
    required this.name, 
    required this.counties, 
    this.artworkCount = 0, 
    this.artistCount = 0,
    this.eventCount = 0,
  });
}
EOL
  fi
  
  # Create models.dart barrel file if it doesn't exist
  if [ ! -f "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/models/models.dart" ]; then
    cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/models/models.dart << 'EOL'
export 'nc_region_model.dart';
export 'user_model.dart';
EOL
  fi

  # Update the core exports
  if ! grep -q "export 'src/models/models.dart';" "/Users/kristybock/artbeat/packages/artbeat_core/lib/artbeat_core.dart"; then
    sed -i '' "/export 'src\/data\/data.dart';/a\\
export 'src\/models\/models.dart';" "/Users/kristybock/artbeat/packages/artbeat_core/lib/artbeat_core.dart"
  fi
}

# Fix the NC Zip Code Database implementation
fix_nc_zip_code_db() {
  echo "Enhancing NC Zip Code Database with missing methods"
  
  cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/data/nc_zip_code_db.dart << 'EOL'
// NC Zip Code Database

class NCZipCodeModel {
  final String zipCode;
  final String region;
  final String county;
  final double latitude;
  final double longitude;

  NCZipCodeModel({
    required this.zipCode,
    required this.region,
    required this.county,
    required this.latitude,
    required this.longitude,
  });
}

class NCRegionInfo {
  final String name;
  final String county;
  final List<String> cities;

  NCRegionInfo({
    required this.name,
    required this.county,
    required this.cities,
  });
}

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
  final Map<String, String> zipToRegion = {
    '28801': MOUNTAIN, '28806': MOUNTAIN, '28804': MOUNTAIN, // Asheville
    '27701': PIEDMONT, '27707': PIEDMONT, '27713': PIEDMONT, // Durham
    '27601': PIEDMONT, '27603': PIEDMONT, '27608': PIEDMONT, // Raleigh
    '28403': COASTAL, '28405': COASTAL, '28412': COASTAL, // Wilmington  
    // More zip codes would be added here
  };

  // Map regions to counties
  final Map<String, List<String>> regionToCounties = {
    MOUNTAIN: ['Buncombe', 'Henderson', 'Madison', 'Haywood', 'Transylvania'],
    PIEDMONT: ['Wake', 'Durham', 'Orange', 'Chatham', 'Guilford', 'Mecklenburg'],
    COASTAL: ['New Hanover', 'Brunswick', 'Pender', 'Onslow', 'Carteret'],
  };

  // Check if a zip code is in NC
  bool isNCZipCode(String zipCode) {
    return zipToRegion.containsKey(zipCode);
  }

  // Get region for a zip code
  String getRegionForZipCode(String zipCode) {
    return zipToRegion[zipCode] ?? 'Unknown';
  }

  // Get info for a zip code
  NCZipCodeModel getInfoForZipCode(String zipCode) {
    final region = getRegionForZipCode(zipCode);
    
    // Determine county based on zip code (simplified example)
    String county = 'Unknown';
    if (region == MOUNTAIN) {
      if (['28801', '28806', '28804'].contains(zipCode)) county = 'Buncombe';
    } else if (region == PIEDMONT) {
      if (['27701', '27707', '27713'].contains(zipCode)) county = 'Durham';
      if (['27601', '27603', '27608'].contains(zipCode)) county = 'Wake';
    } else if (region == COASTAL) {
      if (['28403', '28405', '28412'].contains(zipCode)) county = 'New Hanover';
    }
    
    // Determine lat/long (simplified example)
    double lat = 35.5951;
    double lng = -82.5515;
    
    return NCZipCodeModel(
      zipCode: zipCode,
      region: region,
      county: county,
      latitude: lat,
      longitude: lng,
    );
  }

  // Get zip codes for a region
  List<String> getZipCodesByRegion(String region) {
    return zipToRegion.entries
        .where((entry) => entry.value == region)
        .map((entry) => entry.key)
        .toList();
  }
  
  // Get region by name
  NCRegionInfo getRegionByName(String regionName) {
    if (!regionToCounties.containsKey(regionName)) {
      return NCRegionInfo(name: 'Unknown', county: 'Unknown', cities: []);
    }
    
    List<String> counties = regionToCounties[regionName] ?? [];
    
    // Example cities by region
    List<String> cities = [];
    if (regionName == MOUNTAIN) {
      cities = ['Asheville', 'Hendersonville', 'Black Mountain'];
    } else if (regionName == PIEDMONT) {
      cities = ['Raleigh', 'Durham', 'Chapel Hill', 'Charlotte'];
    } else if (regionName == COASTAL) {
      cities = ['Wilmington', 'Jacksonville', 'Morehead City'];
    }
    
    return NCRegionInfo(
      name: regionName,
      county: counties.isNotEmpty ? counties.first : 'Unknown',
      cities: cities,
    );
  }
  
  // Get all regions
  List<String> getAllRegions() {
    return [MOUNTAIN, PIEDMONT, COASTAL];
  }
}
EOL

  # Create a data.dart barrel file if it doesn't exist
  if [ ! -f "/Users/kristybock/artbeat/packages/artbeat_core/lib/src/data/data.dart" ]; then
    cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/data/data.dart << 'EOL'
export 'nc_zip_code_db.dart';
EOL
  fi
}

# Fix location utils with missing methods
fix_location_utils() {
  mkdir -p /Users/kristybock/artbeat/packages/artbeat_core/lib/src/utils
  cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/utils/location_utils.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationUtils {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getZipCodeFromGeoPoint(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        String postalCode = placemarks.first.postalCode ?? '';
        if (postalCode.isNotEmpty) {
          return postalCode;
        }
      }
      return '';
    } catch (e) {
      debugPrint('Error getting zip code from coordinates: $e');
      return '';
    }
  }

  static Future<String> getZipCodeFromCurrentPosition() async {
    try {
      Position position = await getCurrentPosition();
      return await getZipCodeFromGeoPoint(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current zip code: $e');
      return '';
    }
  }
  
  static Future<List<Placemark>> getAddressFromGeoPoint(double latitude, double longitude) async {
    return await placemarkFromCoordinates(latitude, longitude);
  }
}
EOL
}

# Fix connectivity service with missing functions
fix_connectivity_service() {
  mkdir -p /Users/kristybock/artbeat/packages/artbeat_core/lib/src/services
  cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/services/connectivity_service.dart << 'EOL'
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isInitialized = false;

  ConnectivityService() {
    _initConnectivity();
  }

  ConnectivityResult get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus != ConnectivityResult.none;
  bool get isInitialized => _isInitialized;

  Future<void> _initConnectivity() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _isInitialized = true;
      notifyListeners();
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e) {
      debugPrint('Connectivity initialization error: $e');
    }
  }

  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return ConnectivityResult.none;
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (_connectionStatus != result) {
      _connectionStatus = result;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
EOL
}

# Fix AppConfig implementation
fix_app_config() {
  cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/utils/app_config.dart << 'EOL'
class AppConfig {
  static final Map<String, String> _config = {
    'googleMapsApiKey': 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
    'stripePublishableKey': 'pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2',
    // Add other config values here
  };

  static bool _isUsingPlaceholders = false;
  
  static bool get isUsingPlaceholders => _isUsingPlaceholders;
  
  static String get googleMapsApiKey => _config['googleMapsApiKey'] ?? '';
  static String get stripePublishableKey => _config['stripePublishableKey'] ?? '';
  
  static String get(String key) {
    return _config[key] ?? '';
  }
  
  static void set(String key, String value) {
    _config[key] = value;
  }
  
  static void usePlaceholders(bool value) {
    _isUsingPlaceholders = value;
  }
}
EOL
}

# Fix core models and exports
create_core_models() {
  # Create UserModel
  mkdir -p /Users/kristybock/artbeat/packages/artbeat_core/lib/src/models
  cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/models/user_model.dart << 'EOL'
enum UserType {
  regular,
  artist,
  gallery,
  admin,
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? username;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? bio;
  final String? location;
  final String? zipCode;
  final UserType userType;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    this.profileImageUrl,
    this.coverImageUrl,
    this.bio,
    this.location,
    this.zipCode,
    this.userType = UserType.regular,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? lastActive,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'bio': bio,
      'location': location,
      'zipCode': zipCode,
      'userType': userType.index,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? map['name'] ?? '',
      username: map['username'],
      profileImageUrl: map['profileImageUrl'],
      coverImageUrl: map['coverImageUrl'],
      bio: map['bio'],
      location: map['location'],
      zipCode: map['zipCode'],
      userType: map['userType'] != null
          ? UserType.values[map['userType']]
          : UserType.regular,
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastActive: map['lastActive'] != null
          ? DateTime.parse(map['lastActive'])
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? email,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? coverImageUrl,
    String? bio,
    String? location,
    String? zipCode,
    UserType? userType,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      zipCode: zipCode ?? this.zipCode,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
EOL
}

# Create Firebase options
fix_firebase_options() {
  # Create Firebase options file
  mkdir -p /Users/kristybock/artbeat/packages/artbeat_core/lib
  cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/firebase_options.dart << 'EOL'
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
      appId: '1:665020451634:android:70aaba9b305fa17b78652b',
      messagingSenderId: '665020451634',
      projectId: 'wordnerd-artbeat',
      storageBucket: 'wordnerd-artbeat.appspot.com',
    );
  }
}
EOL
}

# Fix SubscriptionTier enum
fix_subscription_tier() {
  mkdir -p /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models
  cat > /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/subscription_model.dart << 'EOL'
enum SubscriptionTier {
  artistBasic,
  artistPro,
  gallery,
}

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  
  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.stripeSubscriptionId,
    this.stripePriceId,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripePriceId': stripePriceId,
    };
  }
  
  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] ?? '',
      tier: SubscriptionTier.values[map['tier'] ?? 0],
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : DateTime.now(),
      endDate: map['endDate'] != null 
          ? DateTime.parse(map['endDate']) 
          : null,
      isActive: map['isActive'] ?? false,
      stripeSubscriptionId: map['stripeSubscriptionId'],
      stripePriceId: map['stripePriceId'],
    );
  }
}
EOL

  # Create models.dart barrel file
  cat > /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/models.dart << 'EOL'
export 'subscription_model.dart';
EOL

  # Update the artist exports
  if ! grep -q "export 'src/models/models.dart';" "/Users/kristybock/artbeat/packages/artbeat_artist/lib/artbeat_artist.dart"; then
    sed -i '' "/export 'src\/screens\/screens.dart';/a\\
export 'src\/models\/models.dart';" "/Users/kristybock/artbeat/packages/artbeat_artist/lib/artbeat_artist.dart"
  fi
}

# Run the fixes
fix_semicolons
fix_user_service_conflicts
fix_package_locations
fix_nc_region_models
fix_nc_zip_code_db
fix_location_utils
fix_connectivity_service
fix_app_config
create_core_models
fix_firebase_options
fix_subscription_tier

# Run flutter pub get in each package
echo "Running flutter pub get in each package..."
for module in artbeat_core artbeat_auth artbeat_artist artbeat_artwork artbeat_art_walk artbeat_community artbeat_profile artbeat_settings artbeat_calendar artbeat_capture; do
  echo "Running flutter pub get in $module"
  (cd "/Users/kristybock/artbeat/packages/$module" && flutter pub get)
done

# Run flutter pub get in the main app
echo "Running flutter pub get in the main app..."
(cd "/Users/kristybock/artbeat" && flutter pub get)

echo "Remaining import fixes completed!"
