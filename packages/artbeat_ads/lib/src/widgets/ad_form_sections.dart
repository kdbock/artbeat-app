import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_type.dart';
import '../models/ad_location.dart';
import '../controllers/ad_form_controller.dart';

/// Basic information section of the ad form
class AdBasicInfoSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final AdType adType;

  const AdBasicInfoSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.adType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BF63),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '1️⃣ Basic Information - Start with your ad details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title field
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Ad Title*',
                hintText:
                    'Create a catchy title (e.g., "Amazing Art Exhibition")',
                border: OutlineInputBorder(),
                helperText: 'Keep it short and compelling',
              ),
              maxLength: 60,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description*',
                hintText: 'Why should users be interested? Include key details',
                border: OutlineInputBorder(),
                helperText: 'Describe what makes your content special',
              ),
              maxLines: 3,
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Image selection section of the ad form
class AdImageSection extends StatelessWidget {
  final AdType adType;
  final XFile? selectedImage;
  final XFile? avatarImage;
  final List<XFile?> artworkImages;
  final VoidCallback onSelectImage;
  final VoidCallback onSelectAvatar;
  final void Function(int) onSelectArtwork;
  final void Function(int) onRemoveArtwork;

  const AdImageSection({
    super.key,
    required this.adType,
    this.selectedImage,
    this.avatarImage,
    required this.artworkImages,
    required this.onSelectImage,
    required this.onSelectAvatar,
    required this.onSelectArtwork,
    required this.onRemoveArtwork,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BF63),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '2️⃣ Images - Upload 4 high-quality images that will rotate as a GIF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Choose your best, most eye-catching images. They will automatically rotate to create an engaging animated effect.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            if (adType == AdType.artistApproved)
              _buildArtistApprovedImages(context)
            else
              _buildStandardImage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardImage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload 4 Images for Your Ad*'),
        const SizedBox(height: 8),
        const Text(
          'These images will rotate to create an animated GIF effect',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),

        // 2x2 grid of image slots
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final hasImage =
                index < artworkImages.length && artworkImages[index] != null;

            return GestureDetector(
              onTap: () => onSelectArtwork(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasImage ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(artworkImages[index]!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? Stack(
                        children: [
                          // Remove button
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemoveArtwork(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          // Image number badge
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Image ${index + 1}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),
        Text(
          'Upload at least 2 images (up to 4) for the best animated effect',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildArtistApprovedImages(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar image
        const Text('Avatar Image*'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onSelectAvatar,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: avatarImage != null ? Colors.green : Colors.grey[400]!,
                width: 2,
              ),
              image: avatarImage != null
                  ? DecorationImage(
                      image: FileImage(File(avatarImage!.path)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarImage == null
                ? Icon(Icons.add_a_photo, size: 32, color: Colors.grey[600])
                : null,
          ),
        ),

        const SizedBox(height: 24),

        // Artwork images
        const Text('Artwork Images* (4 required for animation)'),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final hasImage = artworkImages[index] != null;
            return GestureDetector(
              onTap: () => onSelectArtwork(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasImage ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(artworkImages[index]!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? Stack(
                        children: [
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemoveArtwork(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Colors.grey[600],
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Artwork ${index + 1}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Location and scheduling section
class AdLocationSection extends StatelessWidget {
  final AdLocation selectedLocation;
  final List<AdLocation> availableLocations;
  final int duration;
  final void Function(AdLocation) onLocationChanged;
  final void Function(int) onDurationChanged;

  const AdLocationSection({
    super.key,
    required this.selectedLocation,
    required this.availableLocations,
    required this.duration,
    required this.onLocationChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BF63),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '3️⃣ Placement & Duration - Choose where and how long your ad runs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location dropdown
            DropdownButtonFormField<AdLocation>(
              value: selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Ad Location*',
                hintText: 'Where should your ad appear?',
                border: OutlineInputBorder(),
                helperText: 'Dashboard = most views, Community = engagement',
              ),
              style: const TextStyle(color: Colors.black),
              items: availableLocations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(
                    _getLocationDisplayName(location),
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onLocationChanged(value);
              },
            ),

            const SizedBox(height: 16),

            // Duration slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration: $duration days',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Longer campaigns get better results. Most successful ads run for 7-14 days.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Slider(
                  value: duration.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: '$duration days',
                  onChanged: (value) => onDurationChanged(value.round()),
                ),
              ],
            ),

            Text(
              'Recommended: ${_getRecommendedDuration()} days for this location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocationDisplayName(AdLocation location) {
    switch (location) {
      case AdLocation.dashboard:
        return 'Main Dashboard';
      case AdLocation.artWalkDashboard:
        return 'Art Walk Dashboard';
      case AdLocation.captureDashboard:
        return 'Capture Dashboard';
      case AdLocation.communityDashboard:
        return 'Community Dashboard';
      case AdLocation.eventsDashboard:
        return 'Events Dashboard';
      case AdLocation.communityFeed:
        return 'Community Feed';
    }
  }

  String _getRecommendedDuration() {
    switch (selectedLocation) {
      case AdLocation.dashboard:
        return '7-14';
      case AdLocation.communityFeed:
        return '5-10';
      case AdLocation.artWalkDashboard:
        return '3-7';
      case AdLocation.captureDashboard:
        return '3-7';
      case AdLocation.communityDashboard:
        return '5-10';
      case AdLocation.eventsDashboard:
        return '3-7';
    }
  }
}

/// Artist approved ad specific section
class AdArtistApprovedSection extends StatelessWidget {
  final TextEditingController taglineController;
  final TextEditingController ctaController;
  final TextEditingController urlController;
  final int animationSpeed;
  final bool autoPlay;
  final void Function(int) onAnimationSpeedChanged;
  final void Function(bool) onAutoPlayChanged;

  const AdArtistApprovedSection({
    super.key,
    required this.taglineController,
    required this.ctaController,
    required this.urlController,
    required this.animationSpeed,
    required this.autoPlay,
    required this.onAnimationSpeedChanged,
    required this.onAutoPlayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BF63),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Artist Approved Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tagline
            TextFormField(
              controller: taglineController,
              decoration: const InputDecoration(
                labelText: 'Tagline',
                hintText: 'A catchy tagline for your ad',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),

            const SizedBox(height: 16),

            // Call to action
            TextFormField(
              controller: ctaController,
              decoration: const InputDecoration(
                labelText: 'Call to Action',
                hintText: 'e.g., "View Portfolio", "Visit Gallery"',
                border: OutlineInputBorder(),
              ),
              maxLength: 30,
            ),

            const SizedBox(height: 16),

            // Destination URL
            TextFormField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Destination URL',
                hintText: 'https://your-website.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 16),

            // Animation settings
            Text(
              'Animation Settings',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Animation speed
            Text('Animation Speed: ${animationSpeed}ms per image'),
            Slider(
              value: animationSpeed.toDouble(),
              min: 500,
              max: 3000,
              divisions: 10,
              label: '${animationSpeed}ms',
              onChanged: (value) => onAnimationSpeedChanged(value.round()),
            ),

            // Auto play toggle
            SwitchListTile(
              title: const Text('Auto Play Animation'),
              subtitle: const Text('Start animation automatically'),
              value: autoPlay,
              onChanged: onAutoPlayChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pricing information section
class AdPricingSection extends StatelessWidget {
  final double pricePerDay;
  final int duration;
  final double totalPrice;
  final String userType;
  final void Function(double)? onPriceChanged;

  const AdPricingSection({
    super.key,
    required this.pricePerDay,
    required this.duration,
    required this.totalPrice,
    required this.userType,
    this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BF63),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '4️⃣ Pricing - Review your cost and submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPricingHelpText(userType),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Price breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price per day:'),
                Text(
                  '\$${pricePerDay.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Duration: $duration days'),
                Text(
                  '\$${(pricePerDay * duration).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            // Admin price override
            if (userType == 'admin' && onPriceChanged != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: pricePerDay.toString(),
                decoration: const InputDecoration(
                  labelText: 'Custom Price per Day (Admin)',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null) onPriceChanged!(price);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPricingHelpText(String userType) {
    switch (userType) {
      case 'admin':
        return 'Admin ads are FREE! No charges will be applied.';
      case 'artist':
        return 'Affordable promotion for artists - just \$1 per day to showcase your work.';
      case 'gallery':
        return 'Professional gallery advertising - \$1 per day to promote exhibitions and events.';
      default:
        return 'Great value at \$1 per day - perfect for sharing your content with the community.';
    }
  }
}

/// Ad preview section
class AdPreviewSection extends StatelessWidget {
  final AdFormController controller;

  const AdPreviewSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview image
                  if (controller.selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(controller.selectedImage!.path),
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    controller.titleController.text.isNotEmpty
                        ? controller.titleController.text
                        : 'Your Ad Title',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    controller.descriptionController.text.isNotEmpty
                        ? controller.descriptionController.text
                        : 'Your ad description will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
