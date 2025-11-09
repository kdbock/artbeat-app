import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.userId,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;

  File? _profileImage;
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isSaving = false;

  // References for efficiency
  final _userService = UserService();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Load user profile data
  Future<void> _loadUserProfile() async {
    try {
      final userModel = await _userService.getUserById(widget.userId);

      if (mounted) {
        setState(() {
          _userModel = userModel;
          if (userModel != null) {
            _nameController.text = userModel.fullName;
            _usernameController.text = userModel.username;
            _emailController.text = userModel.email;
            _bioController.text = userModel.bio;
            _locationController.text = userModel.location;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle profile image selection
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  // Handle form submission
  Future<void> _handleSubmit() async {
    AppLogger.debug('_handleSubmit called');
    if (!_formKey.currentState!.validate()) {
      AppLogger.debug('Form validation failed');
      return;
    }
    AppLogger.debug('Form validation passed, proceeding with save');

    setState(() {
      _isSaving = true;
    });

    try {
      // debugPrint('🔧 Updating Firestore profile data...');
      final String bio = _bioController.text.trim();
      final String location = _locationController.text.trim();

      // Update data logging removed for production

      // Update profile data
      await _userService.updateUserProfile(
        fullName: _nameController.text.trim(),
        bio: bio,
        location: location,
      );
      // debugPrint('✅ Firestore profile data updated');

      // Upload profile image if changed
      final profileImage = _profileImage;
      if (profileImage != null) {
        try {
          // debugPrint('🔧 Uploading profile image...');

          // Show upload indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Uploading profile image...'),
                duration: Duration(seconds: 1),
              ),
            );
          }

          await _userService.uploadAndUpdateProfilePhoto(profileImage);
          // debugPrint('✅ Profile image uploaded');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile_edit_image_success'.tr()),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // debugPrint('⚠️ Profile image upload failed: $e');

          if (e.toString().contains('object-not-found')) {
            // Storage path issue detected - file path configuration problem
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Storage issue: Please try again or contact support if the problem persists.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } else if (e.toString().contains('permission-denied')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Permission denied. Please check your account permissions.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to upload profile image: ${e.toString()}',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onProfileUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      // debugPrint('❌ Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Helper to get the right image provider for profile picture
  ImageProvider<Object>? _getProfileImageProvider() {
    final profileImage = _profileImage;
    if (profileImage != null) {
      return FileImage(profileImage);
    }

    final userModel = _userModel;
    final profileImageUrl = userModel?.profileImageUrl;
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      // Use ImageUtils for safe URL validation
      final networkImage = ImageUtils.safeNetworkImage(profileImageUrl);
      if (networkImage != null) {
        return networkImage;
      } else {
        AppLogger.warning(
          '⚠️ Invalid profile image URL format: $profileImageUrl',
        );
      }
    }

    final photoURL = currentUser?.photoURL;
    if (photoURL != null && photoURL.isNotEmpty) {
      // Use ImageUtils for safe URL validation
      final networkImage = ImageUtils.safeNetworkImage(photoURL);
      if (networkImage != null) {
        return networkImage;
      } else {
        AppLogger.warning('⚠️ Invalid photo URL format: $photoURL');
      }
    }
    return null;
  }

  // Helper to determine if placeholder icon should be shown
  bool _shouldShowProfilePlaceholder() {
    return _profileImage == null &&
        _userModel?.profileImageUrl == null &&
        currentUser?.photoURL == null;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'profile_edit_title'.tr(),
          showLogo: false,
          showBackButton: true,
        ),
        body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
                Colors.white,
                ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ArtbeatColors.primaryPurple,
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _getProfileImageProvider(),
                                    child: _shouldShowProfilePlaceholder()
                                        ? const Icon(Icons.person, size: 50)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: -10,
                                    right: -10,
                                    child: IconButton(
                                      icon: const Icon(Icons.add_a_photo),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Form fields
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                icon: const Icon(
                                  Icons.person,
                                  color: ArtbeatColors.primaryPurple,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: ArtbeatColors.primaryPurple,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _bioController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Bio',
                                icon: const Icon(
                                  Icons.description,
                                  color: ArtbeatColors.primaryPurple,
                                ),
                                hintText: 'Tell us about yourself...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: ArtbeatColors.primaryPurple,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: 'Location',
                                icon: const Icon(
                                  Icons.location_on,
                                  color: ArtbeatColors.primaryPurple,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: ArtbeatColors.primaryPurple,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ArtbeatButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        AppLogger.debug('Save button pressed');
                                        _handleSubmit();
                                      },
                                variant: ButtonVariant.primary,
                                child: _isSaving
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Saving...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Save Profile',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ), // Form
                    ), // Padding
                  ), // SingleChildScrollView
          ), // SafeArea
        ),
      ),
    );
  }
}
