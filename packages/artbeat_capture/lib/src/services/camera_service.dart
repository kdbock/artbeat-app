import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:artbeat_capture/src/models/capture_model.dart';
import 'package:artbeat_capture/src/screens/capture_upload_screen.dart';
import 'storage_service.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage;

  CameraService()
    : _storage = kDebugMode ? DebugStorageService() : ReleaseStorageService();

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  // Initialize camera
  Future<void> initCamera() async {
    try {
      // Get camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available');

      // Initialize with lower resolution to reduce buffer usage
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, // Lowered from max to medium
        enableAudio: false,
      );

      await _controller?.initialize();
      _isInitialized = true;
      debugPrint('✅ Camera initialized successfully');
    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
      _isInitialized = false;
      throw CameraException(
        'initialization_failed',
        'Failed to initialize camera: $e',
      );
    }
  }

  // Take picture and process it
  Future<CaptureModel?> captureImage(
    String userId,
    BuildContext context,
  ) async {
    if (!_isInitialized || _controller == null) {
      throw CameraException('not_initialized', 'Camera not initialized');
    }

    // Verify authentication first
    if (!_isUserAuthenticated()) {
      throw CameraException('unauthorized', 'User not authenticated');
    }

    XFile? image;
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Check connectivity first
        if (!await _checkConnectivity()) {
          throw CameraException(
            'no_network',
            'No network connectivity available',
          );
        }

        // Take picture with timeout
        image = await _controller!.takePicture().timeout(
          const Duration(seconds: 10),
        );

        // Add a short delay to help release camera buffers
        await Future<void>.delayed(const Duration(milliseconds: 350));

        // Re-verify auth before upload
        if (!_isUserAuthenticated()) {
          throw CameraException('unauthorized', 'User authentication lost');
        }

        // Upload image using storage service
        final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final downloadUrl = await _storage.uploadImage(
          userId,
          File(image.path),
        );

        debugPrint('✅ Image uploaded successfully');

        // Create initial capture model
        final capture = CaptureModel(
          id: fileName,
          userId: userId,
          imageUrl: downloadUrl,
          createdAt: DateTime.now(),
        );

        // Show upload screen and wait for user input
        final NavigatorState navigator = Navigator.of(context);
        final CaptureModel? updatedCapture = await navigator.push(
          MaterialPageRoute<CaptureModel>(
            builder: (context) => CaptureUploadScreen(
              capture: capture,
              onUploadComplete: (updatedCapture) {
                navigator.pop(updatedCapture);
              },
            ),
          ),
        );

        return updatedCapture;
      } catch (e) {
        retryCount++;
        debugPrint('⚠️ Capture attempt $retryCount failed: $e');

        if (retryCount >= maxRetries) {
          debugPrint('❌ Max retries reached, failing');
          rethrow;
        }

        // Wait before retrying
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    throw CameraException('max_retries', 'Max retry attempts reached');
  }

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      return false;
    }
  }

  // Check if user is authenticated
  bool _isUserAuthenticated() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ User not authenticated');
      return false;
    }
    debugPrint('✅ User authenticated: ${user.uid}');
    return true;
  }

  bool _isDisposing = false;
  // Clean up resources
  void dispose() {
    if (_isDisposing) {
      debugPrint('CameraService: dispose called while already disposing');
      return;
    }
    _isDisposing = true;
    try {
      debugPrint('CameraService: Disposing camera controller');
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      debugPrint('CameraService: Disposed successfully');
    } catch (e) {
      debugPrint('CameraService: Error during dispose: $e');
    } finally {
      _isDisposing = false;
    }
  }
}
