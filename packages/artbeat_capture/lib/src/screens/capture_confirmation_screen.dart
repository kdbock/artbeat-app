import 'dart:io';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/src/services/capture_service.dart';
import 'package:artbeat_capture/src/services/storage_service.dart';

/// Confirmation screen for reviewing and submitting a capture
class CaptureConfirmationScreen extends StatefulWidget {
  final File imageFile;
  final core.CaptureModel captureData;

  const CaptureConfirmationScreen({
    Key? key,
    required this.imageFile,
    required this.captureData,
  }) : super(key: key);

  @override
  State<CaptureConfirmationScreen> createState() =>
      _CaptureConfirmationScreenState();
}

class _CaptureConfirmationScreenState extends State<CaptureConfirmationScreen> {
  bool _isSubmitting = false;
  final CaptureService _captureService = CaptureService();
  final StorageService _storageService = StorageService();

  Future<void> _submitCapture() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload image first
      final imageUrl = await _storageService.uploadCaptureImage(
        widget.imageFile,
        widget.captureData.userId,
      );

      // Create capture with image URL
      final updatedCapture = widget.captureData.copyWith(imageUrl: imageUrl);

      // Save capture to database
      await _captureService.createCapture(updatedCapture);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capture submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to fluid dashboard screen after successful upload
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit capture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const core.EnhancedUniversalHeader(
        title: 'Review Capture',
        showLogo: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(widget.imageFile, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Title: ${widget.captureData.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.captureData.artistName != null)
              Text(
                'Artist: ${widget.captureData.artistName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (widget.captureData.description != null)
              Text(
                'Description: ${widget.captureData.description}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (widget.captureData.locationName != null)
              Text(
                'Location: ${widget.captureData.locationName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (widget.captureData.artType != null)
              Text(
                'Art Type: ${widget.captureData.artType}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (widget.captureData.artMedium != null)
              Text(
                'Art Medium: ${widget.captureData.artMedium}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCapture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: core.ArtbeatColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Submit', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
