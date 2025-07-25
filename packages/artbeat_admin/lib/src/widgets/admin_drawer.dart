import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
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
          final headerHeight = availableHeight > 600 ? 180.0 : 140.0;
          
          return Column(
            children: [
              // Custom drawer header with admin branding
              Container(
                height: headerHeight, // Dynamic height based on available space
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _headerColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16), // Reduced padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Admin icon
                    Container(
                      width: availableHeight > 600 ? 60 : 50, // Responsive size
                      height: availableHeight > 600 ? 60 : 50, // Responsive size
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
                        size: availableHeight > 600 ? 30 : 25, // Responsive size
                        color: _iconTextColor,
                      ),
                    ),
                    SizedBox(height: availableHeight > 600 ? 12 : 8), // Responsive spacing
                    // Title
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: _iconTextColor,
                        fontFamily: 'Limelight',
                        fontSize: availableHeight > 600 ? 20 : 18, // Responsive font size
                        fontWeight: FontWeight.normal,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Management Console',
                      style: TextStyle(
                        color: _iconTextColor.withValues(alpha: 0.8),
                        fontSize: availableHeight > 600 ? 12 : 10, // Responsive font size
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable menu items
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableHeight - headerHeight - 20, // Reserve space for header and padding
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                // Core menu items
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/admin/dashboard',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people,
                  title: 'User Management',
                  route: '/admin/users',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.report,
                  title: 'Content Review',
                  route: '/admin/content-review',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics,
                  title: 'Analytics',
                  route: '/admin/analytics',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: '/admin/settings',
                ),

                const Divider(height: 16), // Reduced height

                // Additional admin tools
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

                const Divider(height: 16), // Reduced height

                // Developer tools
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

                const Divider(height: 16), // Reduced height

                // Footer items
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
          )],
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
                  // Navigate to API console
                },
              ),
              ListTile(
                leading: const Icon(Icons.storage, color: _headerColor),
                title: const Text('Database Tools'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to database tools
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: _headerColor),
                title: const Text('Performance Monitor'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to performance monitor
                },
              ),
              ListTile(
                leading: const Icon(Icons.memory, color: _headerColor),
                title: const Text('Memory Usage'),
                onTap: () {
                  Navigator.pop(context);
                  // Show memory usage
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
                  // Show system health
                },
              ),
              ListTile(
                leading: const Icon(Icons.network_check, color: _headerColor),
                title: const Text('Network Status'),
                onTap: () {
                  Navigator.pop(context);
                  // Show network status
                },
              ),
              ListTile(
                leading: const Icon(Icons.error_outline, color: _headerColor),
                title: const Text('Error Logs'),
                onTap: () {
                  Navigator.pop(context);
                  // Show error logs
                },
              ),
              ListTile(
                leading: const Icon(Icons.timeline, color: _headerColor),
                title: const Text('Performance Metrics'),
                onTap: () {
                  Navigator.pop(context);
                  // Show performance metrics
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
