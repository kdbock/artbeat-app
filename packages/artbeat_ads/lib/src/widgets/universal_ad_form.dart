import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ad_form_controller.dart';
import '../models/ad_type.dart';
import '../models/ad_location.dart';
import 'ad_form_sections.dart';

/// Universal form widget for all ad creation types
/// Dynamically renders form fields based on ad type and user permissions
class UniversalAdForm extends StatelessWidget {
  final AdType initialAdType;
  final String userType;
  final List<AdLocation> availableLocations;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;

  const UniversalAdForm({
    super.key,
    required this.initialAdType,
    required this.userType,
    required this.availableLocations,
    this.onSubmit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdFormController>(
      builder: (context, controller, child) {
        return Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with progress indicator
              _buildHeader(context, controller),

              const SizedBox(height: 16),

              // Dynamic form sections based on ad type
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic information section
                      AdBasicInfoSection(
                        titleController: controller.titleController,
                        descriptionController: controller.descriptionController,
                        adType: controller.adType,
                      ),

                      const SizedBox(height: 24),

                      // Image selection section
                      AdImageSection(
                        adType: controller.adType,
                        selectedImage: controller.selectedImage,
                        avatarImage: controller.avatarImage,
                        artworkImages: controller.artworkImages,
                        onSelectImage: controller.selectImage,
                        onSelectAvatar: controller.selectAvatarImage,
                        onSelectArtwork: controller.selectArtworkImage,
                        onRemoveArtwork: controller.removeArtworkImage,
                      ),

                      const SizedBox(height: 24),

                      // Location and scheduling section
                      AdLocationSection(
                        selectedLocation: controller.adLocation,
                        availableLocations: availableLocations,
                        duration: controller.durationDays,
                        onLocationChanged: controller.setAdLocation,
                        onDurationChanged: controller.setDuration,
                      ),

                      const SizedBox(height: 24),

                      // Artist approved specific fields
                      if (controller.adType == AdType.artistApproved)
                        AdArtistApprovedSection(
                          taglineController: controller.taglineController,
                          ctaController: controller.ctaController,
                          urlController: controller.destinationUrlController,
                          animationSpeed: controller.animationSpeed,
                          autoPlay: controller.autoPlay,
                          onAnimationSpeedChanged: controller.setAnimationSpeed,
                          onAutoPlayChanged: controller.setAutoPlay,
                        ),

                      const SizedBox(height: 24),

                      // Pricing section
                      AdPricingSection(
                        pricePerDay: controller.pricePerDay,
                        duration: controller.durationDays,
                        totalPrice: controller.totalPrice,
                        userType: userType,
                        onPriceChanged: controller.setPricePerDay,
                      ),

                      const SizedBox(height: 24),

                      // Ad preview section
                      if (controller.hasSelectedImage)
                        AdPreviewSection(controller: controller),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Error display
              if (controller.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    controller.error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Action buttons
              _buildActionButtons(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AdFormController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getHeaderGradientColor(userType).withValues(alpha: 0.9),
            _getHeaderGradientColor(userType),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: _getHeaderGradientColor(userType).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section with user-friendly instructions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Your Ad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Follow the steps below to create your advertisement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Upload progress bar
          if (controller.isProcessing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creating your ad... ${_getProgressPercentage(controller.uploadProgress)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _getSafeProgress(controller.uploadProgress),
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AdFormController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: controller.isProcessing
                  ? null
                  : () {
                      if (onCancel != null) {
                        onCancel!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
              child: const Text('Cancel'),
            ),
          ),

          const SizedBox(width: 16),

          // Submit button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: controller.isProcessing
                  ? null
                  : () {
                      if (onSubmit != null) {
                        onSubmit!();
                      } else {
                        _handleSubmit(context, controller);
                      }
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Submit Ad (\$${controller.totalPrice.toStringAsFixed(2)})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    AdFormController controller,
  ) async {
    // This would be overridden by specific implementations
    // or handled by the parent widget through onSubmit callback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submit handler not implemented')),
    );
  }

  Color _getHeaderGradientColor(String userType) {
    switch (userType) {
      case 'artist':
        return const Color(0xFF6B73FF); // Purple-blue for artists
      case 'gallery':
        return const Color(0xFF00BF63); // Green for galleries
      case 'admin':
        return const Color(0xFFFF6B6B); // Red for admin
      case 'user':
      default:
        return const Color(0xFF4ECDC4); // Teal for users
    }
  }

  int _getProgressPercentage(double progress) {
    // Handle invalid values safely
    if (progress.isNaN || progress.isInfinite) {
      return 0;
    }
    // Clamp to valid range and convert to percentage
    final percentage = (progress * 100).clamp(0.0, 100.0);
    return percentage.toInt();
  }

  double _getSafeProgress(double progress) {
    // Handle invalid values safely for LinearProgressIndicator
    if (progress.isNaN || progress.isInfinite) {
      return 0.0;
    }
    // Clamp to valid range (0.0 to 1.0)
    return progress.clamp(0.0, 1.0);
  }
}
