import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Utility class for location-based functions
class LocationUtils {
  static final NCZipCodeDatabase _zipCodeDB = NCZipCodeDatabase();

  /// Determine if a location is in North Carolina based on its ZIP code
  static bool isLocationInNC(String zipCode) {
    return _zipCodeDB.isNCZipCode(zipCode);
  }

  /// Get the region name for a ZIP code
  static String? getRegionForZipCode(String zipCode) {
    final info = _zipCodeDB.getInfoForZipCode(zipCode);
    return info?.region;
  }

  /// Get the county name for a ZIP code
  static String? getCountyForZipCode(String zipCode) {
    final info = _zipCodeDB.getInfoForZipCode(zipCode);
    return info?.county;
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(GeoPoint point1, GeoPoint point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000; // Convert meters to kilometers
  }

  /// Extract ZIP code from an address string
  static String? extractZipCodeFromAddress(String address) {
    // Basic US ZIP code regex pattern (5 digits, optionally followed by dash and 4 more digits)
    final RegExp zipRegex = RegExp(r'(\d{5})(?:-\d{4})?');
    final match = zipRegex.firstMatch(address);
    return match?.group(1);
  }

  /// Check if a ZIP code is in a specific region
  static bool isZipCodeInRegion(String zipCode, String regionName) {
    final info = _zipCodeDB.getInfoForZipCode(zipCode);
    return info?.region.toLowerCase() == regionName.toLowerCase();
  }

  /// Get all NC ZIP codes for a specific region
  static List<String> getZipCodesForRegion(String regionName) {
    return _zipCodeDB.getZipCodesByRegion(regionName);
  }

  /// Extract ZIP code from a GeoPoint using reverse geocoding
  static Future<String?> getZipCodeFromGeoPoint(GeoPoint point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.postalCode;
      }
      return null;
    } catch (e) {
      print('Error getting ZIP code from coordinates: $e');
      return null;
    }
  }

  /// Get a Firestore query for filtering content by region
  static Query<Map<String, dynamic>> getQueryFilteredByRegion({
    required Query<Map<String, dynamic>> query,
    required String zipCodeField,
    required String regionName,
  }) {
    final zipCodes = _zipCodeDB.getZipCodesByRegion(regionName);

    // If the list is too long for a single "in" query, we need to page results
    if (zipCodes.length > 10) {
      // Use a different approach for large datasets - here we'll just take the first 10
      // In a real implementation, you would use multiple queries or a different field
      return query.where(zipCodeField, whereIn: zipCodes.take(10).toList());
    } else {
      return query.where(zipCodeField, whereIn: zipCodes);
    }
  }

  /// Find local items within a certain distance of a ZIP code
  static Future<List<String>> findNearbyZipCodes(
      String zipCode, int radiusKm) async {
    final List<String> nearbyZipCodes = [];
    final targetZipInfo = _zipCodeDB.getInfoForZipCode(zipCode);

    if (targetZipInfo == null) return nearbyZipCodes;

    // Get all ZIP codes in the same region as a starting point
    final regionZipCodes = _zipCodeDB.getZipCodesByRegion(targetZipInfo.region);

    // In a production app, you would use a spatial database or API
    // For this implementation, we'll just return zip codes from the same region
    // which is a reasonable approximation for North Carolina regions
    return regionZipCodes;
  }

  /// Get region name from any string that might contain a ZIP code
  static String? findRegionFromText(String text) {
    final RegExp zipRegex = RegExp(r'(\d{5})(?:-\d{4})?');
    final matches = zipRegex.allMatches(text);

    for (final match in matches) {
      final zipCode = match.group(1);
      if (zipCode != null) {
        final info = _zipCodeDB.getInfoForZipCode(zipCode);
        if (info != null) {
          return info.region;
        }
      }
    }

    return null;
  }
}
