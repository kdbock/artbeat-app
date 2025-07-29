import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:intl/intl.dart';

/// Read-only screen for viewing all details of a captured artwork
class CaptureDetailScreen extends StatelessWidget {
  final core.CaptureModel capture;

  const CaptureDetailScreen({Key? key, required this.capture})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const core.EnhancedUniversalHeader(
        title: 'Capture Details',
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (capture.imageUrl.isNotEmpty)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    capture.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Title
            Text(
              capture.title ?? '(Untitled)',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Artist
            if (capture.artistName != null && capture.artistName!.isNotEmpty)
              _buildDetailRow('Artist', capture.artistName!),
            // Photographer (show userId as fallback)
            if (capture.userId.isNotEmpty)
              _buildDetailRow('Photographer (User ID)', capture.userId),
            // Art Type
            if (capture.artType != null && capture.artType!.isNotEmpty)
              _buildDetailRow('Art Type', capture.artType!),
            // Art Medium
            if (capture.artMedium != null && capture.artMedium!.isNotEmpty)
              _buildDetailRow('Medium', capture.artMedium!),
            // Description
            if (capture.description != null && capture.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  capture.description!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            // Location
            if (capture.locationName != null &&
                capture.locationName!.isNotEmpty)
              _buildDetailRow('Location', capture.locationName!),
            if (capture.location != null)
              _buildDetailRow(
                'Coordinates',
                'Lat: ${capture.location!.latitude.toStringAsFixed(5)}, Lng: ${capture.location!.longitude.toStringAsFixed(5)}',
              ),
            // Date
            _buildDetailRow(
              'Captured',
              DateFormat.yMMMd().add_jm().format(capture.createdAt),
            ),
            // Tags
            if (capture.tags != null && capture.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  children: capture.tags!
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              ),
            // Status
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(capture.status.toString().split('.').last),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
