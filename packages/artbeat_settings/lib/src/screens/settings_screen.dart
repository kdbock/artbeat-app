import 'package:flutter/material.dart';
import '../models/models.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSettingsBody(context);
  }

  Widget _buildSettingsBody(BuildContext context) {
    final categories = SettingsCategoryModel.getDefaultCategories();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User profile summary
        _buildProfileSummary(context),
        const SizedBox(height: 24),

        // Settings categories
        ...categories.map(
          (category) => _buildSettingsCategory(context, category),
        ),

        const SizedBox(height: 24),

        // Quick actions
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: const AssetImage('assets/default_profile.png'),
              child: Container(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your profile and preferences',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCategory(
    BuildContext context,
    SettingsCategoryModel category,
  ) {
    if (!category.isEnabled) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getIconForCategory(category.iconData),
        title: Text(
          category.title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          category.description,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToCategory(context, category),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Icon _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'account_circle':
        return const Icon(Icons.account_circle);
      case 'privacy_tip':
        return const Icon(Icons.privacy_tip);
      case 'notifications':
        return const Icon(Icons.notifications);
      case 'security':
        return const Icon(Icons.security);
      case 'block':
        return const Icon(Icons.block);
      default:
        return const Icon(Icons.settings);
    }
  }

  void _navigateToCategory(
    BuildContext context,
    SettingsCategoryModel category,
  ) {
    Navigator.pushNamed(context, category.route);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement logout functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout functionality coming soon'),
                ),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion functionality coming soon'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
