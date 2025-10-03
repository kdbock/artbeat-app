import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/settings_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _settingsService = SettingsService();
  PrivacySettingsModel? _privacySettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final settings = await _settingsService.getPrivacySettings();
      if (mounted) {
        setState(() {
          _privacySettings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load privacy settings: $e')),
        );
      }
    }
  }

  Future<void> _updatePrivacySettings(PrivacySettingsModel settings) async {
    setState(() => _isSaving = true);
    try {
      await _settingsService.savePrivacySettings(settings);
      if (mounted) {
        setState(() {
          _privacySettings = settings;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings updated')),
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _privacySettings == null
        ? const Center(child: Text('Failed to load privacy settings'))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileVisibilityCard(),
                const SizedBox(height: 16),
                _buildContentPrivacyCard(),
                const SizedBox(height: 16),
                _buildDataPrivacyCard(),
                const SizedBox(height: 16),
                _buildLocationPrivacyCard(),
                const SizedBox(height: 24),
                _buildDataControlsSection(),
              ],
            ),
          );
  }

  Widget _buildProfileVisibilityCard() {
    final profile = _privacySettings!.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control who can see your profile and information',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildVisibilityDropdown(profile),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'Show Last Seen',
              subtitle: 'Let others see when you were last active',
              value: profile.showLastSeen,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(showLastSeen: value);
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Show Online Status',
              subtitle: 'Display when you are currently online',
              value: profile.showOnlineStatus,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(
                  showOnlineStatus: value,
                );
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Allow Messages',
              subtitle: 'Let others send you direct messages',
              value: profile.allowMessages,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(allowMessages: value);
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Show Followers Count',
              subtitle: 'Display your follower count on your profile',
              value: profile.showFollowersCount,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(
                  showFollowersCount: value,
                );
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Show Following Count',
              subtitle: 'Display your following count on your profile',
              value: profile.showFollowingCount,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(
                  showFollowingCount: value,
                );
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityDropdown(ProfilePrivacySettings profile) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Profile Visibility',
        border: OutlineInputBorder(),
      ),
      initialValue: profile.visibility,
      items: const [
        DropdownMenuItem(value: 'public', child: Text('Public')),
        DropdownMenuItem(value: 'friends', child: Text('Friends Only')),
        DropdownMenuItem(value: 'private', child: Text('Private')),
      ],
      onChanged: _isSaving
          ? null
          : (value) {
              if (value != null) {
                final updatedProfile = profile.copyWith(visibility: value);
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              }
            },
    );
  }

  Widget _buildContentPrivacyCard() {
    final content = _privacySettings!.content;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Content Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control who can see and interact with your content',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Show in Search',
              subtitle: 'Display your content in search results',
              value: content.showInSearch,
              onChanged: (value) {
                final updatedContent = content.copyWith(showInSearch: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Allow Comments',
              subtitle: 'Let others comment on your posts',
              value: content.allowComments,
              onChanged: (value) {
                final updatedContent = content.copyWith(allowComments: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Allow Sharing',
              subtitle: 'Let others share your content',
              value: content.allowSharing,
              onChanged: (value) {
                final updatedContent = content.copyWith(allowSharing: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Allow Likes',
              subtitle: 'Let others like your content',
              value: content.allowLikes,
              onChanged: (value) {
                final updatedContent = content.copyWith(allowLikes: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPrivacyCard() {
    final data = _privacySettings!.data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control how your data is collected and used',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Analytics Collection',
              subtitle: 'Help improve the app by sharing usage data',
              value: data.allowAnalytics,
              onChanged: (value) {
                final updatedData = data.copyWith(allowAnalytics: value);
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Marketing Communications',
              subtitle: 'Receive marketing emails and notifications',
              value: data.allowMarketing,
              onChanged: (value) {
                final updatedData = data.copyWith(allowMarketing: value);
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Personalization',
              subtitle: 'Use your data to personalize content',
              value: data.allowPersonalization,
              onChanged: (value) {
                final updatedData = data.copyWith(allowPersonalization: value);
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Third-party Sharing',
              subtitle: 'Share data with trusted partners',
              value: data.allowThirdPartySharing,
              onChanged: (value) {
                final updatedData = data.copyWith(
                  allowThirdPartySharing: value,
                );
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPrivacyCard() {
    final location = _privacySettings!.location;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control location tracking and sharing',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Location Sharing',
              subtitle: 'Allow location-based features',
              value: location.shareLocation,
              onChanged: (value) {
                final updatedLocation = location.copyWith(shareLocation: value);
                final updated = _privacySettings!.copyWith(
                  location: updatedLocation,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Show Location in Profile',
              subtitle: 'Display your location in your profile',
              value: location.showLocationInProfile,
              onChanged: (value) {
                final updatedLocation = location.copyWith(
                  showLocationInProfile: value,
                );
                final updated = _privacySettings!.copyWith(
                  location: updatedLocation,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'Location-based Recommendations',
              subtitle: 'Get recommendations based on your location',
              value: location.allowLocationBasedRecommendations,
              onChanged: (value) {
                final updatedLocation = location.copyWith(
                  allowLocationBasedRecommendations: value,
                );
                final updated = _privacySettings!.copyWith(
                  location: updatedLocation,
                );
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Controls',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Download My Data'),
                subtitle: const Text('Get a copy of your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDataDownloadDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete My Data'),
                subtitle: const Text(
                  'Permanently delete your account and data',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDataDeletionDialog(),
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

  void _showDataDownloadDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We\'ll prepare a file containing all your data and send you a download link via email. This may take a few minutes to process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestDataDownload();
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Your Data'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestDataDeletion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete My Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDataDownload() async {
    try {
      await _settingsService.requestDataDownload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data download requested. You\'ll receive an email when ready.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request data download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestDataDeletion() async {
    try {
      await _settingsService.requestDataDeletion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data deletion requested. This will take effect within 30 days.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request data deletion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
