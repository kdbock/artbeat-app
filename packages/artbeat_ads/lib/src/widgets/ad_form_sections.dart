import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_type.dart';
import '../models/ad_location.dart';
import '../models/ad_display_type.dart';
import '../controllers/ad_form_controller.dart';
import 'ad_display_widget.dart';

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
  final List<XFile?> artworkImages;
  final VoidCallback onSelectImage;
  final void Function(int) onSelectArtwork;
  final void Function(int) onRemoveArtwork;

  const AdImageSection({
    super.key,
    required this.adType,
    this.selectedImage,
    required this.artworkImages,
    required this.onSelectImage,
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
                '2️⃣ Images - Upload up to 4 high-quality images for your ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Choose your best, most eye-catching images to showcase your content.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

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

/// Destination URL and CTA section
class AdDestinationSection extends StatelessWidget {
  final TextEditingController destinationUrlController;
  final TextEditingController ctaController;

  const AdDestinationSection({
    super.key,
    required this.destinationUrlController,
    required this.ctaController,
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
                '4️⃣ Destination & Action - Where should users go when they tap your ad?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Optional: Add a destination URL and call-to-action to drive traffic to your website, social media, or online store.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Destination URL field
            TextFormField(
              controller: destinationUrlController,
              decoration: const InputDecoration(
                labelText: 'Destination URL (Optional)',
                hintText:
                    'https://your-website.com or https://instagram.com/yourprofile',
                border: OutlineInputBorder(),
                helperText: 'Where users will go when they tap your ad',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Basic URL validation
                  final urlPattern = RegExp(
                    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
                  );
                  if (!urlPattern.hasMatch(value.trim())) {
                    return 'Please enter a valid URL (must start with http:// or https://)';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // CTA text field
            TextFormField(
              controller: ctaController,
              decoration: const InputDecoration(
                labelText: 'Call-to-Action Text (Optional)',
                hintText: 'Shop Now, Learn More, Visit Gallery, Follow Me',
                border: OutlineInputBorder(),
                helperText: 'Short text that encourages users to take action',
                prefixIcon: Icon(Icons.touch_app),
              ),
              maxLength: 20,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 2) {
                    return 'CTA text must be at least 2 characters';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 8),

            // Info container with examples
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Popular Examples:',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Artists: "View Portfolio", "Commission Me", "Follow"\n'
                    '• Galleries: "Visit Gallery", "Book Tour", "Learn More"\n'
                    '• Events: "Get Tickets", "RSVP", "Details"\n'
                    '• General: "Shop Now", "Discover", "Explore"',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
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
                '5️⃣ Pricing - Review your cost and submit',
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
    // Get artwork image paths for preview
    final artworkPaths = controller.artworkImages
        .where((image) => image != null)
        .map((image) => image!.path)
        .toList();

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
                '6️⃣ Preview - See how your ad will look with rotating images',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Use the actual AdDisplayWidget for preview
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 350),
                child: AdDisplayWidget(
                  imageUrl: artworkPaths.isNotEmpty ? artworkPaths.first : '',
                  artworkUrls: artworkPaths,
                  title: controller.titleController.text.isNotEmpty
                      ? controller.titleController.text
                      : 'Your Ad Title',
                  description: controller.descriptionController.text.isNotEmpty
                      ? controller.descriptionController.text
                      : 'Your ad description will appear here',
                  ctaText: controller.ctaController.text.isNotEmpty
                      ? controller.ctaController.text
                      : null,
                  displayType: controller.adType == AdType.square
                      ? AdDisplayType.square
                      : AdDisplayType.rectangle,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info text
            if (artworkPaths.length > 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✨ Your ad will rotate through ${artworkPaths.length} images every 3 seconds to catch viewers\' attention!',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (artworkPaths.length == 1)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 Add more images (up to 4) to create an eye-catching rotating effect!',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
