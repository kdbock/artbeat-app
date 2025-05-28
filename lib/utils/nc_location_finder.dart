import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/utils/location_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Helper class to find and filter artwork by NC location data
class NCLocationFinder {
  final NCZipCodeDatabase _db = NCZipCodeDatabase();

  /// Get the user's current location and determine if they're in NC
  Future<Map<String, dynamic>> getUserLocationContext() async {
    try {
      // Check if location permission is granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': false,
            'error': 'Location permissions are denied',
            'isInNC': false,
          };
        }
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Use the geocoding library to get the ZIP code
      final zipCode = await LocationUtils.getZipCodeFromGeoPoint(
        GeoPoint(position.latitude, position.longitude),
      );

      // Check if in NC
      bool isInNC = false;
      String? region;
      String? county;

      if (zipCode != null) {
        isInNC = _db.isNCZipCode(zipCode);
        if (isInNC) {
          final info = _db.getInfoForZipCode(zipCode);
          region = info?.region;
          county = info?.county;
        }
      }

      return {
        'success': true,
        'isInNC': isInNC,
        'zipCode': zipCode,
        'region': region,
        'county': county,
        'position': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'isInNC': false,
      };
    }
  }

  /// Filter Firestore query for artwork by NC region
  Query<Map<String, dynamic>> filterArtworkByRegion(
    Query<Map<String, dynamic>> baseQuery,
    String regionName,
  ) {
    final zipCodes = _db.getZipCodesByRegion(regionName);
    // For efficiency, we'll just use the first 10 ZIP codes
    // In a production app, you'd want to structure your data differently
    return baseQuery.where('location', whereIn: zipCodes.take(10).toList());
  }

  /// Get nearby art walks based on ZIP code
  Future<List<String>> getNearbyArtWalks(String zipCode) async {
    if (!_db.isNCZipCode(zipCode)) {
      return [];
    }

    final zipInfo = _db.getInfoForZipCode(zipCode);
    if (zipInfo == null) {
      return [];
    }

    // Get all ZIP codes in the region to find nearby art walks
    // In a real implementation, you'd query Firestore for art walks in these ZIP codes
    return _db.getZipCodesByRegion(zipInfo.region);
  }

  /// Get a human-readable description of the user's location context
  String getLocationDescription(String zipCode) {
    if (!_db.isNCZipCode(zipCode)) {
      return "Outside North Carolina";
    }

    final info = _db.getInfoForZipCode(zipCode);
    if (info != null) {
      return "${info.county} in the ${info.region} region of North Carolina";
    }

    return "North Carolina";
  }

  /// Group artwork by region
  Map<String, List<String>> groupArtworksByRegion(List<String> zipCodes) {
    final Map<String, List<String>> result = {};

    for (final zipCode in zipCodes) {
      final info = _db.getInfoForZipCode(zipCode);
      if (info != null) {
        final region = info.region;
        if (!result.containsKey(region)) {
          result[region] = [];
        }
        result[region]!.add(zipCode);
      }
    }

    return result;
  }
}
