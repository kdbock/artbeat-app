import 'dart:io';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Confirmation screen for reviewing and submitting a capture
class CaptureConfirmationScreen extends StatelessWidget {
  final File imageFile;
  final core.CaptureModel captureData;

  const CaptureConfirmationScreen({
    Key? key,
    required this.imageFile,
    required this.captureData,
  }) : super(key: key);

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
                child: Image.file(imageFile, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Title: ${captureData.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (captureData.artistName != null)
              Text(
                'Artist: ${captureData.artistName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (captureData.description != null)
              Text(
                'Description: ${captureData.description}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (captureData.locationName != null)
              Text(
                'Location: ${captureData.locationName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (captureData.artType != null)
              Text(
                'Art Type: ${captureData.artType}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (captureData.artMedium != null)
              Text(
                'Art Medium: ${captureData.artMedium}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement upload logic here
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Submit'),
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
