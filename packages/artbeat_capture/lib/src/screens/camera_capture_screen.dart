import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'capture_details_screen.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../services/capture_terms_service.dart';

class BasicCaptureScreen extends StatefulWidget {
  const BasicCaptureScreen({Key? key}) : super(key: key);

  @override
  State<BasicCaptureScreen> createState() => _BasicCaptureScreenState();
}

class _BasicCaptureScreenState extends State<BasicCaptureScreen> {
  File? _imageFile;
  bool _isProcessing = false;
  bool _hasAcceptedTerms = false;
  bool _showTerms = true;

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
        setState(() => _imageFile = File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        AppLogger.error('Camera capture failed: $e');

        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getCameraErrorMessage(e)),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _openCamera,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getCameraErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission')) {
      return 'Camera permission required. Please enable camera access in settings.';
    } else if (errorString.contains('camera not available') ||
        errorString.contains('no camera found')) {
      return 'Camera not available on this device.';
    } else if (errorString.contains('cancelled') ||
        errorString.contains('user_cancelled')) {
      return 'Camera capture was cancelled.';
    } else {
      return 'Unable to access camera. Please try again.';
    }
  }

  @override
  void initState() {
    super.initState();
    // Show terms modal first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _showTerms = true;
      });
    });
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _accept() {
    if (_imageFile != null) {
      Navigator.of(context).push(
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

  void _showTermsModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 32,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                        ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in,
                        size: 48,
                        color: ArtbeatColors.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Before You Capture',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please read and accept our guidelines to ensure safe and legal art capturing',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ArtbeatColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Safety Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Safety Guidelines',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '• Always be aware of your surroundings\n'
                        '• Do not trespass on private property\n'
                        '• Stay on public sidewalks and paths\n'
                        '• Be respectful of other people and property\n'
                        '• Use caution when crossing streets or navigating traffic\n'
                        '• Follow local laws and regulations',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Legal Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gavel,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Legal Guidelines',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '• Only capture art in public spaces\n'
                        '• No nudity or inappropriate content\n'
                        '• No derogatory or offensive images\n'
                        '• Respect artist copyrights and permissions\n'
                        '• All captures are subject to moderation\n'
                        '• Follow community guidelines and standards',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Art Walk Integration
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: ArtbeatColors.primaryGreen,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Community Contribution',
                            style: TextStyle(
                              color: ArtbeatColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your captures help build Art Walks for the community! '
                        'Each approved capture becomes part of curated routes that guide other users to discover '
                        'public art. Your contribution helps create a rich map of artistic discoveries.',
                        style: TextStyle(
                          color: ArtbeatColors.primaryGreen,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Acceptance Checkbox
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _hasAcceptedTerms,
                        onChanged: (bool? value) {
                          setState(() {
                            _hasAcceptedTerms = value ?? false;
                          });
                        },
                        activeColor: ArtbeatColors.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I have read and agree to all the safety guidelines, legal guidelines, and community standards listed above.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _showTerms = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _hasAcceptedTerms
                            ? () async {
                                // Save terms acceptance for future use
                                await CaptureTermsService.markTermsAccepted();

                                Navigator.of(context).pop();
                                setState(() {
                                  _showTerms = false;
                                  _openCamera();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Accept & Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show terms modal if needed
    if (_showTerms) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_showTerms) _showTermsModal();
      });
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_imageFile != null)
            Positioned.fill(child: Image.file(_imageFile!, fit: BoxFit.cover)),
          if (_imageFile == null && _isProcessing)
            const Center(child: CircularProgressIndicator()),
          // Top bar
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: _close,
            ),
          ),
          if (_imageFile != null)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.check, color: Colors.white, size: 32),
                onPressed: _accept,
              ),
            ),
          if (_imageFile != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                  ),
                  onPressed: _retake,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
