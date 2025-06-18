import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
  late TextEditingController _birthdayController;
  late String _gender;

  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

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
    _birthdayController = TextEditingController();
    _gender = 'Prefer not to say';
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _birthdayController.dispose();
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
            _usernameController.text = userModel.username ?? '';
            _emailController.text = userModel.email;
            _bioController.text = userModel.bio ?? '';
            _locationController.text = userModel.location ?? '';
            if (userModel.birthDate != null) {
              _birthdayController.text = DateFormat(
                'MM/dd/yyyy',
              ).format(userModel.birthDate!);
            }
            _gender = userModel.gender ?? 'Prefer not to say';
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

  // Parse birthday string to DateTime
  DateTime? _parseBirthday(String value) {
    try {
      return DateFormat('MM/dd/yyyy').parse(value);
    } catch (e) {
      debugPrint('Error parsing birth date: $e');
      return null;
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

      final DateTime? dateOfBirth = _birthdayController.text.isNotEmpty
          ? _parseBirthday(_birthdayController.text)
          : null;

      debugPrint(
        '🔧 Update data: {'
        'username: $username, '
        'bio: $bio, '
        'location: $location, '
        'birthDate: $dateOfBirth, '
        'gender: $_gender}',
      );

      // Update profile data
      await _userService.updateUserProfile(
        fullName: _nameController.text.trim(),
        bio: bio,
        location: location,
        gender: _gender,
      );
      debugPrint('✅ Firestore profile data updated');

      // Upload profile image if changed
      if (_profileImage != null) {
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

          await _userService.uploadAndUpdateProfilePhoto(_profileImage!);
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
    if (_profileImage != null) {
      return FileImage(_profileImage!);
    } else if (_userModel != null && _userModel!.profileImageUrl != null) {
      return NetworkImage(_userModel!.profileImageUrl!);
    } else if (currentUser?.photoURL != null) {
      return NetworkImage(currentUser!.photoURL!);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSubmit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          icon: Icon(Icons.person),
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
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          icon: Icon(Icons.description),
                          hintText: 'Tell us about yourself...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          icon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _birthdayController,
                        decoration: const InputDecoration(
                          labelText: 'Birthday',
                          icon: Icon(Icons.cake),
                          hintText: 'MM/DD/YYYY',
                        ),
                        keyboardType: TextInputType.datetime,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final date = _parseBirthday(value);
                            if (date == null) {
                              return 'Please enter a valid date in MM/DD/YYYY format';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          icon: Icon(Icons.person_outline),
                        ),
                        value: _gender,
                        items: _genders.map((String gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _gender = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
