import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';

/// Admin System Alerts Screen
/// Handles system notifications, alerts, and monitoring
class AdminSystemAlertsScreen extends StatefulWidget {
  const AdminSystemAlertsScreen({super.key});

  @override
  State<AdminSystemAlertsScreen> createState() =>
      _AdminSystemAlertsScreenState();
}

class _AdminSystemAlertsScreenState extends State<AdminSystemAlertsScreen> {
  final List<String> _tabs = [
    'Active Alerts',
    'Alert History',
    'Alert Settings',
    'Monitoring'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'System Alerts',
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
            _buildActiveAlertsTab(),
            _buildAlertHistoryTab(),
            _buildAlertSettingsTab(),
            _buildMonitoringTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlertsTab() {
    return Column(
      children: [
        // Alert Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '5 critical, 12 warning, 8 info alerts',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _acknowledgeAllAlerts(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Acknowledge All'),
              ),
            ],
          ),
        ),

        // Alert Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: 'All',
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['All', 'Critical', 'Warning', 'Info']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: 'All',
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['All', 'System', 'Security', 'Performance', 'Storage']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),

        // Alert List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 10,
            itemBuilder: (context, index) => _buildActiveAlertCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertHistoryTab() {
    return Column(
      children: [
        // History Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search alerts...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: 'Last 7 days',
                items: [
                  'Last 24 hours',
                  'Last 7 days',
                  'Last 30 days',
                  'All time'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),

        // History List
        Expanded(
          child: ListView.builder(
            itemCount: 25,
            itemBuilder: (context, index) => _buildHistoryAlertCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Global Alert Settings
          const Text(
            'Global Alert Settings',
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
                    title: const Text('Enable System Alerts'),
                    subtitle: const Text('Receive system-level alerts'),
                    value: true,
                    onChanged: (value) {},
                    activeThumbColor: const Color(0xFF8C52FF),
                  ),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Send alerts via email'),
                    value: true,
                    onChanged: (value) {},
                    activeThumbColor: const Color(0xFF8C52FF),
                  ),
                  SwitchListTile(
                    title: const Text('SMS Notifications'),
                    subtitle: const Text('Send critical alerts via SMS'),
                    value: false,
                    onChanged: (value) {},
                    activeThumbColor: const Color(0xFF8C52FF),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Alert Rules
          const Text(
            'Alert Rules',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (index) => _buildAlertRuleCard(index)),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateRuleDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create New Rule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C52FF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Status
          const Text(
            'System Status',
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
                  'System Health',
                  '98%',
                  Icons.health_and_safety,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'Uptime',
                  '99.9%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Response Time',
                  '245ms',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusCard(
                  'Error Rate',
                  '0.1%',
                  Icons.error_outline,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Service Status
          const Text(
            'Service Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(6, (index) => _buildServiceStatusCard(index)),

          const SizedBox(height: 24),

          // Performance Chart
          const Text(
            'Performance Trends',
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
                'Performance Chart\n(Integration with monitoring service required)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAlertCard(int index) {
    final severities = ['Critical', 'Warning', 'Info', 'Critical', 'Warning'];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.orange
    ];
    final alerts = [
      'Database connection timeout',
      'High memory usage detected',
      'Scheduled backup completed',
      'Failed login attempts spike',
      'API response time increased',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getAlertIcon(severities[index % severities.length]),
          color: colors[index % colors.length],
        ),
        title: Text(alerts[index % alerts.length]),
        subtitle: Text(
          '${severities[index % severities.length]} • 2024-12-24 ${10 + index}:${(index * 5).toString().padLeft(2, '0')}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'acknowledge', child: Text('Acknowledge')),
            const PopupMenuItem(value: 'resolve', child: Text('Resolve')),
            const PopupMenuItem(value: 'escalate', child: Text('Escalate')),
          ],
          onSelected: (value) => _handleAlertAction(value, index),
        ),
        onTap: () => _showAlertDetails(index),
      ),
    );
  }

  Widget _buildHistoryAlertCard(int index) {
    final statuses = [
      'Resolved',
      'Acknowledged',
      'Escalated',
      'Resolved',
      'Acknowledged'
    ];
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.blue
    ];

    return ListTile(
      dense: true,
      leading: Icon(
        _getStatusIcon(statuses[index % statuses.length]),
        color: colors[index % colors.length],
        size: 20,
      ),
      title: Text('Alert ${index + 1}'),
      subtitle: Text(
          '${statuses[index % statuses.length]} • 2024-12-${(20 - index).toString().padLeft(2, '0')}'),
      onTap: () => _showAlertDetails(index),
    );
  }

  Widget _buildAlertRuleCard(int index) {
    final rules = [
      'CPU Usage > 80%',
      'Memory Usage > 90%',
      'Failed Logins > 10/min',
      'API Response > 1000ms',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.rule, color: Color(0xFF8C52FF)),
        title: Text(rules[index]),
        subtitle: Text(
            'Severity: ${index % 2 == 0 ? 'Critical' : 'Warning'} • Active'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'disable', child: Text('Disable')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) => _handleRuleAction(value, index),
        ),
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

  Widget _buildServiceStatusCard(int index) {
    final services = [
      'Authentication Service',
      'Database Service',
      'File Storage Service',
      'Email Service',
      'Payment Service',
      'Analytics Service',
    ];
    final statuses = [
      'Online',
      'Online',
      'Degraded',
      'Online',
      'Online',
      'Maintenance'
    ];
    final colors = [
      Colors.green,
      Colors.green,
      Colors.orange,
      Colors.green,
      Colors.green,
      Colors.blue
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colors[index],
            shape: BoxShape.circle,
          ),
        ),
        title: Text(services[index]),
        trailing: Text(
          statuses[index],
          style: TextStyle(
            color: colors[index],
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _showServiceDetails(services[index], statuses[index]),
      ),
    );
  }

  IconData _getAlertIcon(String severity) {
    switch (severity) {
      case 'Critical':
        return Icons.error;
      case 'Warning':
        return Icons.warning;
      case 'Info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Resolved':
        return Icons.check_circle;
      case 'Acknowledged':
        return Icons.visibility;
      case 'Escalated':
        return Icons.arrow_upward;
      default:
        return Icons.help;
    }
  }

  void _acknowledgeAllAlerts() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acknowledge All Alerts'),
        content: const Text(
            'Are you sure you want to acknowledge all active alerts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All alerts acknowledged')),
              );
            },
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  void _handleAlertAction(Object? value, int index) {
    String message;
    switch (value) {
      case 'acknowledge':
        message = 'Alert ${index + 1} acknowledged';
        break;
      case 'resolve':
        message = 'Alert ${index + 1} resolved';
        break;
      case 'escalate':
        message = 'Alert ${index + 1} escalated';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleRuleAction(Object? value, int index) {
    String message;
    switch (value) {
      case 'edit':
        message = 'Edit rule ${index + 1}';
        break;
      case 'disable':
        message = 'Rule ${index + 1} disabled';
        break;
      case 'delete':
        message = 'Rule ${index + 1} deleted';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAlertDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alert Details - Alert ${index + 1}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timestamp: 2024-12-24 10:30:00'),
            Text('Severity: Critical'),
            Text('Category: System'),
            Text('Source: Database Monitor'),
            SizedBox(height: 8),
            Text(
                'Description: Database connection timeout detected. Multiple connection attempts failed.'),
            SizedBox(height: 8),
            Text('Recommended Actions:'),
            Text('• Check database server status'),
            Text('• Review connection pool settings'),
            Text('• Monitor network connectivity'),
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

  void _showServiceDetails(String service, String status) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            const Text('Last Updated: 2024-12-24 10:35:00'),
            const Text('Response Time: 250ms'),
            const Text('Uptime: 99.8%'),
            if (status == 'Degraded') ...[
              const SizedBox(height: 8),
              const Text('Issues: Increased response time'),
              const Text('ETA: 30 minutes'),
            ],
            if (status == 'Maintenance') ...[
              const SizedBox(height: 8),
              const Text('Maintenance Window: 10:00 - 12:00'),
              const Text('Expected Duration: 2 hours'),
            ],
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

  void _showCreateRuleDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Alert Rule'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Rule Name',
                hintText: 'High CPU Usage',
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Condition',
                hintText: 'cpu_usage > 80',
              ),
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'CPU usage is above 80%',
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
                const SnackBar(content: Text('Alert rule created')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
