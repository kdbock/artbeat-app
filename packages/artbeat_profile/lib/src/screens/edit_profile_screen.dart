import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import 'dart:io';

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
  // Add scaffold key for drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('🔧 Updating Firestore profile data...');
      final String username = _usernameController.text.trim();
      final String bio = _bioController.text.trim();
      final String location = _locationController.text.trim();

      debugPrint(
        '🔧 Update data: {'
        'username: $username, '
        'bio: $bio, '
        'location: $location}',
      );

      // Update profile data
      await _userService.updateUserProfile(
        fullName: _nameController.text.trim(),
        bio: bio,
        location: location,
      );
      debugPrint('✅ Firestore profile data updated');

      // Upload profile image if changed
      final profileImage = _profileImage;
      if (profileImage != null) {
        try {
          debugPrint('🔧 Uploading profile image...');

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
          debugPrint('✅ Profile image uploaded');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('⚠️ Profile image upload failed: $e');

          if (e.toString().contains('object-not-found')) {
            debugPrint(
              '📝 Storage path issue detected. This may be a file path configuration problem.',
            );
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
      debugPrint('❌ Error updating profile: $e');
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
    if (profileImageUrl != null) {
      return NetworkImage(profileImageUrl);
    }

    final photoURL = currentUser?.photoURL;
    if (photoURL != null) {
      return NetworkImage(photoURL);
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
        key: _scaffoldKey,
        appBar: EnhancedUniversalHeader(
          title: 'Edit Profile',
          showLogo: false,
          showDeveloperTools: true,
          onMenuPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _handleSubmit,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          ArtbeatColors.primaryPurple,
                        ),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: ArtbeatColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtbeatColors.primaryPurple,
                      ArtbeatColors.primaryGreen,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header content can be added here
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.home_outlined,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/');
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  title: const Text('Captures'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/captures');
                  },
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.map_outlined,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Art Walks'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/art-walks');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.people_outline,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Artist Community'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/community');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.front_hand,
                  color: ArtbeatColors.accentYellow,
                ),
                title: const Text('Fan of'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile/following');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.emoji_events_outlined,
                  color: ArtbeatColors.accentYellow,
                ),
                title: const Text('Achievements'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile/achievements');
                },
              ),
              const Divider(color: ArtbeatColors.border),
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: ArtbeatColors.primaryPurple,
                ),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              if (currentUser != null) ...[
                ListTile(
                  leading: const Icon(
                    Icons.dashboard_outlined,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  title: const Text('Artist Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/artist/dashboard');
                  },
                ),
              ],
            ],
          ),
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
                            const SizedBox(height: 24),

                            // Ad Space
                            const ProfileAdWidget(
                              showPlaceholder: true,
                              margin: EdgeInsets.symmetric(vertical: 16),
                            ),
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
