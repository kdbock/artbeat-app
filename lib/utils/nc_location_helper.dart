import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/models/nc_region_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat/utils/location_utils.dart';

/// Helper class for convenient access to NC location features
/// throughout the application
class NCLocationHelper {
  static final NCLocationHelper _instance = NCLocationHelper._internal();
  factory NCLocationHelper() => _instance;

  NCLocationHelper._internal();

  final NCZipCodeDatabase _db = NCZipCodeDatabase();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a user's location is in North Carolina
  Future<bool> isUserInNC() async {
    final zipCode = await _getCurrentUserZipCode();
    if (zipCode == null) return false;
    return _db.isNCZipCode(zipCode);
  }

  /// Get the region a user is located in
  Future<String?> getUserRegion() async {
    final zipCode = await _getCurrentUserZipCode();
    if (zipCode == null) return null;
    final info = _db.getInfoForZipCode(zipCode);
    return info?.region;
  }

  /// Get the county a user is located in
  Future<String?> getUserCounty() async {
    final zipCode = await _getCurrentUserZipCode();
    if (zipCode == null) return null;
    final info = _db.getInfoForZipCode(zipCode);
    return info?.county;
  }

  /// Get current user's ZIP code from Firestore
  Future<String?> _getCurrentUserZipCode() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists && userDoc.data()?['location'] != null) {
        return userDoc.data()?['location'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user location: $e');
      return null;
    }
  }

  /// Set the user's ZIP code in Firestore (used after location permission)
  Future<void> updateUserZipCode(String zipCode) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'location': zipCode,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user location: $e');
    }
  }

  /// Request location permission and get current ZIP code
  Future<String?> requestLocationAndGetZipCode(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return null;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      final zipCode = await LocationUtils.getZipCodeFromGeoPoint(
        GeoPoint(position.latitude, position.longitude),
      );

      if (zipCode != null) {
        // Update user's ZIP code in Firestore
        await updateUserZipCode(zipCode);
      }

      return zipCode;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return null;
    }
  }

  /// Determine if a location is in a specific region
  bool isZipCodeInRegion(String zipCode, String regionName) {
    final info = _db.getInfoForZipCode(zipCode);
    if (info == null) return false;
    return info.region.toLowerCase() == regionName.toLowerCase();
  }

  /// Get a human-readable description of the user's location
  Future<String> getUserLocationDescription() async {
    final zipCode = await _getCurrentUserZipCode();
    if (zipCode == null) return "Location unknown";

    final info = _db.getInfoForZipCode(zipCode);
    if (info == null) return "Location outside North Carolina";

    return "${info.county} in the ${info.region} region of North Carolina";
  }

  /// Get all regions for displaying in the UI
  List<NCRegionModel> getAllRegions() {
    return _db.getAllRegions();
  }

  /// Get a color for a specific region (for UI styling)
  Color getColorForRegion(String regionName) {
    final Map<String, Color> regionColors = {
      'Mountain': Colors.green.shade700,
      'Foothills': Colors.amber.shade800,
      'Piedmont': Colors.blue.shade700,
      'Sandhills': Colors.orange.shade700,
      'Coastal Plain': Colors.cyan.shade700,
      'Coastal': Colors.indigo.shade700,
    };

    return regionColors[regionName] ?? Colors.purple;
  }

  /// Get an icon for a specific region (for UI styling)
  IconData getIconForRegion(String regionName) {
    final Map<String, IconData> regionIcons = {
      'Mountain': Icons.terrain,
      'Foothills': Icons.landscape,
      'Piedmont': Icons.park,
      'Sandhills': Icons.waves,
      'Coastal Plain': Icons.grass,
      'Coastal': Icons.beach_access,
    };

    return regionIcons[regionName] ?? Icons.map;
  }

  /// Get ZIP codes for a region (for Firestore queries)
  List<String> getZipCodesForRegion(String regionName) {
    return _db.getZipCodesByRegion(regionName);
  }
}
