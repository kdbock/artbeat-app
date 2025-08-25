import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';

/// Admin Help & Support Screen
/// Provides documentation, tutorials, and support resources for admin users
class AdminHelpSupportScreen extends StatefulWidget {
  const AdminHelpSupportScreen({super.key});

  @override
  State<AdminHelpSupportScreen> createState() => _AdminHelpSupportScreenState();
}

class _AdminHelpSupportScreenState extends State<AdminHelpSupportScreen> {
  final List<String> _tabs = [
    'Documentation',
    'Tutorials',
    'Support Tickets',
    'Contact'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Help & Support',
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
            _buildDocumentationTab(),
            _buildTutorialsTab(),
            _buildSupportTicketsTab(),
            _buildContactTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Access
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildQuickAccessCard(
                'Getting Started',
                Icons.rocket_launch,
                'New admin onboarding guide',
              ),
              _buildQuickAccessCard(
                'User Management',
                Icons.people,
                'Managing users and permissions',
              ),
              _buildQuickAccessCard(
                'Content Moderation',
                Icons.gavel,
                'Content review and moderation',
              ),
              _buildQuickAccessCard(
                'Analytics Guide',
                Icons.analytics,
                'Understanding analytics data',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Documentation Categories
          const Text(
            'Documentation Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(6, (index) => _buildDocumentationCategory(index)),
        ],
      ),
    );
  }

  Widget _buildTutorialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Tutorials
          const Text(
            'Featured Tutorials',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) =>
                  _buildFeaturedTutorialCard(index),
            ),
          ),
          const SizedBox(height: 24),

          // Tutorial Categories
          const Text(
            'Tutorial Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildTutorialCategory(index)),
        ],
      ),
    );
  }

  Widget _buildSupportTicketsTab() {
    return Column(
      children: [
        // Create Ticket Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateTicketDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Support Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C52FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),

        // Ticket Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: 'All',
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['All', 'Open', 'In Progress', 'Resolved', 'Closed']
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
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['All', 'Low', 'Medium', 'High', 'Critical']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),

        // Tickets List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (context, index) => _buildSupportTicketCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Contact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'Emergency Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('For critical system issues affecting production:'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _makeCall('+1-800-SUPPORT'),
                      child: const Text(
                        '+1-800-SUPPORT',
                        style: TextStyle(
                          color: Colors.red,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendEmail('emergency@artbeat.com'),
                      child: const Text(
                        'emergency@artbeat.com',
                        style: TextStyle(
                          color: Colors.red,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Support Team
          const Text(
            'Support Team',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (index) => _buildSupportTeamCard(index)),

          const SizedBox(height: 24),

          // Contact Methods
          const Text(
            'Contact Methods',
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
                  leading: const Icon(Icons.email, color: Color(0xFF8C52FF)),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@artbeat.com'),
                  trailing: const Text('24-48 hours'),
                  onTap: () => _sendEmail('support@artbeat.com'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF8C52FF)),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Available 9 AM - 6 PM EST'),
                  trailing: const Text('Instant'),
                  onTap: () => _openLiveChat(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.forum, color: Color(0xFF8C52FF)),
                  title: const Text('Community Forum'),
                  subtitle: const Text('Get help from other admins'),
                  trailing: const Text('Variable'),
                  onTap: () => _openForum(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Knowledge Base Search
          const Text(
            'Knowledge Base Search',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C52FF),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for help articles...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: ElevatedButton(
                onPressed: () => _searchKnowledgeBase(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8C52FF),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
                child: const Text('Search'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
      String title, IconData icon, String description) {
    return Card(
      child: InkWell(
        onTap: () => _openDocumentation(title),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF8C52FF), size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentationCategory(int index) {
    final categories = [
      'System Administration',
      'User Management',
      'Content Moderation',
      'Analytics & Reporting',
      'Security & Privacy',
      'API Documentation',
    ];
    final descriptions = [
      'Server management, backups, and system configuration',
      'User accounts, permissions, and role management',
      'Content review, moderation tools, and policies',
      'Analytics dashboards, reports, and data interpretation',
      'Security settings, privacy controls, and compliance',
      'API endpoints, authentication, and integration guides',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.folder_open, color: Color(0xFF8C52FF)),
        title: Text(categories[index]),
        subtitle: Text(descriptions[index]),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDocumentationCategory(categories[index]),
      ),
    );
  }

  Widget _buildFeaturedTutorialCard(int index) {
    final tutorials = [
      'Admin Panel Overview',
      'User Management Basics',
      'Content Moderation',
      'Analytics Dashboard',
    ];
    final durations = ['15 min', '20 min', '25 min', '18 min'];

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        child: InkWell(
          onTap: () => _playTutorial(tutorials[index]),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.play_circle, size: 48, color: Color(0xFF8C52FF)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorials[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durations[index],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCategory(int index) {
    final categories = [
      'Getting Started',
      'User Management',
      'Content Management',
      'Analytics',
      'Advanced Features',
    ];
    final counts = [5, 8, 12, 6, 4];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.play_circle, color: Color(0xFF8C52FF)),
        title: Text(categories[index]),
        subtitle: Text('${counts[index]} tutorials'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openTutorialCategory(categories[index]),
      ),
    );
  }

  Widget _buildSupportTicketCard(int index) {
    final titles = [
      'Unable to access user analytics',
      'Content moderation question',
      'Database backup failed',
      'API integration issue',
      'Permission error on admin panel',
      'Email notifications not working',
      'Performance issues with dashboard',
      'Security question about user data',
    ];
    final statuses = [
      'Open',
      'In Progress',
      'Resolved',
      'Open',
      'Closed',
      'In Progress',
      'Open',
      'Resolved'
    ];
    final priorities = [
      'High',
      'Medium',
      'Low',
      'Critical',
      'Medium',
      'High',
      'Low',
      'Medium'
    ];
    final colors = {
      'Open': Colors.blue,
      'In Progress': Colors.orange,
      'Resolved': Colors.green,
      'Closed': Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.support_agent,
          color: colors[statuses[index]] ?? Colors.blue,
        ),
        title: Text(titles[index]),
        subtitle: Text(
            'Priority: ${priorities[index]} | Created: 2024-12-${(20 + index).toString().padLeft(2, '0')}'),
        trailing: Chip(
          label: Text(statuses[index]),
          backgroundColor:
              (colors[statuses[index]] ?? Colors.blue).withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: colors[statuses[index]] ?? Colors.blue,
            fontSize: 12,
          ),
        ),
        onTap: () => _viewTicketDetails(index),
      ),
    );
  }

  Widget _buildSupportTeamCard(int index) {
    final team = [
      {
        'name': 'Sarah Johnson',
        'role': 'Lead Support Engineer',
        'email': 'sarah.j@artbeat.com'
      },
      {
        'name': 'Mike Chen',
        'role': 'Technical Support Specialist',
        'email': 'mike.c@artbeat.com'
      },
      {
        'name': 'Emma Wilson',
        'role': 'Admin System Expert',
        'email': 'emma.w@artbeat.com'
      },
      {
        'name': 'David Kim',
        'role': 'Security Support Specialist',
        'email': 'david.k@artbeat.com'
      },
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8C52FF),
          child: Text(team[index]['name']![0]),
        ),
        title: Text(team[index]['name']!),
        subtitle: Text(team[index]['role']!),
        trailing: IconButton(
          icon: const Icon(Icons.email),
          onPressed: () => _sendEmail(team[index]['email']!),
        ),
      ),
    );
  }

  void _openDocumentation(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening documentation: $title')),
    );
  }

  void _openDocumentationCategory(String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening documentation category: $category')),
    );
  }

  void _playTutorial(String tutorial) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing tutorial: $tutorial')),
    );
  }

  void _openTutorialCategory(String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening tutorial category: $category')),
    );
  }

  void _showCreateTicketDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Support Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Brief description of the issue',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Detailed description of the problem',
                ),
                maxLines: 4,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Priority',
                ),
                items: ['Low', 'Medium', 'High', 'Critical']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
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
                const SnackBar(content: Text('Support ticket created')),
              );
            },
            child: const Text('Create Ticket'),
          ),
        ],
      ),
    );
  }

  void _viewTicketDetails(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket #${1000 + index}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: Unable to access user analytics'),
            Text('Status: Open'),
            Text('Priority: High'),
            Text('Created: 2024-12-20 14:30'),
            Text('Assigned to: Sarah Johnson'),
            SizedBox(height: 8),
            Text(
                'Description: I am unable to access the user analytics dashboard. The page loads but shows no data.'),
            SizedBox(height: 8),
            Text('Last Update: Investigating the issue...'),
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

  void _makeCall(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone')),
    );
  }

  void _sendEmail(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening email to $email')),
    );
  }

  void _openLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening live chat')),
    );
  }

  void _openForum() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening community forum')),
    );
  }

  void _searchKnowledgeBase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Searching knowledge base')),
    );
  }
}
