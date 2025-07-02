import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  List<CameraDescription>? _cameras;
  bool? _isCameraAvailable;
  bool _isInitialized = false;

  /// Check if camera is available on the device
  Future<bool> isCameraAvailable() async {
    if (_isCameraAvailable != null) {
      return _isCameraAvailable!;
    }

    try {
      // For web platform, camera is generally not available for file operations
      if (kIsWeb) {
        _isCameraAvailable = false;
        return false;
      }

      // Check if running on emulator
      if (await _isRunningOnEmulator()) {
        debugPrint(
          'CameraService: Running on emulator, checking camera availability',
        );
      }

      // Try to get available cameras
      await _initializeCameras();

      _isCameraAvailable = _cameras != null && _cameras!.isNotEmpty;
      debugPrint('CameraService: Camera available: $_isCameraAvailable');

      return _isCameraAvailable!;
    } catch (e) {
      debugPrint('CameraService: Error checking camera availability: $e');
      _isCameraAvailable = false;
      return false;
    }
  }

  /// Initialize cameras list
  Future<void> _initializeCameras() async {
    if (_isInitialized) return;

    try {
      _cameras = await availableCameras();
      _isInitialized = true;
      debugPrint('CameraService: Found ${_cameras?.length ?? 0} cameras');
    } catch (e) {
      debugPrint('CameraService: Failed to initialize cameras: $e');
      _cameras = [];
      _isInitialized = true;
    }
  }

  /// Check if running on emulator
  Future<bool> _isRunningOnEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Common indicators of Android emulator
        return androidInfo.isPhysicalDevice == false ||
            androidInfo.model.toLowerCase().contains('emulator') ||
            androidInfo.model.toLowerCase().contains('sdk') ||
            androidInfo.fingerprint.contains('generic') ||
            androidInfo.fingerprint.contains('unknown') ||
            androidInfo.hardware.contains('goldfish') ||
            androidInfo.hardware.contains('ranchu') ||
            androidInfo.product.contains('sdk') ||
            androidInfo.product.contains('emulator');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.isPhysicalDevice == false;
      }

      return false;
    } catch (e) {
      debugPrint('CameraService: Error checking if emulator: $e');
      return false;
    }
  }

  /// Get available cameras
  List<CameraDescription>? get cameras => _cameras;

  /// Check if device has rear camera
  bool get hasRearCamera {
    if (_cameras == null) return false;
    return _cameras!.any(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
  }

  /// Check if device has front camera
  bool get hasFrontCamera {
    if (_cameras == null) return false;
    return _cameras!.any(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
  }

  /// Reset camera availability check (useful for testing)
  void reset() {
    _isCameraAvailable = null;
    _isInitialized = false;
    _cameras = null;
  }
}
