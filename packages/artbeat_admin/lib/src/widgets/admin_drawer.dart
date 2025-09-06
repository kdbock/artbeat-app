import 'package:flutter/material.dart';
import 'package:artbeat_core/src/services/auth_service.dart';

/// Admin Package Specific Drawer
///
/// Color: #8c52ff (140, 82, 255)
/// Text/Icon Color: #00bf63
/// Font: Limelight
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  static const Color _headerColor = Color(0xFF8C52FF); // Admin header color
  static const Color _iconTextColor = Color(0xFF00BF63); // Text/Icon color

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height and adjust header accordingly
          final availableHeight = constraints.maxHeight;
          final isCompact = availableHeight < 400;

          return Column(
            children: [
              // Custom drawer header with admin branding - flexible height
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: isCompact ? 80 : 120,
                  maxHeight:
                      availableHeight * 0.3, // Use 30% of available height
                ),
                decoration: const BoxDecoration(
                  color: _headerColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 8 : 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Admin icon
                        Container(
                          width: isCompact ? 40 : 50,
                          height: isCompact ? 40 : 50,
                          decoration: BoxDecoration(
                            color: _iconTextColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _iconTextColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: isCompact ? 20 : 25,
                            color: _iconTextColor,
                          ),
                        ),
                        SizedBox(height: isCompact ? 4 : 8),
                        // Title
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: _iconTextColor,
                            fontFamily: 'Limelight',
                            fontSize: isCompact ? 14 : 18,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Management Console',
                            style: TextStyle(
                              color: _iconTextColor.withValues(alpha: 0.8),
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Scrollable menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    // Overview Section
                    _buildSectionHeader('Overview'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      route: '/admin/dashboard',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.attach_money,
                      title: 'Financial Analytics',
                      route: '/admin/financial-analytics',
                    ),

                    const Divider(height: 16),

                    // User Management Section
                    _buildSectionHeader('User Management'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.manage_accounts,
                      title: 'User Management',
                      route: '/admin/user-management',
                    ),

                    const Divider(height: 16),

                    // Content Management Section
                    _buildSectionHeader('Content Management'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.rate_review,
                      title: 'Content Review',
                      route: '/admin/content-review',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.content_copy,
                      title: 'Advanced Content Management',
                      route: '/admin/advanced-content-management',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.campaign,
                      title: 'Ads Management',
                      route: '/admin/ads-management',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.event,
                      title: 'Events Management',
                      route: '/admin/events-management',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people_alt,
                      title: 'Community Moderation',
                      route: '/admin/community-moderation',
                    ),

                    const Divider(height: 16),

                    // Analytics Section
                    _buildSectionHeader('Analytics'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.analytics,
                      title: 'Analytics',
                      route: '/admin/analytics',
                    ),

                    const Divider(height: 16),

                    // System Management Section
                    _buildSectionHeader('System Management'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.security,
                      title: 'Security Center',
                      route: '/admin/security',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.backup,
                      title: 'Data Management',
                      route: '/admin/data',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.notifications,
                      title: 'System Alerts',
                      route: '/admin/alerts',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.sync_alt,
                      title: 'Data Migration',
                      route: '/admin/migration',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings,
                      title: 'Settings',
                      route: '/admin/settings',
                    ),

                    const Divider(height: 16),

                    // Developer Tools Section
                    _buildSectionHeader('Developer Tools'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.developer_mode,
                      title: 'Developer Tools',
                      onTap: () => _showDeveloperTools(context),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.bug_report,
                      title: 'System Diagnostics',
                      onTap: () => _showSystemDiagnostics(context),
                    ),

                    const Divider(height: 16),

                    // Support & Account Section
                    _buildSectionHeader('Support & Account'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      route: '/admin/help',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => _handleLogout(context),
                      isDestructive: true,
                    ),
                    const SizedBox(height: 16), // Bottom padding
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : _headerColor;

    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 22, // Reduced icon size
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 14, // Reduced font size
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap ??
          () {
            Navigator.pop(context); // Close drawer
            if (route != null) {
              Navigator.pushNamed(context, route);
            }
          },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: color.withValues(alpha: 0.1),
      splashColor: color.withValues(alpha: 0.2),
    );
  }

  void _showDeveloperTools(BuildContext context) {
    Navigator.pop(context); // Close drawer
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Developer Tools',
          style: TextStyle(
            fontFamily: 'Limelight',
            color: _headerColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.code, color: _headerColor),
                title: const Text('API Console'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.storage, color: _headerColor),
                title: const Text('Database Tools'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/data');
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: _headerColor),
                title: const Text('Performance Monitor'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/analytics');
                },
              ),
              ListTile(
                leading: const Icon(Icons.memory, color: _headerColor),
                title: const Text('Memory Usage'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/alerts');
                },
              ),
            ],
          ),
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

  void _showSystemDiagnostics(BuildContext context) {
    Navigator.pop(context); // Close drawer
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'System Diagnostics',
          style: TextStyle(
            fontFamily: 'Limelight',
            color: _headerColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.health_and_safety, color: _headerColor),
                title: const Text('System Health'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/alerts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.network_check, color: _headerColor),
                title: const Text('Network Status'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/security');
                },
              ),
              ListTile(
                leading: const Icon(Icons.error_outline, color: _headerColor),
                title: const Text('Error Logs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/alerts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.timeline, color: _headerColor),
                title: const Text('Performance Metrics'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/analytics');
                },
              ),
            ],
          ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _headerColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.pop(context); // Close drawer
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content:
            const Text('Are you sure you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Handle logout logic using AuthService from artbeat_core
                final authService = AuthService();
                await authService.signOut();

                // Navigate to login screen
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/admin/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                // Handle logout error
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
