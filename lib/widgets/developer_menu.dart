import 'package:flutter/material.dart';

class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Screen Navigation',
                    style: TextStyle(
                      color: Color.fromARGB(179, 27, 26, 26),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildDatabaseSection(context),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('System settings coming soon')),
            );
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
