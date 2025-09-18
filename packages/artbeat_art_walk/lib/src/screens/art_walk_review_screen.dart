import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/models.dart';
import '../constants/routes.dart';
import '../theme/art_walk_design_system.dart';

/// Review screen shown after creating an art walk, allows selfie upload before starting
class ArtWalkReviewScreen extends StatefulWidget {
  static const String routeName = '/art-walk/review';

  final String artWalkId;
  final ArtWalkModel artWalk;

  const ArtWalkReviewScreen({
    super.key,
    required this.artWalkId,
    required this.artWalk,
  });

  @override
  State<ArtWalkReviewScreen> createState() => _ArtWalkReviewScreenState();
}

class _ArtWalkReviewScreenState extends State<ArtWalkReviewScreen> {
  File? _selfieFile;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'Review Your Art Walk',
          showLogo: false,
          showBackButton: true,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              ArtWalkDesignSystem.primaryTeal,
              ArtWalkDesignSystem.accentOrange,
            ],
          ),
          titleGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              ArtWalkDesignSystem.primaryTeal,
              ArtWalkDesignSystem.accentOrange,
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtWalkDesignSystem.primaryTealLight,
                ArtWalkDesignSystem.accentOrangeLight,
                ArtWalkDesignSystem.backgroundGradientStart,
                ArtWalkDesignSystem.backgroundGradientEnd,
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWalkSummary(),
                const SizedBox(height: 24),
                _buildSelfieSection(),
                const SizedBox(height: 32),
                _buildStartWalkButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalkSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.artWalk.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.artWalk.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          _buildWalkStats(),
        ],
      ),
    );
  }

  Widget _buildWalkStats() {
    final artworkCount = widget.artWalk.artworkIds.length;
    final estimatedDistance = widget.artWalk.estimatedDistance ?? 0.0;
    final estimatedDuration = widget.artWalk.estimatedDuration ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.location_on,
                label: 'Starting Point',
                value: 'Current Location',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.flag,
                label: 'Stops',
                value: '$artworkCount Art Pieces',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${estimatedDistance.toStringAsFixed(1)} miles',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.schedule,
                label: 'Est. Time',
                value: '${(estimatedDuration / 60).round()} min',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          icon: Icons.home,
          label: 'End Destination',
          value: 'Back at Start',
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Capture Your Starting Moment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Take a selfie to mark the beginning of your art walk adventure!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          _buildSelfieUploadArea(),
        ],
      ),
    );
  }

  Widget _buildSelfieUploadArea() {
    return GestureDetector(
      onTap: _captureSelfie,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selfieFile != null
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _selfieFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _selfieFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_enhance,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to Take Selfie',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optional • Share your excitement!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStartWalkButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startArtWalk,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Start My Art Walk',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureSelfie() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null && mounted) {
        setState(() {
          _selfieFile = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error capturing selfie: $e')));
      }
    }
  }

  Future<void> _startArtWalk() async {
    try {
      // If user took a selfie, we could upload it here as a post
      // For now, we'll just navigate to the experience
      if (mounted) {
        Navigator.of(context).pushNamed(
          ArtWalkRoutes.experience,
          arguments: {'artWalkId': widget.artWalkId, 'artWalk': widget.artWalk},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting art walk: $e')));
      }
    }
  }
}
