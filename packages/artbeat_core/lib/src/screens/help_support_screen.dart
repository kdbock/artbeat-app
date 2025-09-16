import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/artbeat_colors.dart';
import '../widgets/enhanced_universal_header.dart';

/// Help & Support Screen - Comprehensive guide for ARTbeat users
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Help & Support',
        showLogo: false,
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search help topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Help topics
                  ..._buildHelpSections(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ArtbeatColors.primary.withValues(alpha: 0.1),
            ArtbeatColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette, color: ArtbeatColors.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome to ARTbeat',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your All-in-One Art Platform',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ArtbeatColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to ARTbeat, the premier application designed to connect the global art community. Whether you\'re an art enthusiast exploring local masterpieces, an artist showcasing your portfolio, a gallery managing talent, or an administrator overseeing the platform, ARTbeat provides a rich, integrated experience.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Contact Support',
                icon: Icons.support_agent,
                onTap: () => _contactSupport(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Report Issue',
                icon: Icons.bug_report,
                onTap: () => _reportIssue(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Video Tutorials',
                icon: Icons.play_circle_fill,
                onTap: () => _openVideoTutorials(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Community Forum',
                icon: Icons.forum,
                onTap: () => _openCommunityForum(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: ArtbeatColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHelpSections() {
    final sections = [
      _buildSection(
        'Getting Started & Account Management',
        'Set up your account and get familiar with ARTbeat',
        Icons.person_add,
        [
          'Registration & Login: Create your account using email and password, verify your email, and set up your profile',
          'User Types: ARTbeat supports Regular Users, Artists, Galleries, Moderators, and Admins with different access levels',
          'Profile Creation: Set up your identity on the platform with personalized information',
        ],
      ),
      _buildSection(
        'Discovering & Experiencing Art',
        'Find and experience art in interactive ways',
        Icons.explore,
        [
          'Art Walks: Discover guided art adventures with GPS navigation and gamification features',
          'Artwork Browsing: Browse comprehensive art database with filtering and search',
          'Events: Find exhibitions, workshops, and art events with ticketing integration',
          'Capturing Inspiration: Take photos and contribute to public art collections',
        ],
      ),
      _buildSection(
        'For Artists & Galleries',
        'Manage your creative career and business',
        Icons.palette,
        [
          'Artist Dashboard: View sales, engagement metrics, and manage your portfolio',
          'Gallery Operations: Manage artist rosters, track performance, and handle commissions',
          'Earnings & Financial Management: Track revenue, request payouts, and manage payments',
          'Advertising & Marketing: Create campaigns and track performance',
          'Subscription Tiers: Free, Starter (\$4.99), Creator (\$12.99), Business (\$29.99), Enterprise (\$79.99)',
        ],
      ),
      _buildSection(
        'Community & Social Features',
        'Connect and engage with the art community',
        Icons.people,
        [
          'Community Feed: Create posts, engage with content using the Applause System',
          'Direct Commissions: Manage custom art requests and negotiations',
          'Studio System: Create collaborative workspaces with real-time messaging',
          'Profile Features: Customize your profile and manage connections',
          'Messaging System: Real-time chat with advanced features',
          'Gifts: Send themed monetary gifts and create gift campaigns',
        ],
      ),
      _buildSection(
        'AI-Powered Features',
        'Enhance your workflow with artificial intelligence',
        Icons.auto_awesome,
        [
          'Smart Cropping: Automatically crop images for optimal composition (1 AI credit)',
          'Background Removal: Remove backgrounds from artwork images (2 AI credits)',
          'Auto-Tagging: Generate relevant tags for artwork (1 AI credit)',
          'Color Palette Extraction: Extract dominant colors (1 AI credit)',
          'Content Recommendations: Get personalized suggestions (2 AI credits)',
          'Performance Insights: AI-driven analytics (3 AI credits)',
          'Similar Artwork Detection: Find visually similar artworks (2 AI credits)',
        ],
      ),
      _buildSection(
        'Settings & Security',
        'Manage your preferences and security',
        Icons.security,
        [
          'Account Settings: Edit profile, manage email/phone, upload pictures',
          'Privacy Controls: Control profile visibility, content privacy, data privacy',
          'Security Settings: Two-Factor Authentication, login history, device management',
          'Notification Settings: Granular controls for email, push, and in-app notifications',
          'Blocked Users: Manage blocked users and privacy settings',
        ],
      ),
      _buildSection(
        'Admin & Moderation Tools',
        'Platform administration and content management',
        Icons.admin_panel_settings,
        [
          'Admin Dashboard: Central command center with real-time metrics',
          'User Management: Complete user lifecycle management',
          'Content Moderation: Unified moderation hub for all content types',
          'Events Management: Event approval workflows and analytics',
          'Advertising Management: Ad administration with revenue tracking',
          'Financial Analytics: Revenue tracking and reporting',
          'System Administration: Settings, data management, security center',
        ],
      ),
    ];

    final List<Widget> filteredSections = [];
    for (final section in sections) {
      if (_searchQuery.isEmpty ||
          section.toString().toLowerCase().contains(_searchQuery)) {
        filteredSections.add(section);
      }
    }

    return filteredSections;
  }

  Widget _buildSection(
    String title,
    String description,
    IconData icon,
    List<String> items,
  ) {
    // Filter items based on search query
    List<String> filteredItems = items;
    if (_searchQuery.isNotEmpty) {
      filteredItems = items
          .where((item) => item.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // If search is active and no items match, don't show the section
    if (_searchQuery.isNotEmpty && filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon, color: ArtbeatColors.primary),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: ArtbeatColors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: filteredItems.map((item) {
                // Highlight search terms
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: ArtbeatColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    const email = 'support@artbeat.com';
    const subject = 'ARTbeat Support Request';
    final uri = Uri(scheme: 'mailto', path: email, query: 'subject=$subject');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email client. Please contact support@artbeat.com',
            ),
          ),
        );
      }
    }
  }

  Future<void> _reportIssue() async {
    // Navigate to feedback screen or show dialog
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: const Text(
          'To report an issue, please use the feedback form in Settings or contact our support team directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  Future<void> _openVideoTutorials() async {
    const url = 'https://youtube.com/@artbeat';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video tutorials')),
        );
      }
    }
  }

  Future<void> _openCommunityForum() async {
    const url = 'https://community.artbeat.com';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open community forum')),
        );
      }
    }
  }
}
