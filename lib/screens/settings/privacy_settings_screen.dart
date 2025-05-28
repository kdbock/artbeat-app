import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = false;

  // Privacy settings
  String _profileVisibility = 'Public';
  String _followPermission = 'Everyone';
  String _messagePermission = 'Everyone';
  bool _showActivity = true;
  
  // Dropdown options
  final List<String> _visibilityOptions = ['Public', 'Private', 'Followers Only'];
  final List<String> _permissionOptions = ['Everyone', 'Followers Only', 'Nobody'];
  
  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }
  
  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
    });
    
    // In a real app, fetch from Firestore or similar
    // For now, use hardcoded defaults
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _savePrivacySettings() async {
    setState(() {
      _isLoading = true;
    });
    
    // In a real app, save to Firestore or similar
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePrivacySettings,
            child: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Visibility
                const Text(
                  'Who can see my profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _profileVisibility,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _visibilityOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _profileVisibility = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _getProfileVisibilityDescription(),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // Follow Permission
                const Text(
                  'Who can follow me',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _followPermission,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _permissionOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _followPermission = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Message Permission
                const Text(
                  'Who can message me',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _messagePermission,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _permissionOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _messagePermission = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Activity Status
                const Text(
                  'Activity Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Show activity status'),
                  subtitle: const Text('Allow others to see when you were last active'),
                  value: _showActivity,
                  onChanged: (value) {
                    setState(() {
                      _showActivity = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                
                // Mentions
                const Text(
                  'Tags and Mentions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Who can mention you'),
                  subtitle: const Text('Everyone'),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    // Would navigate to a detailed mentions settings page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mention settings will be implemented soon'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Blocked Users button
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings/blocked-users');
                  },
                  child: const Text('Manage Blocked Users'),
                ),
              ],
            ),
    );
  }
  
  String _getProfileVisibilityDescription() {
    switch (_profileVisibility) {
      case 'Public':
        return 'Anyone can see your profile and posts';
      case 'Private':
        return 'Only your followers can see your profile and posts';
      case 'Followers Only':
        return 'Only people you approved to follow you can see your profile and posts';
      default:
        return '';
    }
  }
}
