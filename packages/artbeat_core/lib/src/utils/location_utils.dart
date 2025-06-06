import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coordinate_validator.dart' show SimpleLatLng;

class LocationUtils {
  static const String _zipCodeKey = 'user_zip_code';

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

  static Future<String> getZipCodeFromGeoPoint(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
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
      return getZipCodeFromGeoPoint(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current zip code: $e');
      return '';
    }
  }

  /// Check if coordinates are valid
  static bool isValidLatitude(double? latitude) {
    return latitude != null && latitude >= -90 && latitude <= 90;
  }

  static bool isValidLongitude(double? longitude) {
    return longitude != null && longitude >= -180 && longitude <= 180;
  }

  static bool isValidLatLng(SimpleLatLng coordinates) {
    return isValidLatitude(coordinates.latitude) &&
        isValidLongitude(coordinates.longitude);
  }

  /// Log invalid coordinates for debugging
  static void logInvalidCoordinates(String source, double? lat, double? lng) {
    debugPrint('❌ Invalid coordinates from $source: lat=$lat, lng=$lng');
  }

  static Future<String?> getStoredZipCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_zipCodeKey);
  }

  static Future<void> storeZipCode(String zipCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zipCodeKey, zipCode);
  }

  static Future<SimpleLatLng?> getCoordinatesFromZipCode(String zipCode) async {
    try {
      final locations = await locationFromAddress('$zipCode USA');
      if (locations.isNotEmpty) {
        return SimpleLatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates from ZIP code: $e');
      return null;
    }
  }

  // Use alias for backward compatibility
  static Future<String> getZipCodeFromCoordinates(
      double lat, double lng) async {
    return getZipCodeFromGeoPoint(lat, lng);
  }
}
