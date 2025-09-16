import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/art_community_service.dart';
import '../services/firebase_storage_service.dart';
import '../models/art_models.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Artist onboarding screen to convert regular users to artists
class ArtistOnboardingScreen extends StatefulWidget {
  const ArtistOnboardingScreen({super.key});

  @override
  State<ArtistOnboardingScreen> createState() => _ArtistOnboardingScreenState();
}

class _ArtistOnboardingScreenState extends State<ArtistOnboardingScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _specialtiesController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();

  final ArtCommunityService _communityService = ArtCommunityService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  File? _profileImage;
  final List<File> _portfolioImages = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  int _currentStep = 0;

  final List<String> _availableSpecialties = [
    'Painting',
    'Drawing',
    'Sculpture',
    'Photography',
    'Digital Art',
    'Mixed Media',
    'Printmaking',
    'Ceramics',
    'Textile Art',
    'Street Art',
    'Illustration',
    'Graphic Design',
  ];

  final List<String> _selectedSpecialties = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _specialtiesController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Pre-fill display name with current user display name
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _displayNameController.text = user.displayName!;
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        if (_storageService.isValidFileSize(imageFile)) {
          setState(() {
            _profileImage = imageFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image must be under 5MB')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking profile image: $e')),
      );
    }
  }

  Future<void> _pickPortfolioImages() async {
    final ImagePicker picker = ImagePicker();

    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        limit: 10,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFiles.isNotEmpty) {
        final validFiles = <File>[];

        for (final file in pickedFiles) {
          final imageFile = File(file.path);

          if (_storageService.isValidFileSize(imageFile)) {
            validFiles.add(imageFile);
          }
        }

        setState(() {
          _portfolioImages.addAll(validFiles);
        });

        if (validFiles.length != pickedFiles.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Some images were too large and skipped (max 5MB each)',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking portfolio images: $e')),
      );
    }
  }

  void _removePortfolioImage(int index) {
    setState(() {
      _portfolioImages.removeAt(index);
    });
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (_selectedSpecialties.contains(specialty)) {
        _selectedSpecialties.remove(specialty);
      } else {
        _selectedSpecialties.add(specialty);
      }
    });
  }

  Future<void> _createArtistProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Display name is required')));
      return;
    }

    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one specialty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Upload profile image if selected
      String? profileImageUrl;
      if (_profileImage != null) {
        setState(() => _isUploadingImages = true);
        profileImageUrl = await _storageService.uploadProfileImage(
          _profileImage!,
          user.uid,
        );
        setState(() => _isUploadingImages = false);
      }

      // Upload portfolio images
      final List<String> portfolioImageUrls = [];
      if (_portfolioImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);

        for (final imageFile in _portfolioImages) {
          try {
            final url = await _storageService.uploadPortfolioImage(
              imageFile,
              user.uid,
            );
            portfolioImageUrls.add(url);
          } catch (e) {
            print('Failed to upload portfolio image: $e');
          }
        }

        setState(() => _isUploadingImages = false);
      }

      // Create artist profile
      final artistProfile = ArtistProfile(
        userId: user.uid,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: profileImageUrl ?? '',
        portfolioImages: portfolioImageUrls,
        specialties: _selectedSpecialties,
        isVerified: false,
        followersCount: 0,
        createdAt: DateTime.now(),
      );

      final success = await _communityService.updateArtistProfile(
        artistProfile,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to ARTbeat as an artist! 🎨'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create artist profile')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating artist profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become an Artist'),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Back', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _currentStep < 2 ? _nextStep : _createArtistProfile,
        onStepCancel: _currentStep > 0 ? _previousStep : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _isUploadingImages
                        ? null
                        : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading || _isUploadingImages
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(_currentStep < 2 ? 'Next' : 'Create Profile'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Basic Information
          Step(
            title: const Text('Basic Information'),
            subtitle: const Text('Tell us about yourself'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ArtbeatColors.surface,
                            border: Border.all(
                              color: ArtbeatColors.primaryPurple.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: ArtbeatColors.primaryPurple,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to add profile photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Display Name
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name *',
                    hintText: 'How you want to be known as an artist',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Bio
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about your art journey...',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Website
                TextField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    hintText: 'https://yourwebsite.com',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Instagram
                TextField(
                  controller: _instagramController,
                  decoration: const InputDecoration(
                    labelText: 'Instagram Handle',
                    hintText: '@yourhandle',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
          ),

          // Step 2: Specialties
          Step(
            title: const Text('Your Specialties'),
            subtitle: const Text('What type of art do you create?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select all that apply:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSpecialties.map((specialty) {
                    final isSelected = _selectedSpecialties.contains(specialty);
                    return FilterChip(
                      label: Text(specialty),
                      selected: isSelected,
                      onSelected: (_) => _toggleSpecialty(specialty),
                      selectedColor: ArtbeatColors.primaryPurple.withValues(
                        alpha: 0.2,
                      ),
                      checkmarkColor: ArtbeatColors.primaryPurple,
                    );
                  }).toList(),
                ),
                if (_selectedSpecialties.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Please select at least one specialty',
                      style: TextStyle(
                        color: ArtbeatColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),

          // Step 3: Portfolio
          Step(
            title: const Text('Portfolio'),
            subtitle: const Text('Showcase your artwork'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add up to 10 images of your artwork:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Portfolio Images
                if (_portfolioImages.isEmpty)
                  GestureDetector(
                    onTap: _pickPortfolioImages,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ArtbeatColors.textSecondary.withValues(
                            alpha: 0.3,
                          ),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: ArtbeatColors.surface,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: ArtbeatColors.primaryPurple,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Add portfolio images',
                            style: TextStyle(
                              fontSize: 16,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_portfolioImages.length}/10 images',
                            style: const TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (_portfolioImages.length < 10)
                            TextButton.icon(
                              onPressed: _pickPortfolioImages,
                              icon: const Icon(Icons.add),
                              label: const Text('Add More'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _portfolioImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_portfolioImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removePortfolioImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Completion Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.celebration,
                            color: ArtbeatColors.primaryPurple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Ready to join the artist community!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ArtbeatColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Once you create your profile, you\'ll be able to:\n'
                        '• Post as an artist with special badges\n'
                        '• Showcase your portfolio\n'
                        '• Connect with art lovers\n'
                        '• Receive commissions and opportunities',
                        style: TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
