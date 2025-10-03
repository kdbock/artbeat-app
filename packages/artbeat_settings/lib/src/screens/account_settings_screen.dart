import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/models.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Services
  final _userService = UserService();
  final _storageService = EnhancedStorageService();
  final _auth = FirebaseAuth.instance;
  final _imagePicker = ImagePicker();

  // Form controllers
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isUploadingImage = false;
  AccountSettingsModel? _accountSettings;

  @override
  void initState() {
    super.initState();
    _loadAccountSettings();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load user model from Firestore
      final userModel = await _userService.getUserModel(user.uid);

      // Create account settings from user model and Firebase Auth data
      _accountSettings = AccountSettingsModel(
        userId: user.uid,
        email: user.email ?? userModel.email,
        username: userModel.username,
        displayName: userModel.fullName,
        phoneNumber: user.phoneNumber ?? '',
        bio: userModel.bio,
        profileImageUrl: userModel.profileImageUrl,
        emailVerified: user.emailVerified,
        phoneVerified: user.phoneNumber != null && user.phoneNumber!.isNotEmpty,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        _populateFormFields();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to load account settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateFormFields() {
    if (_accountSettings != null) {
      _displayNameController.text = _accountSettings!.displayName;
      _emailController.text = _accountSettings!.email;
      _usernameController.text = _accountSettings!.username;
      _phoneController.text = _accountSettings!.phoneNumber;
      _bioController.text = _accountSettings!.bio;
    }
  }

  void _onFormChanged() {
    setState(() => _hasChanges = true);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      var updatedSettings = _accountSettings!.copyWith(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // Update user document in Firestore
      await _userService.firestore.collection('users').doc(user.uid).update({
        'displayName': updatedSettings.displayName,
        'username': updatedSettings.username,
        'bio': updatedSettings.bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update email in Firebase Auth if changed
      if (updatedSettings.email != _accountSettings!.email) {
        await user.verifyBeforeUpdateEmail(updatedSettings.email);
        // Email verification will be reset, so update the flag
        updatedSettings = updatedSettings.copyWith(emailVerified: false);
      }

      // Update display name in Firebase Auth if changed
      if (updatedSettings.displayName != _accountSettings!.displayName) {
        await user.updateDisplayName(updatedSettings.displayName);
      }

      if (mounted) {
        setState(() {
          _accountSettings = updatedSettings;
          _hasChanges = false;
        });

        _showSuccessMessage('Account settings updated successfully');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save changes';
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage =
                'This operation requires recent authentication. Please log out and log in again.';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email is already in use by another account.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          default:
            errorMessage = 'Failed to save changes: ${e.message}';
        }
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to save changes: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAccountForm(),
    );
  }

  Widget _buildAccountForm() {
    return Form(
      key: _formKey,
      onChanged: _onFormChanged,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Picture Section
          _buildProfilePictureSection(),
          const SizedBox(height: 24),

          // Basic Information
          _buildSectionHeader('Basic Information'),
          const SizedBox(height: 12),

          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
              helperText: 'This is how others will see your name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Display name is required';
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
              helperText: 'Unique identifier for your profile',
              prefixText: '@',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
              helperText: 'Tell others about yourself',
            ),
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 24),

          // Contact Information
          _buildSectionHeader('Contact Information'),
          const SizedBox(height: 12),

          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: const OutlineInputBorder(),
              suffixIcon: _accountSettings?.emailVerified == true
                  ? const Icon(Icons.verified, color: Colors.green)
                  : const Icon(Icons.warning, color: Colors.orange),
              helperText: _accountSettings?.emailVerified == true
                  ? 'Email verified'
                  : 'Email not verified',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: const OutlineInputBorder(),
              suffixIcon: _accountSettings?.phoneVerified == true
                  ? const Icon(Icons.verified, color: Colors.green)
                  : null,
              helperText: _accountSettings?.phoneVerified == true
                  ? 'Phone verified'
                  : 'Phone not verified',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          // Account Actions
          _buildSectionHeader('Account Actions'),
          const SizedBox(height: 12),

          ListTile(
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showChangePasswordDialog,
          ),

          ListTile(
            title: const Text('Verify Email'),
            subtitle: const Text('Send verification email'),
            trailing: const Icon(Icons.arrow_forward_ios),
            enabled: _accountSettings?.emailVerified != true,
            onTap: _accountSettings?.emailVerified != true
                ? _sendEmailVerification
                : null,
          ),

          ListTile(
            title: const Text('Verify Phone'),
            subtitle: const Text('Send verification SMS'),
            trailing: const Icon(Icons.arrow_forward_ios),
            enabled:
                _accountSettings?.phoneVerified != true &&
                _phoneController.text.trim().isNotEmpty,
            onTap: _sendPhoneVerification,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  _accountSettings?.profileImageUrl.isNotEmpty == true
                  ? NetworkImage(_accountSettings!.profileImageUrl)
                  : null,
              child: _accountSettings?.profileImageUrl.isEmpty != false
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            if (_isUploadingImage)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _isUploadingImage ? null : _changeProfilePicture,
          icon: const Icon(Icons.camera_alt),
          label: Text(_isUploadingImage ? 'Uploading...' : 'Change Photo'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Future<void> _changeProfilePicture() async {
    if (!mounted) return;

    // Show source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      setState(() => _isUploadingImage = true);

      // Pick image
      final pickedFile = await _imagePicker.pickImage(source: source);

      if (pickedFile == null || !mounted) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload image to Firebase Storage
      final imageFile = File(pickedFile.path);
      final uploadResult = await _storageService.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'profile_pictures/${user.uid}',
        generateThumbnail: true,
        customWidth: 512,
        customHeight: 512,
      );

      final imageUrl = uploadResult['imageUrl'] ?? '';

      // Update user profile in Firestore
      await _userService.firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile
      await user.updatePhotoURL(imageUrl);

      if (mounted) {
        setState(() {
          _accountSettings = _accountSettings!.copyWith(
            profileImageUrl: imageUrl,
          );
          _isUploadingImage = false;
        });

        _showSuccessMessage('Profile picture updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showErrorMessage('Failed to update profile picture: $e');
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change functionality coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmailVerification() async {
    if (!mounted) return;

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (user.emailVerified) {
        _showSuccessMessage('Email is already verified');
        return;
      }

      // Send verification email
      await user.sendEmailVerification();

      if (mounted) {
        _showSuccessMessage(
          'Verification email sent to ${user.email}. Please check your inbox.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to send verification email';
        switch (e.code) {
          case 'too-many-requests':
            errorMessage =
                'Too many requests. Please wait a few minutes before trying again.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          default:
            errorMessage = 'Failed to send verification email: ${e.message}';
        }
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to send verification email: $e');
      }
    }
  }

  Future<void> _sendPhoneVerification() async {
    if (!mounted) return;

    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showErrorMessage('Please enter a phone number first');
      return;
    }

    // Validate phone number format (basic validation)
    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phoneNumber)) {
      _showErrorMessage(
        'Please enter a valid phone number with country code (e.g., +1234567890)',
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          try {
            await user.updatePhoneNumber(credential);
            if (mounted) {
              setState(() {
                _accountSettings = _accountSettings!.copyWith(
                  phoneNumber: phoneNumber,
                  phoneVerified: true,
                );
              });
              _showSuccessMessage('Phone number verified successfully');
            }
          } catch (e) {
            if (mounted) {
              _showErrorMessage('Failed to verify phone number: $e');
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            String errorMessage = 'Phone verification failed';
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage = 'The phone number is invalid.';
                break;
              case 'too-many-requests':
                errorMessage = 'Too many requests. Please try again later.';
                break;
              case 'quota-exceeded':
                errorMessage = 'SMS quota exceeded. Please try again later.';
                break;
              default:
                errorMessage = 'Phone verification failed: ${e.message}';
            }
            _showErrorMessage(errorMessage);
          }
        },
        codeSent: (String verId, int? token) {
          if (mounted) {
            _showVerificationCodeDialog(verId, phoneNumber);
          }
        },
        codeAutoRetrievalTimeout: (String verId) {
          // Timeout occurred, user can still enter code manually
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to send verification code: $e');
      }
    }
  }

  Future<void> _showVerificationCodeDialog(
    String verificationId,
    String phoneNumber,
  ) async {
    final codeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Verification Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A verification code has been sent to $phoneNumber'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
                hintText: '123456',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the verification code'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final user = _auth.currentUser;
                if (user == null) {
                  throw Exception('User not authenticated');
                }

                // Create credential with verification code
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: code,
                );

                // Update phone number
                await user.updatePhoneNumber(credential);

                // Update Firestore
                await _userService.firestore
                    .collection('users')
                    .doc(user.uid)
                    .update({
                      'phoneNumber': phoneNumber,
                      'phoneVerified': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              } on FirebaseAuthException catch (e) {
                String errorMessage = 'Verification failed';
                switch (e.code) {
                  case 'invalid-verification-code':
                    errorMessage =
                        'Invalid verification code. Please try again.';
                    break;
                  case 'session-expired':
                    errorMessage =
                        'Verification code expired. Please request a new one.';
                    break;
                  default:
                    errorMessage = 'Verification failed: ${e.message}';
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verification failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    codeController.dispose();

    if (result == true && mounted) {
      setState(() {
        _accountSettings = _accountSettings!.copyWith(
          phoneNumber: phoneNumber,
          phoneVerified: true,
        );
      });
      _showSuccessMessage('Phone number verified successfully');
    }
  }
}
