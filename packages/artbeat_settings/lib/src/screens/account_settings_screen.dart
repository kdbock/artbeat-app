import 'package:flutter/material.dart';
import '../models/models.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
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
    setState(() => _isLoading = true);

    try {
      // TODO: Load actual account settings from service
      // For now, create mock data
      _accountSettings = AccountSettingsModel(
        userId: 'current-user-id',
        email: 'user@example.com',
        username: 'username',
        displayName: 'Display Name',
        phoneNumber: '',
        bio: '',
        emailVerified: true,
        phoneVerified: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      _populateFormFields();
    } catch (e) {
      _showErrorMessage('Failed to load account settings: $e');
    } finally {
      setState(() => _isLoading = false);
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

    setState(() => _isLoading = true);

    try {
      final updatedSettings = _accountSettings!.copyWith(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // TODO: Save to service
      // await _settingsService.updateAccountSettings(updatedSettings);

      setState(() {
        _accountSettings = updatedSettings;
        _hasChanges = false;
      });

      _showSuccessMessage('Account settings updated successfully');
    } catch (e) {
      _showErrorMessage('Failed to save changes: $e');
    } finally {
      setState(() => _isLoading = false);
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
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/default_profile.png'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _changeProfilePicture,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Photo'),
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

  void _changeProfilePicture() {
    // TODO: Implement profile picture change
    _showErrorMessage('Profile picture change coming soon');
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

  void _sendEmailVerification() {
    // TODO: Implement email verification
    _showSuccessMessage('Verification email sent');
  }

  void _sendPhoneVerification() {
    // TODO: Implement phone verification
    _showSuccessMessage('Verification SMS sent');
  }
}
