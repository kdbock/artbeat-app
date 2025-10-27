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
                    // Artbeat Home button - navigate to main app dashboard
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      title: 'Artbeat Home',
                      route: '/dashboard',
                      subtitle: 'Return to main app',
                    ),

                    const Divider(height: 16),

                    // Main Admin Dashboard - All-in-One Interface
                    _buildSectionHeader('Admin Dashboard'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'Unified Dashboard',
                      route: '/admin/dashboard',
                      subtitle: 'All admin functions in one place',
                    ),

                    const Divider(height: 16),

                    // Business Management Section
                    _buildSectionHeader('Business Management'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.local_offer,
                      title: 'Coupon Management',
                      route: '/admin/coupons',
                      subtitle: 'Create and manage discount coupons',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.payment,
                      title: 'Payment Management',
                      route: '/admin/payments',
                      subtitle: 'Transaction & refund management',
                    ),

                    const Divider(height: 16),

                    // Content Management Section
                    _buildSectionHeader('Content Management'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.content_paste,
                      title: 'Content Moderation',
                      route:
                          '/admin/dashboard', // Unified dashboard handles content moderation
                      subtitle: 'Review and moderate user content',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.photo_library,
                      title: 'Capture Moderation',
                      route: '/capture/admin/moderation',
                      subtitle: 'Moderate captures and manage reports',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.route,
                      title: 'Art Walk Moderation',
                      route: '/artwalk/admin/moderation',
                      subtitle: 'Moderate art walks and manage reports',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people,
                      title: 'User Management',
                      route:
                          '/admin/dashboard', // Unified dashboard handles user management
                      subtitle: 'Manage user accounts and profiles',
                    ),

                    const Divider(height: 16),

                    // System Management Section
                    _buildSectionHeader('System Management'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings,
                      title: 'Admin Settings',
                      route: '/admin/settings',
                      subtitle: 'System configuration',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.security,
                      title: 'Security Center',
                      route: '/admin/security',
                      subtitle: 'Security monitoring and controls',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.monitor,
                      title: 'System Monitoring',
                      route: '/admin/monitoring',
                      subtitle: 'Real-time system metrics',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.sync_alt,
                      title: 'Data Migration',
                      route: '/admin/migration',
                      subtitle: 'Run database migrations',
                    ),

                    const Divider(height: 16),

                    // Developer Tools Section
                    _buildSectionHeader('Developer Tools'),
                    _buildDrawerItem(
                      context,
                      icon: Icons.upload_file,
                      title: 'Data Upload Tools',
                      route: '/dev',
                      subtitle: 'Bulk upload content and data',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.feedback,
                      title: 'Developer Feedback',
                      route: '/developer-feedback-admin',
                      subtitle: 'View developer feedback and reports',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Upload Tools',
                      route: '/dev', // Developer menu has admin upload tools
                      subtitle: 'Upload users, content, and data',
                    ),

                    const Divider(height: 16),

                    // Support & Account Section
                    _buildSectionHeader('Support & Account'),
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
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            )
          : null,
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
