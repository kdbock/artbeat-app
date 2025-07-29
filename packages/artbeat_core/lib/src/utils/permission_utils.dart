import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for handling permissions consistently across the app
class PermissionUtils {
  /// Request photo library permission with proper error handling
  static Future<bool> requestPhotoPermission(BuildContext context) async {
    try {
      // Check current permission status
      PermissionStatus status = await Permission.photos.status;

      // If permission is denied, request it
      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      // Handle permanently denied permission
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Photo library access is permanently denied. Please enable it in your device settings to upload artwork.',
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }

      // Check if permission is granted (including limited access on iOS)
      if (status.isGranted || status.isLimited) {
        return true;
      }

      // Permission denied
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Photo library permission is required to upload artwork',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting photo permission: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request permission: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Request camera permission with proper error handling
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.camera.status;

      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Camera access is permanently denied. Please enable it in your device settings to capture artwork.',
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }

      if (status.isGranted) {
        return true;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to capture artwork'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request permission: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Request location permission with proper error handling
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.locationWhenInUse.status;

      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Location access is permanently denied. Please enable it in your device settings to discover nearby art.',
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }

      if (status.isGranted) {
        return true;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for this feature'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request permission: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Check if photo permission is granted without requesting
  static Future<bool> hasPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  /// Check if camera permission is granted without requesting
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if location permission is granted without requesting
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }
}
