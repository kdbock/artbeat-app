import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';

/// Admin Security Center Screen
/// Handles security monitoring, threat detection, and system security
class AdminSecurityCenterScreen extends StatefulWidget {
  const AdminSecurityCenterScreen({super.key});

  @override
  State<AdminSecurityCenterScreen> createState() =>
      _AdminSecurityCenterScreenState();
}

class _AdminSecurityCenterScreenState extends State<AdminSecurityCenterScreen> {
  final List<String> _tabs = [
    'Security Overview',
    'Threat Detection',
    'Access Control',
    'Audit Logs'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Security Center',
            style: TextStyle(
              fontFamily: 'Limelight',
              color: Color(0xFF8C52FF),
            ),
          ),
          bottom: TabBar(
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            labelColor: const Color(0xFF8C52FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF8C52FF),
          ),
        ),
        drawer: const AdminDrawer(),
        body: TabBarView(
          children: [
            _buildSecurityOverviewTab(),
            _buildThreatDetectionTab(),
            _buildAccessControlTab(),
            _buildAuditLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Status Cards
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Security Score',
                  '94/100',
                  Icons.security,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'Active Threats',
                  '2',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Failed Logins',
                  '15',
                  Icons.login,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'Blocked IPs',
                  '8',
                  Icons.block,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Security Events
          const Text(
            'Recent Security Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildSecurityEventCard(index)),
        ],
      ),
    );
  }

  Widget _buildThreatDetectionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active Threats
        const Text(
          'Active Threats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        _buildThreatCard(
          'Suspicious Login Activity',
          'Multiple failed login attempts from IP 192.168.1.100',
          'High',
          Colors.red,
        ),
        _buildThreatCard(
          'Unusual Data Access Pattern',
          'User accessing large amounts of user data',
          'Medium',
          Colors.orange,
        ),
        const SizedBox(height: 24),

        // Threat Detection Settings
        const Text(
          'Detection Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Real-time Monitoring'),
                  subtitle: const Text('Monitor security events in real-time'),
                  value: true,
                  onChanged: (value) {},
                  activeThumbColor: const Color(0xFF8C52FF),
                ),
                SwitchListTile(
                  title: const Text('Automated Threat Response'),
                  subtitle:
                      const Text('Automatically block suspicious activity'),
                  value: true,
                  onChanged: (value) {},
                  activeThumbColor: const Color(0xFF8C52FF),
                ),
                SwitchListTile(
                  title: const Text('Email Alerts'),
                  subtitle: const Text('Send email notifications for threats'),
                  value: false,
                  onChanged: (value) {},
                  activeThumbColor: const Color(0xFF8C52FF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessControlTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin Permissions
        const Text(
          'Admin Access Control',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(3, (index) => _buildAdminUserCard(index)),

        const SizedBox(height: 24),

        // IP Whitelist
        const Text(
          'IP Whitelist',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C52FF),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('192.168.1.0/24'),
                subtitle: const Text('Office Network'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {},
                ),
              ),
              ListTile(
                title: const Text('10.0.0.0/8'),
                subtitle: const Text('VPN Network'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Color(0xFF8C52FF)),
                title: const Text('Add IP Range'),
                onTap: () => _showAddIPDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab() {
    return Column(
      children: [
        // Filter Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: 'All',
                items: ['All', 'Login', 'Data Access', 'Settings Change']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),

        // Audit Log Entries
        Expanded(
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) => _buildAuditLogEntry(index),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityEventCard(int index) {
    final events = [
      'Failed login attempt blocked',
      'New admin user added',
      'Suspicious data access detected',
      'Password policy updated',
      'Security scan completed',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.security, color: Color(0xFF8C52FF)),
        title: Text(events[index % events.length]),
        subtitle: Text(
            '2024-12-${(index + 1).toString().padLeft(2, '0')} 10:${(index * 5).toString().padLeft(2, '0')} AM'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildThreatCard(
      String title, String description, String severity, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.warning, color: color),
        title: Text(title),
        subtitle: Text(description),
        trailing: Chip(
          label: Text(severity),
          backgroundColor: color.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: color),
        ),
        onTap: () => _showThreatDetails(title, description, severity),
      ),
    );
  }

  Widget _buildAdminUserCard(int index) {
    final users = ['John Admin', 'Sarah Security', 'Mike Manager'];
    final roles = ['Super Admin', 'Security Admin', 'Content Admin'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8C52FF),
          child: Text(users[index][0]),
        ),
        title: Text(users[index]),
        subtitle: Text('Role: ${roles[index]}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Permissions')),
            const PopupMenuItem(
                value: 'disable', child: Text('Disable Account')),
            const PopupMenuItem(value: 'remove', child: Text('Remove Admin')),
          ],
          onSelected: (value) => _handleAdminAction(value, users[index]),
        ),
      ),
    );
  }

  Widget _buildAuditLogEntry(int index) {
    final actions = [
      'User Login',
      'Data Export',
      'Settings Change',
      'User Created',
      'Content Deleted'
    ];
    final users = [
      'john.admin',
      'sarah.security',
      'mike.manager',
      'system',
      'auto.moderator'
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        dense: true,
        title: Text(actions[index % actions.length]),
        subtitle: Text(
            'User: ${users[index % users.length]} | IP: 192.168.1.${100 + index}'),
        trailing:
            Text('${10 + index}:${(index * 3).toString().padLeft(2, '0')}'),
        onTap: () => _showLogDetails(index),
      ),
    );
  }

  void _showThreatDetails(String title, String description, String severity) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Severity: $severity'),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            const Text('Recommended Actions:'),
            const Text('• Monitor the IP address'),
            const Text('• Review access logs'),
            const Text('• Consider blocking if pattern continues'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Threat marked as resolved')),
              );
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  void _showAddIPDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add IP Range'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'IP Address/Range',
                hintText: '192.168.1.0/24',
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Office Network',
              ),
            ),
          ],
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
                const SnackBar(content: Text('IP range added to whitelist')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _handleAdminAction(Object? value, String user) {
    String message;
    switch (value) {
      case 'edit':
        message = 'Edit permissions for $user';
        break;
      case 'disable':
        message = 'Disabled account for $user';
        break;
      case 'remove':
        message = 'Removed admin privileges for $user';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLogDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Log Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log ID: LOG_${1000 + index}'),
            Text(
                'Timestamp: 2024-12-24 ${10 + index}:${(index * 3).toString().padLeft(2, '0')}:00'),
            Text('User: user_${index + 1}'),
            Text('IP Address: 192.168.1.${100 + index}'),
            Text('User Agent: Mozilla/5.0...'),
            const Text('Additional Details: Success'),
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
}
