import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart' show CaptureService;

class CaptureDetailScreen extends StatelessWidget {
  final String captureId;
  final CaptureModel? capture;
  final bool isCurrentUser;

  const CaptureDetailScreen({
    super.key,
    this.captureId = '',
    this.capture,
    this.isCurrentUser = false,
  }) : assert(
         captureId != '' || capture != null,
         'Either captureId or capture must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Details'),
      ),
      body: capture != null
          ? _buildCaptureDetails(context, capture!)
          : FutureBuilder<CaptureModel?>(
              future: CaptureService().getCaptureById(captureId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('Capture not found'));
                }
                return _buildCaptureDetails(context, snapshot.data!);
              },
            ),
    );
  }

  Widget _buildCaptureDetails(BuildContext context, CaptureModel capture) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: 'capture_${capture.id}',
              child: Image.network(
                capture.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(
                      child: Icon(Icons.error_outline, size: 48),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (capture.title != null) ...[
                  Text(
                    capture.title!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                ],
                if (capture.description != null) ...[
                  Text(
                    capture.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                ],
                if (capture.locationName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(capture.locationName!),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (capture.artistName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(capture.artistName!),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (capture.tags?.isNotEmpty ?? false) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: capture.tags!.map((tag) {
                      return Chip(label: Text(tag));
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
