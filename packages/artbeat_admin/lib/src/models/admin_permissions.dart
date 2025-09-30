import 'package:flutter/foundation.dart';

/// Admin role definitions for payment management
enum AdminRole {
  superAdmin, // Full access to all features
  financeAdmin, // Payment management, refunds, financial reports
  supportAdmin, // View payments, basic actions, user support
  auditor, // Read-only access for compliance
  contentAdmin, // Content management only (no payment access)
}

/// Admin permissions for payment system
class AdminPermissions {
  final AdminRole role;

  const AdminPermissions(this.role);

  /// Check if admin can view payment data
  bool get canViewPayments => role != AdminRole.contentAdmin;

  /// Check if admin can process refunds
  bool get canProcessRefunds =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin;

  /// Check if admin can export payment data
  bool get canExportData =>
      role == AdminRole.superAdmin ||
      role == AdminRole.financeAdmin ||
      role == AdminRole.auditor;

  /// Check if admin can modify payment records
  bool get canModifyPayments =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin;

  /// Check if admin can view sensitive payment details
  bool get canViewSensitiveData =>
      role == AdminRole.superAdmin ||
      role == AdminRole.financeAdmin ||
      role == AdminRole.auditor;

  /// Check if admin can access audit logs
  bool get canAccessAuditLogs =>
      role == AdminRole.superAdmin || role == AdminRole.auditor;

  /// Check if admin can perform bulk operations
  bool get canPerformBulkOperations =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin;

  /// Check if admin can manage payment methods
  bool get canManagePaymentMethods =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin;

  /// Check if admin can view analytics
  bool get canViewAnalytics => role != AdminRole.contentAdmin;

  /// Check if admin can configure system settings
  bool get canConfigureSystem => role == AdminRole.superAdmin;

  /// Get list of allowed actions for this role
  List<String> get allowedActions {
    final actions = <String>[];

    if (canViewPayments) actions.add('view_payments');
    if (canProcessRefunds) actions.add('process_refunds');
    if (canExportData) actions.add('export_data');
    if (canModifyPayments) actions.add('modify_payments');
    if (canViewSensitiveData) actions.add('view_sensitive_data');
    if (canAccessAuditLogs) actions.add('access_audit_logs');
    if (canPerformBulkOperations) actions.add('bulk_operations');
    if (canManagePaymentMethods) actions.add('manage_payment_methods');
    if (canViewAnalytics) actions.add('view_analytics');
    if (canConfigureSystem) actions.add('configure_system');

    return actions;
  }

  /// Check if admin has permission for specific action
  bool hasPermission(String action) {
    return allowedActions.contains(action);
  }

  /// Get role display name
  String get displayName {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super Administrator';
      case AdminRole.financeAdmin:
        return 'Finance Administrator';
      case AdminRole.supportAdmin:
        return 'Support Administrator';
      case AdminRole.auditor:
        return 'Auditor';
      case AdminRole.contentAdmin:
        return 'Content Administrator';
    }
  }

  /// Get role description
  String get description {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Full access to all system features and configurations';
      case AdminRole.financeAdmin:
        return 'Manage payments, refunds, and financial reporting';
      case AdminRole.supportAdmin:
        return 'View payments and provide user support';
      case AdminRole.auditor:
        return 'Read-only access for compliance and auditing';
      case AdminRole.contentAdmin:
        return 'Manage content with no payment access';
    }
  }

  /// Check if role has elevated privileges
  bool get isElevated =>
      role == AdminRole.superAdmin || role == AdminRole.financeAdmin;

  /// Check if role is read-only
  bool get isReadOnly =>
      role == AdminRole.auditor || role == AdminRole.contentAdmin;
}

/// Admin user model with role information
class AdminUser {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    this.metadata = const {},
  });

  AdminPermissions get permissions => AdminPermissions(role);

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: AdminRole.values.firstWhere(
        (r) => r.name == (map['role'] as String? ?? 'supportAdmin'),
        orElse: () => AdminRole.supportAdmin,
      ),
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      lastLogin: (map['lastLogin'] as DateTime?) ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    AdminRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Service for managing admin roles and permissions
class AdminRoleService extends ChangeNotifier {
  final List<AdminUser> _admins = [];

  /// Get current admin user (would be implemented with auth service)
  AdminUser? getCurrentAdmin() {
    // TODO(admin): Implement with actual authentication
    // For now, return a mock admin for development
    return AdminUser(
      id: 'admin_123',
      email: 'admin@artbeat.com',
      name: 'Admin User',
      role: AdminRole.superAdmin,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLogin: DateTime.now(),
      isActive: true,
    );
  }

  /// Check if current admin has permission for action
  bool hasPermission(String action) {
    final admin = getCurrentAdmin();
    return admin?.permissions.hasPermission(action) ?? false;
  }

  /// Get list of admins (for super admin management)
  List<AdminUser> getAdmins() {
    return _admins.where((admin) => admin.isActive).toList();
  }

  /// Update admin role (super admin only)
  Future<void> updateAdminRole(String adminId, AdminRole newRole) async {
    final currentAdmin = getCurrentAdmin();
    if (currentAdmin?.role != AdminRole.superAdmin) {
      throw Exception('Only super admins can modify roles');
    }

    // TODO(admin): Implement with Firestore
    debugPrint('Updated admin $adminId to role $newRole');
  }

  /// Get role statistics
  Map<AdminRole, int> getRoleStatistics() {
    final stats = <AdminRole, int>{};
    for (final admin in _admins) {
      stats[admin.role] = (stats[admin.role] ?? 0) + 1;
    }
    return stats;
  }

  /// Validate role transition
  bool canTransitionRole(AdminRole from, AdminRole to) {
    // Define allowed role transitions
    const allowedTransitions = {
      AdminRole.supportAdmin: [AdminRole.financeAdmin, AdminRole.auditor],
      AdminRole.financeAdmin: [AdminRole.superAdmin, AdminRole.supportAdmin],
      AdminRole.auditor: [AdminRole.supportAdmin],
      AdminRole.contentAdmin: [AdminRole.supportAdmin],
      AdminRole.superAdmin: [
        AdminRole.financeAdmin
      ], // Can demote but not promote others
    };

    return allowedTransitions[from]?.contains(to) ?? false;
  }
}
