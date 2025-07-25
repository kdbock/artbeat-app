import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Screen Navigation & Tools',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDatabaseSection(context),
            const SizedBox(height: 8),
            _buildFeedbackSection(context),
            const SizedBox(height: 8),
            _buildBackupSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseSection(BuildContext context) {
    return ExpansionTile(
      title: const Text('Database Management'),
      children: [
        ListTile(
          title: const Text('View Records'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Database viewer coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('User Management'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User management coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Analytics'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analytics dashboard coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('System Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/admin/settings');
          },
        ),
        ListTile(
          title: const Text('View Logs'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log viewer coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return ExpansionTile(
      title: const Text('Feedback System'),
      children: [
        ListTile(
          leading: const Icon(Icons.feedback),
          title: const Text('Submit Feedback'),
          subtitle: const Text('Test the feedback form'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const FeedbackForm(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text('Admin Panel'),
          subtitle: const Text('View and manage feedback'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const DeveloperFeedbackAdminScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('System Info'),
          subtitle: const Text('Learn about the feedback system'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const FeedbackSystemInfoScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    return ExpansionTile(
      title: const Text('Backup Management'),
      children: [
        ListTile(
          title: const Text('View Backups'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup viewer coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Create Backup'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup creation coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Restore Backup'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup restoration coming soon')),
            );
          },
        ),
      ],
    );
  }
}
