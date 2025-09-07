import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A utility class to validate coordinates before using them with Google Maps
/// to prevent CoreGraphics NaN errors on iOS
class CoordinateValidator {
  /// Checks if a GeoPoint has valid coordinates
  static bool isValidGeoPoint(GeoPoint? point) {
    if (point == null) return false;
    return isValidLatitude(point.latitude) && isValidLongitude(point.longitude);
  }

  /// Checks if a latitude value is valid
  static bool isValidLatitude(double? lat) {
    if (lat == null) return false;
    return lat.isFinite && lat >= -90 && lat <= 90;
  }

  /// Checks if a longitude value is valid
  static bool isValidLongitude(double? lng) {
    if (lng == null) return false;
    return lng.isFinite && lng >= -180 && lng <= 180;
  }

  /// Checks if a SimpleLatLng position is valid
  static bool isValidLatLng(SimpleLatLng? position) {
    if (position == null) return false;
    return isValidLatitude(position.latitude) &&
        isValidLongitude(position.longitude);
  }

  /// Creates a default position for map center when coordinates are invalid
  static SimpleLatLng getDefaultLocation() {
    // Use a default location (San Francisco)
    return const SimpleLatLng(37.7749, -122.4194);
  }

  /// Logs a warning about invalid coordinates
  static void logInvalidCoordinates(String id, double? lat, double? lng) {
    debugPrint(
      '⚠️ Invalid coordinates detected for item $id: lat=$lat, lng=$lng',
    );
  }

  /// Safely creates a SimpleLatLng from a GeoPoint, with validation
  static SimpleLatLng? safeLatLngFromGeoPoint(
    GeoPoint? point, {
    String? itemId,
  }) {
    if (!isValidGeoPoint(point)) {
      if (itemId != null) {
        logInvalidCoordinates(itemId, point?.latitude, point?.longitude);
      }
      return null;
    }
    return SimpleLatLng(point!.latitude, point.longitude);
  }
}

/// Simple coordinate class for use in core logic (not tied to Google Maps)
class SimpleLatLng {
  final double latitude;
  final double longitude;
  const SimpleLatLng(this.latitude, this.longitude);
}
