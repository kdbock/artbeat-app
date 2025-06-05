import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/camera_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (_cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initializeCamera();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isProcessing) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to capture images')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final capture = await _cameraService.takePicture(user.uid);
      if (mounted) {
        Navigator.pop(context, capture);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraService.controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraService.controller!.value.aspectRatio,
              child: CameraPreview(_cameraService.controller!),
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
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Capture button
                  IconButton(
                    icon: const Icon(Icons.camera),
                    color: Colors.white,
                    iconSize: 72,
                    onPressed: _isProcessing ? null : _takePicture,
                  ),

                  // Switch camera button
                  IconButton(
                    icon: const Icon(Icons.switch_camera),
                    color: Colors.white,
                    onPressed: _isProcessing
                        ? null
                        : () => _cameraService.switchCamera(),
                  ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
