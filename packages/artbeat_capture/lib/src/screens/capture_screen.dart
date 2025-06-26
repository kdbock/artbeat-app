import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtbeatColors;
import 'package:artbeat_core/src/utils/color_extensions.dart';
import '../services/camera_service.dart';
import 'capture_upload_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({Key? key}) : super(key: key);

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final CameraService _cameraService = CameraService();
  bool _isCameraAvailable = true;
  bool _isProcessing = false;
  bool _isCheckingCamera = true;

  @override
  void initState() {
    super.initState();
    // Start camera check immediately but don't show loading state
    _checkCameraAvailability();
  }

  Future<void> _checkCameraAvailability() async {
    try {
      final isAvailable = await _cameraService.isCameraAvailable();
      if (mounted) {
        setState(() {
          _isCameraAvailable = isAvailable;
          _isCheckingCamera = false;
        });

        // If camera is not available and we're on an emulator, show the dialog immediately
        if (!isAvailable) {
          // Small delay to ensure the widget is fully built
          Future<void>.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _showEmulatorDialog();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraAvailable = false;
          _isCheckingCamera = false;
        });

        // Show emulator dialog for any camera errors
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _showEmulatorDialog();
          }
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isProcessing = true;
    });

    // Check camera availability during the actual photo taking
    if (!_isCameraAvailable && !_isCheckingCamera) {
      setState(() {
        _isProcessing = false;
      });
      _showEmulatorDialog();
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      setState(() {
        _isProcessing = false;
      });

      if (photo != null) {
        final imageFile = File(photo.path);

        // Navigate to upload screen with the captured image
        if (mounted) {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (context) => CaptureUploadScreen(imageFile: imageFile),
            ),
          );

          // If upload was successful, return to previous screen
          if (result == true && mounted) {
            Navigator.of(context).pop(result);
          }
        }
      }
    } on PlatformException catch (e) {
      setState(() {
        _isProcessing = false;
      });

      String errorMessage = 'Failed to access camera';

      if (e.code == 'camera_access_denied') {
        errorMessage =
            'Camera access was denied. Please enable camera permissions in your device settings.';
      } else if (e.code == 'camera_access_denied_without_prompt') {
        errorMessage =
            'Camera access is permanently denied. Please enable camera permissions in your device settings.';
      } else if (e.code == 'camera_access_restricted') {
        errorMessage = 'Camera access is restricted on this device.';
      } else if (e.message?.toLowerCase().contains('not available') == true ||
          e.message?.toLowerCase().contains('no camera') == true) {
        errorMessage = 'Camera is not available on this device.';
        setState(() {
          _isCameraAvailable = false;
        });
        _showEmulatorDialog();
        return;
      }

      if (mounted) {
        _showErrorDialog('Camera Error', errorMessage);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        final errorMessage = 'An unexpected error occurred: ${e.toString()}';
        if (e.toString().toLowerCase().contains('not available') ||
            e.toString().toLowerCase().contains('no camera')) {
          setState(() {
            _isCameraAvailable = false;
          });
          _showEmulatorDialog();
          return;
        }
        _showErrorDialog('Camera Error', errorMessage);
      }
    }
  }

  void _showEmulatorDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Not Available'),
          content: const Text(
            'Camera is not available on this emulator. This is normal behavior for Android emulators.\n\n'
            'To test camera functionality:\n'
            '• Use a physical device, or\n'
            '• Select an image from the gallery instead\n\n'
            'On a real device, the camera will work normally.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickFromGallery();
              },
              child: const Text('Use Gallery'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (!_isCameraAvailable)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickFromGallery();
                },
                child: const Text('Use Gallery'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        final imageFile = File(photo.path);

        // Navigate to upload screen with the selected image
        if (mounted) {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (context) => CaptureUploadScreen(imageFile: imageFile),
            ),
          );

          // If upload was successful, return to previous screen
          if (result == true && mounted) {
            Navigator.of(context).pop(result);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Capture Art'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlphaValue(0.05),
              Colors.white,
              ArtbeatColors.primaryGreen.withAlphaValue(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Informational Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Important Guidelines',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Do not take photos on private property without permission\n'
                        '• No nudity or inappropriate content allowed\n'
                        '• No derogatory or offensive images\n'
                        '• All uploaded captures will be reviewed by moderators\n'
                        '• Focus on public art, murals, sculptures, and installations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 120,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Capture Public Art',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Take a photo of public art to share with the community',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Take Photo Button
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _takePhoto,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 24),
                        label: Text(
                          _isProcessing ? 'Opening Camera...' : 'Take Photo',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Camera unavailable message
                    if (!_isCameraAvailable && !_isCheckingCamera)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Camera not available on emulator. Use gallery or test on a real device.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Pick from Gallery Button
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library, size: 24),
                        label: const Text(
                          'From Gallery',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
