import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/capture_model.dart';

class CaptureDetailScreen extends StatelessWidget {
  final CaptureModel capture;
  final bool isCurrentUser;

  const CaptureDetailScreen({
    super.key,
    required this.capture,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(capture.title ?? 'Capture Details'),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit screen
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'capture_${capture.id}',
                child: Image.network(
                  capture.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Privacy
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          capture.title ?? 'Untitled',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Icon(
                        capture.isPublic ? Icons.public : Icons.lock_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Artist Info
                  if (capture.artistName != null) ...[
                    Text(
                      'Artist',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capture.artistName!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Art Type and Medium
                  if (capture.artType != null || capture.artMedium != null) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        if (capture.artType != null)
                          Chip(label: Text(capture.artType!)),
                        if (capture.artMedium != null)
                          Chip(label: Text(capture.artMedium!)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (capture.description?.isNotEmpty == true) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capture.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (capture.tags?.isNotEmpty == true) ...[
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: capture.tags!
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Location
                  if (capture.location != null) ...[
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capture.locationName ?? 'View on map',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              capture.location!.latitude,
                              capture.location!.longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(capture.id),
                              position: LatLng(
                                capture.location!.latitude,
                                capture.location!.longitude,
                              ),
                            ),
                          },
                          liteModeEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
