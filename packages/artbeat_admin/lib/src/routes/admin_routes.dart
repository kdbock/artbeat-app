import 'package:flutter/material.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import '../screens/admin_login_screen.dart';
import '../screens/admin_enhanced_dashboard_screen.dart';
import '../screens/admin_financial_analytics_screen.dart';
import '../screens/admin_advanced_user_management_screen.dart';
import '../screens/admin_advanced_content_management_screen.dart';
import '../screens/admin_user_detail_screen.dart';
import '../screens/enhanced_admin_content_review_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/admin_coupon_management_screen.dart';
import '../screens/admin_security_center_screen.dart';
import '../screens/admin_data_management_screen.dart';
import '../screens/admin_system_alerts_screen.dart';
import '../screens/admin_help_support_screen.dart';
import '../screens/migration_screen.dart';
import '../models/user_admin_model.dart';

/// Admin routing configuration for the ARTbeat admin system
class AdminRoutes {
  static const String dashboard = '/admin/dashboard';
  static const String enhancedDashboard = '/admin/enhanced-dashboard';
  static const String financialAnalytics = '/admin/financial-analytics';
  static const String userManagement = '/admin/user-management';
  static const String advancedUserManagement =
      '/admin/advanced-user-management';
  static const String userDetail = '/admin/user-detail';
  static const String contentReview = '/admin/content-review';
  static const String enhancedContentReview = '/admin/enhanced-content-review';
  static const String advancedContentManagement =
      '/admin/advanced-content-management';
  static const String analytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';
  static const String adManagement = '/admin/ad-management';
  static const String couponManagement = '/admin/coupon-management';
  static const String securityCenter = '/admin/security';
  static const String dataManagement = '/admin/data';
  static const String systemAlerts = '/admin/alerts';
  static const String helpSupport = '/admin/help';
  static const String migration = '/admin/migration';
  static const String login = '/admin/login';

  /// Generate routes for the admin system
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        // Redirect to enhanced dashboard
        return MaterialPageRoute<void>(
          builder: (_) => const AdminEnhancedDashboardScreen(),
          settings: settings,
        );

      case enhancedDashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminEnhancedDashboardScreen(),
          settings: settings,
        );

      case financialAnalytics:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminFinancialAnalyticsScreen(),
          settings: settings,
        );

      case userManagement:
        // Redirect to advanced user management
        return MaterialPageRoute<void>(
          builder: (_) => const AdminAdvancedUserManagementScreen(),
          settings: settings,
        );

      case advancedUserManagement:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminAdvancedUserManagementScreen(),
          settings: settings,
        );

      case userDetail:
        final user = settings.arguments as UserAdminModel?;
        if (user == null) {
          return _errorRoute('User data is required');
        }
        return MaterialPageRoute<void>(
          builder: (_) => AdminUserDetailScreen(user: user),
          settings: settings,
        );

      case contentReview:
        return MaterialPageRoute<void>(
          builder: (_) => const EnhancedAdminContentReviewScreen(),
          settings: settings,
        );

      case enhancedContentReview:
        return MaterialPageRoute<void>(
          builder: (_) => const EnhancedAdminContentReviewScreen(),
          settings: settings,
        );

      case advancedContentManagement:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminAdvancedContentManagementScreen(),
          settings: settings,
        );

      case analytics:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminAnalyticsScreen(),
          settings: settings,
        );

      case adminSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminSettingsScreen(),
          settings: settings,
        );

      case adManagement:
        return MaterialPageRoute<void>(
          builder: (_) => const SimpleAdManagementScreen(),
          settings: settings,
        );

      case couponManagement:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminCouponManagementScreen(),
          settings: settings,
        );

      case securityCenter:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminSecurityCenterScreen(),
          settings: settings,
        );

      case dataManagement:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminDataManagementScreen(),
          settings: settings,
        );

      case systemAlerts:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminSystemAlertsScreen(),
          settings: settings,
        );

      case helpSupport:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminHelpSupportScreen(),
          settings: settings,
        );

      case migration:
        return MaterialPageRoute<void>(
          builder: (_) => const MigrationScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminLoginScreen(),
          settings: settings,
        );

      default:
        // Return null for unrecognized admin routes so main app can handle them
        return null;
    }
  }

  /// Create an error route
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Navigation Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(_).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get all available admin routes
  static List<AdminRoute> getAllRoutes() {
    return [
      const AdminRoute(
        name: 'Dashboard',
        route: dashboard,
        icon: Icons.dashboard,
        description: 'Main admin dashboard with overview metrics',
        category: AdminRouteCategory.overview,
      ),
      const AdminRoute(
        name: 'Enhanced Dashboard',
        route: enhancedDashboard,
        icon: Icons.dashboard_customize,
        description: 'Advanced dashboard with comprehensive analytics',
        category: AdminRouteCategory.overview,
      ),
      const AdminRoute(
        name: 'Financial Analytics',
        route: financialAnalytics,
        icon: Icons.attach_money,
        description: 'Revenue, subscriptions, and financial metrics',
        category: AdminRouteCategory.analytics,
      ),
      const AdminRoute(
        name: 'User Management',
        route: userManagement,
        icon: Icons.people,
        description: 'Basic user management and administration',
        category: AdminRouteCategory.users,
      ),
      const AdminRoute(
        name: 'Advanced User Management',
        route: advancedUserManagement,
        icon: Icons.manage_accounts,
        description: 'Advanced user segmentation and analytics',
        category: AdminRouteCategory.users,
      ),
      const AdminRoute(
        name: 'Content Review',
        route: contentReview,
        icon: Icons.rate_review,
        description: 'Basic content moderation and review',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Enhanced Content Review',
        route: enhancedContentReview,
        icon: Icons.admin_panel_settings,
        description:
            'Advanced content moderation with bulk operations and filtering',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Advanced Content Management',
        route: advancedContentManagement,
        icon: Icons.content_copy,
        description: 'AI-powered content management and analytics',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Analytics',
        route: analytics,
        icon: Icons.analytics,
        description: 'Comprehensive platform analytics',
        category: AdminRouteCategory.analytics,
      ),
      const AdminRoute(
        name: 'Settings',
        route: adminSettings,
        icon: Icons.settings,
        description: 'Admin system configuration and settings',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'Ad Management',
        route: adManagement,
        icon: Icons.campaign,
        description: 'Manage advertisements and sponsored content',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Security Center',
        route: securityCenter,
        icon: Icons.security,
        description: 'Security monitoring and threat detection',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'Data Management',
        route: dataManagement,
        icon: Icons.backup,
        description: 'Data backup, export, and management tools',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'System Alerts',
        route: systemAlerts,
        icon: Icons.notifications,
        description: 'System notifications and monitoring alerts',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'Help & Support',
        route: helpSupport,
        icon: Icons.help_outline,
        description: 'Documentation, tutorials, and support resources',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'Data Migration',
        route: migration,
        icon: Icons.sync_alt,
        description: 'Migrate data to standardized moderation status',
        category: AdminRouteCategory.system,
      ),
    ];
  }

  /// Get routes by category
  static List<AdminRoute> getRoutesByCategory(AdminRouteCategory category) {
    return getAllRoutes().where((route) => route.category == category).toList();
  }

  /// Get quick access routes (most commonly used)
  static List<AdminRoute> getQuickAccessRoutes() {
    return [
      const AdminRoute(
        name: 'Enhanced Dashboard',
        route: enhancedDashboard,
        icon: Icons.dashboard_customize,
        description: 'Advanced dashboard with comprehensive analytics',
        category: AdminRouteCategory.overview,
      ),
      const AdminRoute(
        name: 'Financial Analytics',
        route: financialAnalytics,
        icon: Icons.attach_money,
        description: 'Revenue, subscriptions, and financial metrics',
        category: AdminRouteCategory.analytics,
      ),
      const AdminRoute(
        name: 'Advanced User Management',
        route: advancedUserManagement,
        icon: Icons.manage_accounts,
        description: 'Advanced user segmentation and analytics',
        category: AdminRouteCategory.users,
      ),
      const AdminRoute(
        name: 'Advanced Content Management',
        route: advancedContentManagement,
        icon: Icons.content_copy,
        description: 'AI-powered content management and analytics',
        category: AdminRouteCategory.content,
      ),
    ];
  }
}

