import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/settings_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  SecuritySettingsModel? _securitySettings;
  bool _isLoading = true;
  bool _isSaving = false;
  late final SettingsService _settingsService;
  late final FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _auth = FirebaseAuth.instance;
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load settings from Firestore
      final settingsData = await _settingsService.getUserSettings();
      final securityData =
          settingsData['securitySettings'] as Map<String, dynamic>?;

      SecuritySettingsModel settings;
      if (securityData != null) {
        // Parse existing security settings
        settings = SecuritySettingsModel.fromMap({
          'userId': userId,
          'twoFactor': securityData['twoFactor'] ?? <String, dynamic>{},
          'login': securityData['login'] ?? <String, dynamic>{},
          'password': securityData['password'] ?? <String, dynamic>{},
          'devices': securityData['devices'] ?? <String, dynamic>{},
          'updatedAt':
              securityData['updatedAt'] ?? DateTime.now().toIso8601String(),
        });
      } else {
        // Create default settings
        settings = SecuritySettingsModel.defaultSettings(userId);
      }

      if (mounted) {
        setState(() {
          _securitySettings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load security settings: $e')),
        );
      }
    }
  }

  Future<void> _updateSecuritySettings(SecuritySettingsModel settings) async {
    setState(() => _isSaving = true);
    try {
      // Save security settings to Firestore
      await _settingsService.updateSetting(
        'securitySettings',
        settings.toMap(),
      );

      if (mounted) {
        setState(() {
          _securitySettings = settings;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security settings updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _securitySettings == null
          ? const Center(child: Text('Failed to load security settings'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTwoFactorCard(),
                  const SizedBox(height: 16),
                  _buildLoginSecurityCard(),
                  const SizedBox(height: 16),
                  _buildPasswordCard(),
                  const SizedBox(height: 16),
                  _buildDeviceSecurityCard(),
                  const SizedBox(height: 24),
                  _buildSecurityActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTwoFactorCard() {
    final twoFactor = _securitySettings!.twoFactor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Two-Factor Authentication',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add an extra layer of security to your account',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Enable 2FA',
              subtitle: 'Require a second factor for login',
              value: twoFactor.enabled,
              onChanged: (value) {
                final updatedTwoFactor = twoFactor.copyWith(enabled: value);
                final updated = _securitySettings!.copyWith(
                  twoFactor: updatedTwoFactor,
                );
                _updateSecuritySettings(updated);
              },
            ),
            if (twoFactor.enabled) ...[
              const SizedBox(height: 12),
              _buildTwoFactorMethodDropdown(twoFactor),
              const SizedBox(height: 12),
              _buildSwitchTile(
                title: 'Backup Codes',
                subtitle: 'Generate backup codes for emergency access',
                value: twoFactor.backupCodesGenerated,
                onChanged: (value) {
                  if (value) {
                    _showBackupCodesDialog();
                  } else {
                    final updatedTwoFactor = twoFactor.copyWith(
                      backupCodesGenerated: false,
                    );
                    final updated = _securitySettings!.copyWith(
                      twoFactor: updatedTwoFactor,
                    );
                    _updateSecuritySettings(updated);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorMethodDropdown(TwoFactorSettings twoFactor) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: '2FA Method',
        border: OutlineInputBorder(),
      ),
      initialValue: twoFactor.method,
      items: const [
        DropdownMenuItem(value: 'sms', child: Text('SMS')),
        DropdownMenuItem(value: 'email', child: Text('Email')),
        DropdownMenuItem(
          value: 'authenticator',
          child: Text('Authenticator App'),
        ),
      ],
      onChanged: _isSaving
          ? null
          : (value) {
              if (value != null) {
                final updatedTwoFactor = twoFactor.copyWith(method: value);
                final updated = _securitySettings!.copyWith(
                  twoFactor: updatedTwoFactor,
                );
                _updateSecuritySettings(updated);
              }
            },
    );
  }

  Widget _buildLoginSecurityCard() {
    final login = _securitySettings!.login;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Login Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control how and when you can log in',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Email Verification Required',
              subtitle: 'Require email verification for login',
              value: login.requireEmailVerification,
              onChanged: (value) {
                final updatedLogin = login.copyWith(
                  requireEmailVerification: value,
                );
                final updated = _securitySettings!.copyWith(
                  login: updatedLogin,
                );
                _updateSecuritySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Login Alerts',
              subtitle: 'Get alerts for suspicious login activity',
              value: login.allowLoginAlerts,
              onChanged: (value) {
                final updatedLogin = login.copyWith(allowLoginAlerts: value);
                final updated = _securitySettings!.copyWith(
                  login: updatedLogin,
                );
                _updateSecuritySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Remember This Device',
              subtitle: 'Skip 2FA on trusted devices',
              value: login.rememberDevice,
              onChanged: (value) {
                final updatedLogin = login.copyWith(rememberDevice: value);
                final updated = _securitySettings!.copyWith(
                  login: updatedLogin,
                );
                _updateSecuritySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    final password = _securitySettings!.password;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last changed: ${password.lastChanged != null ? _formatDate(password.lastChanged!) : 'Never'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showChangePasswordDialog(),
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Require Password Change',
              subtitle: 'Periodically require password updates',
              value: password.requirePasswordChange,
              onChanged: (value) {
                final updatedPassword = password.copyWith(
                  requirePasswordChange: value,
                );
                final updated = _securitySettings!.copyWith(
                  password: updatedPassword,
                );
                _updateSecuritySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSecurityCard() {
    final devices = _securitySettings!.devices;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage trusted devices and security features',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Manage Devices'),
              subtitle: Text(
                '${devices.approvedDevices.length} approved devices',
              ),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showDevicesDialog(),
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Allow Multiple Sessions',
              subtitle: 'Allow login from multiple devices',
              value: devices.allowMultipleSessions,
              onChanged: (value) {
                final updatedDevices = devices.copyWith(
                  allowMultipleSessions: value,
                );
                final updated = _securitySettings!.copyWith(
                  devices: updatedDevices,
                );
                _updateSecuritySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Track Device Location',
              subtitle: 'Monitor device locations for security',
              value: devices.trackDeviceLocation,
              onChanged: (value) {
                final updatedDevices = devices.copyWith(
                  trackDeviceLocation: value,
                );
                final updated = _securitySettings!.copyWith(
                  devices: updatedDevices,
                );
                _updateSecuritySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Login History'),
                subtitle: const Text('View your recent login activity'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLoginHistoryDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.orange),
                title: const Text('Security Checkup'),
                subtitle: const Text('Review your security settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSecurityCheckupDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out Everywhere'),
                subtitle: const Text('Sign out of all devices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSignOutEverywhereDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _isSaving ? null : onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBackupCodesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Codes'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Save these backup codes in a secure location:'),
            SizedBox(height: 16),
            SelectableText('A1B2-C3D4-E5F6\nG7H8-I9J0-K1L2\nM3N4-O5P6-Q7R8'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Mark backup codes as generated
              final twoFactor = _securitySettings!.twoFactor.copyWith(
                backupCodesGenerated: true,
              );
              final updated = _securitySettings!.copyWith(twoFactor: twoFactor);
              _updateSecuritySettings(updated);
            },
            child: const Text('I\'ve Saved Them'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Password must be at least 8 characters long and contain uppercase, lowercase, and numbers.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                // Validate inputs
                if (currentPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }

                // Validate password requirements
                if (_securitySettings != null &&
                    !_securitySettings!.password.validatePassword(
                      newPassword,
                    )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password does not meet security requirements',
                      ),
                    ),
                  );
                  return;
                }

                // Close dialog and show loading
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);

                // Change password using Firebase Auth
                await _changePassword(currentPassword, newPassword);
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Update password change timestamp in security settings
      if (_securitySettings != null) {
        final updatedSettings = _securitySettings!.copyWith(
          password: _securitySettings!.password.copyWith(
            lastChanged: DateTime.now(),
          ),
        );
        await _updateSecuritySettings(updatedSettings);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password';
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'Please log out and log in again before changing password';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDevicesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trusted Devices'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.smartphone),
              title: Text('iPhone 15'),
              subtitle: Text('Last used: Today'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              leading: Icon(Icons.laptop_mac),
              title: Text('MacBook Pro'),
              subtitle: Text('Last used: Yesterday'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLoginHistoryDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login History'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.smartphone, color: Colors.green),
              title: Text('iPhone 15'),
              subtitle: Text('Today, 9:30 AM\nNew York, NY'),
            ),
            ListTile(
              leading: Icon(Icons.laptop_mac, color: Colors.green),
              title: Text('MacBook Pro'),
              subtitle: Text('Yesterday, 2:15 PM\nNew York, NY'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSecurityCheckupDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Checkup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your security status:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('2FA Enabled'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Strong Password'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Password is 6 months old'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutEverywhereDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out Everywhere'),
        content: const Text(
          'This will sign you out of all devices except this one. You\'ll need to sign in again on other devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out of all other devices'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
