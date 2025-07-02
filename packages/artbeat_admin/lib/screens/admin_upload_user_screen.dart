import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Admin screen for creating/uploading users with full admin capabilities
class AdminUploadUserScreen extends StatefulWidget {
  const AdminUploadUserScreen({super.key});

  @override
  State<AdminUploadUserScreen> createState() => _AdminUploadUserScreenState();
}

class _AdminUploadUserScreenState extends State<AdminUploadUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _experienceController = TextEditingController(text: '0');

  UserType _selectedUserType = UserType.regular;
  bool _isVerified = false;
  bool _isLoading = false;
  String? _selectedGender;

  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _zipCodeController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  int _calculateLevel(int experiencePoints) {
    if (experiencePoints < 100) return 1;
    if (experiencePoints < 500) return 2;
    if (experiencePoints < 1000) return 3;
    if (experiencePoints < 2500) return 4;
    if (experiencePoints < 5000) return 5;
    if (experiencePoints < 10000) return 6;
    if (experiencePoints < 25000) return 7;
    if (experiencePoints < 50000) return 8;
    if (experiencePoints < 100000) return 9;
    return 10;
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final experiencePoints = int.tryParse(_experienceController.text) ?? 0;
      final level = _calculateLevel(experiencePoints);

      final userData = {
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : null,
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        'zipCode': _zipCodeController.text.trim().isNotEmpty
            ? _zipCodeController.text.trim()
            : null,
        'gender': _selectedGender,
        'userType': _selectedUserType.name,
        'isVerified': _isVerified,
        'experiencePoints': experiencePoints,
        'level': level,
        'posts': <String>[],
        'followers': <String>[],
        'following': <String>[],
        'captures': <String>[],
        'followersCount': 0,
        'followingCount': 0,
        'postsCount': 0,
        'capturesCount': 0,
        'achievements': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'adminUpload': true,
        'isSuspended': false,
        'isDeleted': false,
        'adminNotes': <String, dynamic>{},
        'adminFlags': <String>[],
        'reportCount': 0,
        'requiresPasswordReset': false,
      };

      if (_isVerified) {
        userData['emailVerifiedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('user').add(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating user: $e')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New User'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Create New User Account',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new user with admin privileges. This bypasses normal registration.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Information Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Location Information
                    _buildSectionHeader('Location Information'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _zipCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Zip Code (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_post_office),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: null, child: Text('Select Gender')),
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(
                            value: 'prefer_not_to_say',
                            child: Text('Prefer not to say')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Account Settings
                    _buildSectionHeader('Account Settings'),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<UserType>(
                      value: _selectedUserType,
                      decoration: const InputDecoration(
                        labelText: 'User Type *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_circle),
                      ),
                      items: UserType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getUserTypeIcon(type),
                                      size: 16,
                                      color: _getUserTypeColor(type),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(type.name.toUpperCase()),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUserType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    CheckboxListTile(
                      title: const Text('Verified Account'),
                      subtitle: const Text('Mark this account as verified'),
                      value: _isVerified,
                      onChanged: (value) {
                        setState(() {
                          _isVerified = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Experience Points',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star),
                        suffixText: 'XP',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final points = int.tryParse(value);
                          if (points == null || points < 0) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level: ${_calculateLevel(int.tryParse(_experienceController.text) ?? 0)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Create User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
    );
  }

  IconData _getUserTypeIcon(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Icons.admin_panel_settings;
      case UserType.moderator:
        return Icons.security;
      case UserType.artist:
        return Icons.brush;
      case UserType.gallery:
        return Icons.store;
      case UserType.regular:
        return Icons.person;
    }
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.red;
      case UserType.moderator:
        return Colors.orange;
      case UserType.artist:
        return Colors.purple;
      case UserType.gallery:
        return Colors.green;
      case UserType.regular:
        return Colors.blue;
    }
  }
}