/// Admin route model
class AdminRoute {
  final String name;
  final String route;
  final IconData icon;
  final String description;
  final AdminRouteCategory category;
  final bool requiresPermission;
  final List<String> permissions;

  const AdminRoute({
    required this.name,
    required this.route,
    required this.icon,
    required this.description,
    required this.category,
    this.requiresPermission = false,
    this.permissions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'route': route,
      'description': description,
      'category': category.name,
      'requiresPermission': requiresPermission,
      'permissions': permissions,
    };
  }
}

/// Admin route categories
enum AdminRouteCategory {
  overview,
  users,
  content,
  analytics,
  financial,
  system,
}

/// Extension for admin route category display names
extension AdminRouteCategoryExtension on AdminRouteCategory {
  String get displayName {
    switch (this) {
      case AdminRouteCategory.overview:
        return 'Overview';
      case AdminRouteCategory.users:
        return 'User Management';
      case AdminRouteCategory.content:
        return 'Content Management';
      case AdminRouteCategory.analytics:
        return 'Analytics';
      case AdminRouteCategory.financial:
        return 'Financial';
      case AdminRouteCategory.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminRouteCategory.overview:
        return Icons.dashboard;
      case AdminRouteCategory.users:
        return Icons.people;
      case AdminRouteCategory.content:
        return Icons.content_copy;
      case AdminRouteCategory.analytics:
        return Icons.analytics;
      case AdminRouteCategory.financial:
        return Icons.attach_money;
      case AdminRouteCategory.system:
        return Icons.settings;
    }
  }
}

/// Admin navigation helper
class AdminNavigation {
  /// Navigate to a specific admin route
  static Future<void> navigateTo(
    BuildContext context,
    String route, {
    Object? arguments,
    bool replace = false,
  }) async {
    if (replace) {
      await Navigator.of(context)
          .pushReplacementNamed(route, arguments: arguments);
    } else {
      await Navigator.of(context).pushNamed(route, arguments: arguments);
    }
  }

  /// Navigate to user detail screen
  static Future<void> navigateToUserDetail(
    BuildContext context,
    UserAdminModel user,
  ) async {
    await Navigator.of(context).pushNamed(
      AdminRoutes.userDetail,
      arguments: user,
    );
  }

  /// Navigate back to dashboard
  static void navigateBackToDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AdminRoutes.enhancedDashboard,
      (route) => false,
    );
  }

  /// Check if current route is admin route
  static bool isAdminRoute(String? routeName) {
    if (routeName == null) return false;
    return routeName.startsWith('/admin/');
  }

  /// Get current admin route category
  static AdminRouteCategory? getCurrentCategory(String? routeName) {
    if (routeName == null) return null;

    final routes = AdminRoutes.getAllRoutes();
    final currentRoute = routes.firstWhere(
      (route) => route.route == routeName,
      orElse: () => routes.first,
    );

    return currentRoute.category;
  }
}
