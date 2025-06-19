import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/camera_service.dart';

class CaptureScreen extends StatefulWidget {
  final Position? location;

  const CaptureScreen({super.key, this.location});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _isOpenGLError = false;
  bool _isDisposing = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('CaptureScreen: initState');
    _initializeCamera();
  }

  @override
  void dispose() {
    debugPrint('CaptureScreen: dispose called');
    WidgetsBinding.instance.removeObserver(this);
    _isDisposing = true;
    _cameraService.dispose(); // This is now async but we don't await in dispose
    super.dispose();
    debugPrint('CaptureScreen: dispose finished');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('CaptureScreen: didChangeAppLifecycleState $state');
    if (_cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      debugPrint('CaptureScreen: AppLifecycleState.inactive, disposing camera');
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint(
        'CaptureScreen: AppLifecycleState.resumed, scheduling camera re-initialization with delay',
      );
      // Add a delay to ensure camera is fully disposed before re-initializing
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_isDisposing && !_isInitializing) {
          debugPrint('CaptureScreen: Delayed re-initialization now running');
          _initializeCamera();
        } else {
          debugPrint(
            'CaptureScreen: Skipping delayed re-initialization (still disposing or initializing)',
          );
        }
      });
    } else if (state == AppLifecycleState.paused && Platform.isAndroid) {
      // On Android, explicitly release buffers when app goes to background
      _cameraService.releaseImageBuffers();
    }
  }

  // Initialize the camera with retry logic
  Future<void> _initializeCamera() async {
    if (_isInitializing || _isDisposing) {
      debugPrint(
        'CaptureScreen: Skipping _initializeCamera (already initializing or disposing)',
      );
      return;
    }

    _isInitializing = true;
    debugPrint('CaptureScreen: _initializeCamera started');

    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount < maxRetries) {
      try {
        setState(() {
          _errorMessage = null;
          _isCameraInitialized = false;
          _isOpenGLError = false;
        });

        // First make sure any previous camera instance is fully disposed
        await _cameraService.dispose();

        // Add a delay to ensure resources are fully released
        await Future<void>.delayed(const Duration(milliseconds: 300));

        debugPrint(
          'CaptureScreen: Initializing camera (attempt ${retryCount + 1})...',
        );
        await _cameraService.initCamera();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
        debugPrint('CaptureScreen: Camera initialized successfully');
        break; // Success, exit the retry loop
      } catch (e) {
        retryCount++;
        debugPrint('Error initializing camera (attempt $retryCount): $e');

        // If this is our last retry and it failed
        if (retryCount >= maxRetries && mounted) {
          setState(() {
            if (e.toString().contains('OpenGL') ||
                e.toString().contains('unimplemented')) {
              _isOpenGLError = true;
              _errorMessage =
                  'Camera preview is not supported on this device. '
                  'If you are using an emulator, try using a physical device instead.';
            } else {
              _errorMessage = 'Failed to initialize camera: $e';
            }
            _isCameraInitialized = false;
          });
        }

        // Wait before retrying
        if (retryCount < maxRetries) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    _isInitializing = false;
    debugPrint('CaptureScreen: _initializeCamera finished');
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isProcessing) return;

    final user = FirebaseAuth.instance.currentUser;
    debugPrint('CaptureScreen: currentUser = ${user?.uid ?? 'null'}');
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to capture images')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Release image buffers before capture (Android only)
      if (Platform.isAndroid) {
        await _cameraService.releaseImageBuffers();
      }

      final capture = await _cameraService.captureImage(user.uid, context);

      // Always dispose camera immediately after capture to release buffers
      await _cameraService.dispose();

      if (capture != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image captured and details saved!')),
        );
      }

      // Re-initialize camera after a short delay
      if (mounted && !_isDisposing) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isDisposing && !_isInitializing) {
            _initializeCamera();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));

        // On error, also try to re-initialize
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !_isDisposing && !_isInitializing) {
            _initializeCamera();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isOpenGLError ? Icons.warning : Icons.error_outline,
                size: 48,
                color: _isOpenGLError
                    ? Colors.orange
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _isOpenGLError ? 'Camera Not Supported' : 'Camera Error',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? 'Unknown camera error',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              if (!_isOpenGLError)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  onPressed: _initializeCamera,
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (!_isCameraInitialized || _cameraService.controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview with error handling
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  try {
                    return AspectRatio(
                      aspectRatio: _cameraService.controller!.value.aspectRatio,
                      child: CameraPreview(_cameraService.controller!),
                    );
                  } catch (e) {
                    if (mounted) {
                      // Handle OpenGL errors that occur during preview
                      Future.microtask(() {
                        setState(() {
                          _isOpenGLError = true;
                          _errorMessage =
                              'Camera preview is not supported on this device. '
                              'If you are using an emulator, try using a physical device instead.';
                        });
                      });
                    }
                    return Container(color: Colors.black);
                  }
                },
              ),
            ),

            // Controls overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.camera,
                        color: _isProcessing ? Colors.grey : Colors.white,
                        size: 36,
                      ),
                      onPressed: _isProcessing ? null : _takePicture,
                    ),
                    const SizedBox(width: 48), // Placeholder for symmetry
                  ],
                ),
              ),
            ),

            // Processing indicator
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
