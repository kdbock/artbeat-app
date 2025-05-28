import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isLoading = false;

  // Mock data - would be fetched from Firebase Auth or other service
  final List<Map<String, dynamic>> _loginHistory = [
    {
      'device': 'iPhone 13',
      'location': 'San Francisco, CA',
      'ip': '192.168.1.1',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'current': true,
    },
    {
      'device': 'MacBook Pro',
      'location': 'San Francisco, CA',
      'ip': '192.168.1.2',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'current': false,
    },
    {
      'device': 'Chrome on Windows',
      'location': 'New York, NY',
      'ip': '10.0.0.1',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'current': false,
    },
  ];

  // Security settings
  bool _alertOnNewLogin = true;
  bool _alertOnSuspiciousActivity = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, fetch security settings from Firestore
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSecuritySettings() async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, save to Firestore
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Security settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSecuritySettings,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('SAVE'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Login Alert Settings
                  const Text(
                    'Login Alerts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Alert on new login'),
                    subtitle: const Text(
                      'Get notified when your account is accessed from a new device',
                    ),
                    value: _alertOnNewLogin,
                    onChanged: (value) {
                      setState(() {
                        _alertOnNewLogin = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Alert on suspicious activity'),
                    subtitle: const Text(
                      'Get notified of unusual account activity',
                    ),
                    value: _alertOnSuspiciousActivity,
                    onChanged: (value) {
                      setState(() {
                        _alertOnSuspiciousActivity = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  const Divider(height: 32),

                  // Current Sessions
                  const Text(
                    'Device Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ..._loginHistory.map((session) => _buildSessionTile(session)),

                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _showSignOutAllDevicesDialog,
                    child: const Text('Sign out all devices'),
                  ),

                  const Divider(height: 32),

                  // Login Verification
                  const Text(
                    'Login Verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Two-Factor Authentication'),
                    subtitle: const Text('Not enabled'),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      Navigator.pushNamed(context, '/settings/account');
                    },
                  ),

                  const Divider(height: 32),

                  // Data and Privacy
                  const Text(
                    'Data and Privacy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Download Your Data'),
                    subtitle: const Text('Get a copy of your WordNerd data'),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Data download will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Data Sharing Settings'),
                    subtitle: const Text('Manage how your data is used'),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Data sharing settings will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final DateTime time = session['time'] as DateTime;
    final bool isCurrent = session['current'] as bool;
    final String timeString = _formatTime(time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCurrent ? Icons.smartphone : Icons.devices,
            color: isCurrent ? Colors.green : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session['device'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(session['location'] as String),
                const SizedBox(height: 4),
                Text(
                  'IP: ${session['ip']} • $timeString',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () => _showSignOutDeviceDialog(session),
              child: const Text('Sign Out'),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }

  Future<void> _showSignOutDeviceDialog(Map<String, dynamic> session) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out Device'),
            content: Text(
              'Are you sure you want to sign out ${session['device']} from your account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('SIGN OUT'),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      // In a real app, sign out the specific device
      setState(() {
        _loginHistory.remove(session);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device has been signed out')),
      );
    }
  }

  Future<void> _showSignOutAllDevicesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out All Devices'),
            content: const Text(
              'Are you sure you want to sign out all devices except your current one? '
              'You will need to sign in again on those devices.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('SIGN OUT ALL'),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      // In a real app, sign out all devices
      try {
        await FirebaseAuth.instance.signOut();
        // Re-authenticate the current user
        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          _loginHistory.removeWhere((session) => !(session['current'] as bool));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All other devices have been signed out'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out devices: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }
}
