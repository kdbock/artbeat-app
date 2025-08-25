import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';

/// Admin Data Management Screen
/// Handles data backup, export, migration, and cleanup operations
class AdminDataManagementScreen extends StatefulWidget {
  const AdminDataManagementScreen({super.key});

  @override
  State<AdminDataManagementScreen> createState() =>
      _AdminDataManagementScreenState();
}

class _AdminDataManagementScreenState extends State<AdminDataManagementScreen> {
  final List<String> _tabs = [
    'Backup & Export',
    'Data Migration',
    'Data Cleanup',
    'Analytics'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Data Management',
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
            _buildBackupExportTab(),
            _buildDataMigrationTab(),
            _buildDataCleanupTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Backup Status
          const Text(
            'Backup Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Last Backup',
                  '2 hours ago',
                  Icons.backup,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'Backup Size',
                  '2.4 GB',
                  Icons.storage,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Backup Actions
          const Text(
            'Backup Actions',
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
                  leading: const Icon(Icons.backup, color: Color(0xFF8C52FF)),
                  title: const Text('Create Full Backup'),
                  subtitle: const Text('Backup all user data and content'),
                  trailing: ElevatedButton(
                    onPressed: () => _createBackup('full'),
                    child: const Text('Start'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.backup_table, color: Color(0xFF8C52FF)),
                  title: const Text('Create Incremental Backup'),
                  subtitle: const Text('Backup only changes since last backup'),
                  trailing: ElevatedButton(
                    onPressed: () => _createBackup('incremental'),
                    child: const Text('Start'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.download, color: Color(0xFF8C52FF)),
                  title: const Text('Export User Data'),
                  subtitle:
                      const Text('Export specific user data (GDPR compliance)'),
                  trailing: ElevatedButton(
                    onPressed: () => _showExportDialog(),
                    child: const Text('Export'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent Backups
          const Text(
            'Recent Backups',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildBackupHistoryCard(index)),
        ],
      ),
    );
  }

  Widget _buildDataMigrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Migration Tools',
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
                  leading:
                      const Icon(Icons.cloud_upload, color: Color(0xFF8C52FF)),
                  title: const Text('Import Data'),
                  subtitle: const Text('Import data from external sources'),
                  trailing: ElevatedButton(
                    onPressed: () => _showImportDialog(),
                    child: const Text('Import'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.transform, color: Color(0xFF8C52FF)),
                  title: const Text('Data Transformation'),
                  subtitle: const Text('Transform data between formats'),
                  trailing: ElevatedButton(
                    onPressed: () => _showTransformDialog(),
                    child: const Text('Transform'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.sync, color: Color(0xFF8C52FF)),
                  title: const Text('Database Sync'),
                  subtitle: const Text('Sync data between environments'),
                  trailing: ElevatedButton(
                    onPressed: () => _syncDatabase(),
                    child: const Text('Sync'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Migration History
          const Text(
            'Migration History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => _buildMigrationHistoryCard(index)),
        ],
      ),
    );
  }

  Widget _buildDataCleanupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cleanup Summary
          const Text(
            'Cleanup Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Orphaned Data',
                  '145 MB',
                  Icons.delete_outline,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'Duplicate Files',
                  '78',
                  Icons.copy,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cleanup Actions
          const Text(
            'Cleanup Actions',
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
                  leading: const Icon(Icons.cleaning_services,
                      color: Color(0xFF8C52FF)),
                  title: const Text('Clean Orphaned Data'),
                  subtitle: const Text('Remove data without valid references'),
                  trailing: ElevatedButton(
                    onPressed: () => _cleanOrphanedData(),
                    child: const Text('Clean'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.content_copy, color: Color(0xFF8C52FF)),
                  title: const Text('Remove Duplicates'),
                  subtitle: const Text('Find and remove duplicate files'),
                  trailing: ElevatedButton(
                    onPressed: () => _removeDuplicates(),
                    child: const Text('Remove'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.archive, color: Color(0xFF8C52FF)),
                  title: const Text('Archive Old Data'),
                  subtitle: const Text('Archive data older than 1 year'),
                  trailing: ElevatedButton(
                    onPressed: () => _archiveOldData(),
                    child: const Text('Archive'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cleanup Schedule
          const Text(
            'Cleanup Schedule',
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
                    title: const Text('Auto Cleanup'),
                    subtitle: const Text('Automatically clean orphaned data'),
                    value: true,
                    onChanged: (value) {},
                    activeThumbColor: const Color(0xFF8C52FF),
                  ),
                  SwitchListTile(
                    title: const Text('Weekly Archives'),
                    subtitle: const Text('Archive old data weekly'),
                    value: false,
                    onChanged: (value) {},
                    activeThumbColor: const Color(0xFF8C52FF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Analytics
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Total Storage',
                  '45.2 GB',
                  Icons.storage,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'Available Space',
                  '154.8 GB',
                  Icons.storage_outlined,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'User Data',
                  '32.1 GB',
                  Icons.people,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'System Data',
                  '13.1 GB',
                  Icons.settings,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Data Growth Chart
          const Text(
            'Data Growth Trends',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Data Growth Chart\n(Integration with analytics service required)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Data Consumers
          const Text(
            'Top Data Consumers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildDataConsumerCard(index)),
        ],
      ),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupHistoryCard(int index) {
    final backupTypes = ['Full', 'Incremental', 'Full', 'Incremental', 'Full'];
    final sizes = ['2.4 GB', '145 MB', '2.3 GB', '167 MB', '2.2 GB'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          backupTypes[index] == 'Full' ? Icons.backup : Icons.backup_table,
          color: const Color(0xFF8C52FF),
        ),
        title: Text('${backupTypes[index]} Backup'),
        subtitle: Text(
            'Size: ${sizes[index]} | 2024-12-${(24 - index).toString().padLeft(2, '0')}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'download', child: Text('Download')),
            const PopupMenuItem(value: 'restore', child: Text('Restore')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) => _handleBackupAction(value, index),
        ),
      ),
    );
  }

  Widget _buildMigrationHistoryCard(int index) {
    final operations = [
      'User Data Import',
      'Content Migration',
      'Database Sync'
    ];
    final statuses = ['Completed', 'Failed', 'Completed'];
    final colors = [Colors.green, Colors.red, Colors.green];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.sync, color: colors[index]),
        title: Text(operations[index]),
        subtitle: Text(
            '2024-12-${(20 + index).toString().padLeft(2, '0')} | Status: ${statuses[index]}'),
        trailing: statuses[index] == 'Failed'
            ? ElevatedButton(
                onPressed: () => _retryMigration(index),
                child: const Text('Retry'),
              )
            : Icon(Icons.check, color: colors[index]),
      ),
    );
  }

  Widget _buildDataConsumerCard(int index) {
    final consumers = [
      'User Profiles',
      'Artwork Images',
      'Post Content',
      'System Logs',
      'Backup Data'
    ];
    final sizes = ['12.3 GB', '18.7 GB', '8.9 GB', '3.2 GB', '2.1 GB'];
    final percentages = [27, 41, 20, 7, 5];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(consumers[index]),
        subtitle: LinearProgressIndicator(
          value: percentages[index] / 100,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8C52FF)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              sizes[index],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${percentages[index]}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _createBackup(String type) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create $type Backup'),
        content: Text(
            'Are you sure you want to create a $type backup? This may take several minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$type backup started')),
              );
            },
            child: const Text('Start Backup'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export User Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'User ID or Email',
                hintText: 'user@example.com',
              ),
            ),
            SizedBox(height: 16),
            Text(
                'This will export all data for the specified user in compliance with GDPR requirements.'),
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
                const SnackBar(content: Text('User data export started')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Import Data'),
        content: Text(
            'Data import functionality will be implemented based on requirements.'),
      ),
    );
  }

  void _showTransformDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Data Transformation'),
        content: Text(
            'Data transformation tools will be implemented based on requirements.'),
      ),
    );
  }

  void _syncDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Database sync started')),
    );
  }

  void _cleanOrphanedData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orphaned data cleanup started')),
    );
  }

  void _removeDuplicates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate removal started')),
    );
  }

  void _archiveOldData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data archiving started')),
    );
  }

  void _handleBackupAction(Object? value, int index) {
    String message;
    switch (value) {
      case 'download':
        message = 'Downloading backup ${index + 1}';
        break;
      case 'restore':
        message = 'Restoring from backup ${index + 1}';
        break;
      case 'delete':
        message = 'Deleted backup ${index + 1}';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _retryMigration(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Retrying migration ${index + 1}')),
    );
  }
}
