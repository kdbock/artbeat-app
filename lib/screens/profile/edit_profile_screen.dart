import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat/services/user_service.dart';
import 'package:artbeat/models/user_model.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

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

  String _gender = 'Prefer not to say';
  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  File? _profileImage;
  File? _coverImage;
  bool _isLoading = false;

  // Service and Firebase user
  final UserService _userService = UserService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _nameController = TextEditingController(
      text: currentUser?.displayName ?? '',
    );
    _usernameController = TextEditingController(
      text: 'wordnerd_user',
    ); // Placeholder
    _emailController = TextEditingController(text: currentUser?.email ?? '');
    _bioController = TextEditingController(
      text: 'Vocabulary enthusiast and language lover',
    ); // Placeholder
    _locationController = TextEditingController(
      text: 'United States',
    ); // Placeholder
    _birthdayController = TextEditingController(text: ''); // Placeholder

    // In a real app, fetch user data from Firestore
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch user data from Firestore
      final UserModel userModel = await _userService.getUserById(widget.userId);

      if (mounted) {
        setState(() {
          _nameController.text = userModel.fullName;
          _usernameController.text = userModel.username;
          _emailController.text = userModel.email;
          _bioController.text = userModel.bio;
          _locationController.text = userModel.location;
          _birthdayController.text = userModel.birthDate != null
              ? '${userModel.birthDate!.month}/${userModel.birthDate!.day}/${userModel.birthDate!.year}'
              : '';
          _gender = _genders.contains(userModel.gender)
              ? userModel.gender
              : 'Prefer not to say';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show loading indicator while picking image
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 90,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (image != null && mounted) {
        setState(() {
          _profileImage = File(image.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Profile image selected. Save your profile to upload.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show loading indicator while picking image
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (image != null && mounted) {
        setState(() {
          _coverImage = File(image.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Cover image selected. Save your profile to upload.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Update Firebase Auth display name
        if (currentUser != null &&
            currentUser!.displayName != _nameController.text.trim()) {
          await _userService.updateDisplayName(_nameController.text.trim());
        }

        // Update user profile data in Firestore
        await _userService.updateUserProfile(
          userId: widget.userId,
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          birthDate: _birthdayController.text.trim().isNotEmpty
              ? _parseBirthDate(_birthdayController.text.trim())
              : null,
          gender: _gender,
        );

        // Upload profile image if changed
        if (_profileImage != null) {
          await _userService.uploadAndUpdateProfilePhoto(_profileImage!);
        }

        // Upload cover image if changed
        if (_coverImage != null) {
          await _userService.uploadAndUpdateCoverPhoto(_coverImage!);
        }

        // Check if user should be transitioned to artist profile creation
        await _checkForArtistProfileTransition();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Helper method to parse birth date string (MM/DD/YYYY) to DateTime
  DateTime? _parseBirthDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]);
        final day = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (month != null && day != null && year != null) {
          return DateTime(year, month, day);
        }
      }
      return null;
    } catch (e) {
      // Use debugPrint instead of print for production code
      debugPrint('Error parsing birth date: $e');
      return null;
    }
  }

  Future<void> _checkForArtistProfileTransition() async {
    try {
      // Check if user has filled out profile information that suggests they're an artist
      final bio = _bioController.text.toLowerCase();
      final location = _locationController.text.trim();
      final username = _usernameController.text.toLowerCase();

      // Check for artistic keywords and professional indicators
      final hasArtistKeywords = bio.contains('artist') ||
          bio.contains('gallery') ||
          bio.contains('curator') ||
          bio.contains('exhibition') ||
          bio.contains('artwork') ||
          bio.contains('painting') ||
          bio.contains('sculpture') ||
          bio.contains('photography') ||
          bio.contains('creative') ||
          bio.contains('designer') ||
          bio.contains('illustrator') ||
          bio.contains('studio') ||
          bio.contains('portfolio');

      // Check for professional website indicators
      final hasWebsiteIndicators = username.contains('.') ||
          bio.contains('website') ||
          bio.contains('portfolio') ||
          bio.contains('etsy') ||
          bio.contains('instagram') ||
          bio.contains('artstation');

      // Check for detailed professional profile
      final hasDetailedProfile = location.isNotEmpty && bio.length > 50;

      final hasArtistIndicators =
          hasArtistKeywords || hasWebsiteIndicators || hasDetailedProfile;

      if (hasArtistIndicators && mounted) {
        // Show dialog asking if they want to create an artist profile
        final shouldCreateArtistProfile = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Create Artist Profile?'),
              content: const Text(
                  'Based on your profile information, it looks like you might be an artist or gallery. '
                  'Would you like to create an artist profile to access additional features like '
                  'artwork uploads, analytics, and subscription options?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create Artist Profile'),
                ),
              ],
            );
          },
        );

        if (shouldCreateArtistProfile == true && mounted) {
          // Navigate to artist profile creation
          Navigator.of(context).pushNamed('/artist/create-profile');
        }
      }
    } catch (e) {
      // Silently handle errors in artist profile transition check
      debugPrint('Error checking for artist profile transition: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile & Cover Photos
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover photo
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        image: _coverImage != null
                            ? DecorationImage(
                                image: FileImage(_coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          color: Colors.white,
                          onPressed: _pickCoverImage,
                        ),
                      ),
                    ),

                    // Profile photo
                    Positioned(
                      left: 20,
                      bottom: -40,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!) as ImageProvider
                                : (currentUser?.photoURL != null &&
                                        currentUser!.photoURL!.isNotEmpty
                                    ? NetworkImage(currentUser!.photoURL!)
                                    : null),
                            child: (_profileImage == null &&
                                    (currentUser?.photoURL == null ||
                                        currentUser!.photoURL!.isEmpty))
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 15),
                                color: Colors.white,
                                onPressed: _pickProfileImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // Form fields
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Name must be less than 50 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email),
                    helperText: 'This will be your unique identifier',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (value.trim().length > 30) {
                      return 'Username must be less than 30 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value.trim())) {
                      return 'Username can only contain letters, numbers, dots, and underscores';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    helperText: 'Email cannot be changed here',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  readOnly:
                      true, // Email should be changed through a separate flow
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    hintText:
                        'Tell us about yourself, your interests, or your art',
                    prefixIcon: Icon(Icons.info_outline),
                    counterText: '', // Hide character counter
                  ),
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) {
                    if (value != null && value.length > 500) {
                      return 'Bio must be less than 500 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                    hintText: 'City, State or Country',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().length > 100) {
                      return 'Location must be less than 100 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _birthdayController,
                  decoration: const InputDecoration(
                    labelText: 'Birthday',
                    border: OutlineInputBorder(),
                    hintText: 'Tap to select date',
                    prefixIcon: Icon(Icons.cake),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final birthDate = _parseBirthDate(value);
                      if (birthDate == null) {
                        return 'Invalid date format';
                      }
                      final age =
                          DateTime.now().difference(birthDate).inDays / 365;
                      if (age < 13) {
                        return 'You must be at least 13 years old';
                      }
                      if (age > 120) {
                        return 'Please enter a valid birth date';
                      }
                    }
                    return null;
                  },
                  onTap: () async {
                    // Show date picker
                    if (mounted) {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(
                          const Duration(days: 365 * 18),
                        ), // Default to 18 years ago
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _birthdayController.text =
                              '${picked.month}/${picked.day}/${picked.year}';
                        });
                      }
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: _genders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Social media connections
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Connect Social Accounts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 8),

                // Social media connection buttons
                _buildSocialButton(
                  icon: Icons.g_mobiledata,
                  text: 'Connect Google',
                  isConnected: false,
                  onTap: () {
                    // Handle Google connection
                  },
                ),

                _buildSocialButton(
                  icon: Icons.facebook,
                  text: 'Connect Facebook',
                  isConnected: false,
                  onTap: () {
                    // Handle Facebook connection
                  },
                ),

                _buildSocialButton(
                  icon: Icons.link,
                  text: 'Connect Twitter',
                  isConnected: false,
                  onTap: () {
                    // Handle Twitter connection
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

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: isConnected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
