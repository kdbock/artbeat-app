import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'capture_details_screen.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Camera-only screen that immediately opens the camera
/// This is used after the user has already accepted terms and conditions
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({Key? key}) : super(key: key);

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  File? _imageFile;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Automatically open camera when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _isProcessing = false;
        });
      } else {
        // User cancelled camera, go back
        setState(() => _isProcessing = false);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _accept() {
    if (_imageFile != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => CaptureDetailsScreen(imageFile: _imageFile!),
        ),
      );
    }
  }

  void _retake() {
    setState(() => _imageFile = null);
    _openCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show captured image if available
          if (_imageFile != null)
            Positioned.fill(child: Image.file(_imageFile!, fit: BoxFit.cover)),

          // Show loading while processing
          if (_isProcessing)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Opening camera...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

          // Close button (always visible)
          Positioned(
            top: 50,
            left: 20,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: _close,
              ),
            ),
          ),

          // Accept button (only when image is captured)
          if (_imageFile != null)
            Positioned(
              top: 50,
              right: 20,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 32),
                  onPressed: _accept,
                ),
              ),
            ),

          // Retake button (only when image is captured)
          if (_imageFile != null)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Discard button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: _retake,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retake'),
                      ),

                      // Save button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primaryGreen
                              .withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: _accept,
                        icon: const Icon(Icons.check),
                        label: const Text('Save Image'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // If no image and not processing, show message
          if (_imageFile == null && !_isProcessing)
            const Center(
              child: Text(
                'Camera will open automatically',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
