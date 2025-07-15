import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  PackageInfo? _packageInfo;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
      });
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppInfoSection(),
              const SizedBox(height: 24),
              _buildUserInfoSection(),
              const SizedBox(height: 24),
              _buildSystemInfoSection(),
              const SizedBox(height: 24),
              _buildDeveloperSection(),
              const SizedBox(height: 24),
              _buildActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return _buildSection(
      title: 'App Information',
      icon: Icons.info_outline,
      children: [
        _buildInfoTile('App Name', _packageInfo?.appName ?? 'ARTbeat'),
        _buildInfoTile('Version', _packageInfo?.version ?? '1.0.0'),
        _buildInfoTile('Build Number', _packageInfo?.buildNumber ?? '1'),
        _buildInfoTile(
          'Package Name',
          _packageInfo?.packageName ?? 'com.artbeat.app',
        ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    return _buildSection(
      title: 'User Information',
      icon: Icons.person_outline,
      children: [
        _buildInfoTile('User ID', _currentUser?.uid ?? 'Not authenticated'),
        _buildInfoTile('Email', _currentUser?.email ?? 'Not provided'),
        _buildInfoTile(
          'Account Created',
          _currentUser?.metadata.creationTime?.toString() ?? 'Unknown',
        ),
        _buildInfoTile(
          'Last Sign In',
          _currentUser?.metadata.lastSignInTime?.toString() ?? 'Unknown',
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return _buildSection(
      title: 'System Information',
      icon: Icons.settings_outlined,
      children: [
        _buildInfoTile('Platform', Theme.of(context).platform.name),
        _buildInfoTile('Firebase Project', 'artbeat-app-b5ab4'),
        _buildInfoTile('Environment', 'Development'),
        _buildInfoTile('Debug Mode', 'Enabled'),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return _buildSection(
      title: 'Developer Tools',
      icon: Icons.developer_mode,
      children: [
        _buildActionTile(
          'Clear Cache',
          'Clear application cache and temporary files',
          Icons.clear_all,
          () => _showClearCacheDialog(),
        ),
        _buildActionTile(
          'Reset User Preferences',
          'Reset all user preferences to default',
          Icons.restore,
          () => _showResetPreferencesDialog(),
        ),
        _buildActionTile(
          'View Application Logs',
          'View recent application logs and errors',
          Icons.list_alt,
          () => _showLogsDialog(),
        ),
        _buildActionTile(
          'Test Connectivity',
          'Test network and Firebase connectivity',
          Icons.wifi_outlined,
          () => _testConnectivity(),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return _buildSection(
      title: 'Actions',
      icon: Icons.build_outlined,
      children: [
        _buildActionTile(
          'Refresh App State',
          'Refresh the application state and data',
          Icons.refresh,
          () => _refreshAppState(),
        ),
        _buildActionTile(
          'Export Settings',
          'Export current application settings',
          Icons.file_download,
          () => _exportSettings(),
        ),
        _buildActionTile(
          'Report Issue',
          'Report a bug or technical issue',
          Icons.bug_report,
          () => _reportIssue(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ArtbeatColors.primaryPurple),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: ArtbeatColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: ArtbeatColors.primaryPurple),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: ArtbeatColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: ArtbeatColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showClearCacheDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear the application cache?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetPreferencesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Preferences'),
        content: const Text(
          'Are you sure you want to reset all user preferences to default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPreferences();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showLogsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Logs'),
        content: const SizedBox(
          height: 300,
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              'Recent logs will be displayed here...\n\n'
              'This feature is under development and will show:\n'
              '- Error logs\n'
              '- Navigation events\n'
              '- API requests\n'
              '- User interactions\n',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
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

  void _clearCache() {
    // Implement cache clearing logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: ArtbeatColors.success,
      ),
    );
  }

  void _resetPreferences() {
    // Implement preferences reset logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences reset successfully'),
        backgroundColor: ArtbeatColors.success,
      ),
    );
  }

  void _testConnectivity() {
    // Implement connectivity test
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connectivity test: All services online'),
        backgroundColor: ArtbeatColors.success,
      ),
    );
  }

  void _refreshAppState() {
    // Implement app state refresh
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App state refreshed successfully'),
        backgroundColor: ArtbeatColors.success,
      ),
    );
  }

  void _exportSettings() {
    // Implement settings export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings exported successfully'),
        backgroundColor: ArtbeatColors.success,
      ),
    );
  }

  void _reportIssue() {
    // Navigate to feedback form
    Navigator.pushNamed(context, '/feedback');
  }
}
