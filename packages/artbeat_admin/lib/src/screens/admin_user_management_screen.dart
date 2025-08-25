import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/user_admin_model.dart';
import '../services/admin_service.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_drawer.dart';
import 'admin_user_detail_screen.dart';

/// Screen for managing users - view, edit, suspend, delete users
class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<UserAdminModel> _users = [];
  List<UserAdminModel> _selectedUsers = [];
  bool _isLoading = true;
  String? _error;
  UserType? _filterUserType;
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = await _adminService.getAllUsers(
        limit: 100,
        orderBy: _sortBy,
        descending: _sortDescending,
        filterByType: _filterUserType,
        searchQuery: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _users = users;
          _selectedUsers.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleUserSelection(UserAdminModel user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _selectAllUsers() {
    setState(() {
      if (_selectedUsers.length == _users.length) {
        _selectedUsers.clear();
      } else {
        _selectedUsers = List.from(_users);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: AdminHeader(
        title: 'User Management',
        showBackButton: true,
        showSearch: true,
        showChat: true,
        showDeveloper: true,
        onBackPressed: () => Navigator.pop(context),
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onSearchPressed: () => Navigator.pushNamed(context, '/search'),
        onChatPressed: () => Navigator.pushNamed(context, '/messaging'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildFilters(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState()
                        : _buildUsersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name, email, or username...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _loadUsers(),
          ),
          const SizedBox(height: 12),
          // Filters row
          Row(
            children: [
              // User type filter
              Expanded(
                child: DropdownButtonFormField<UserType>(
                  initialValue: _filterUserType,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<UserType>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...UserType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterUserType = value;
                    });
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Sort options
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'createdAt', child: Text('Created Date')),
                    DropdownMenuItem(value: 'fullName', child: Text('Name')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(
                        value: 'lastActiveAt', child: Text('Last Active')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                      _loadUsers();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Sort direction
              IconButton(
                icon: Icon(_sortDescending
                    ? Icons.arrow_downward
                    : Icons.arrow_upward),
                onPressed: () {
                  setState(() {
                    _sortDescending = !_sortDescending;
                  });
                  _loadUsers();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUsers,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users found'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Select all checkbox
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Checkbox(
                value:
                    _selectedUsers.length == _users.length && _users.isNotEmpty,
                tristate: true,
                onChanged: (_) => _selectAllUsers(),
              ),
              Text('Select All (${_users.length} users)'),
              const Spacer(),
              Text('${_selectedUsers.length} selected'),
            ],
          ),
        ),
        // Users list
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final isSelected = _selectedUsers.contains(user);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleUserSelection(user),
                      ),
                      CircleAvatar(
                        backgroundColor: _getUserTypeColor(
                            _getUserTypeFromString(user.userType)),
                        child: user.profileImageUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  user.profileImageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : 'U'),
                                ),
                              )
                            : Text(user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U'),
                      ),
                    ],
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildStatusChip(user),
                          const SizedBox(width: 8),
                          _buildUserTypeChip(
                              _getUserTypeFromString(user.userType)),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleUserAction(user, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.black87),
                            SizedBox(width: 8),
                            Text('View Details',
                                style: TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit_type',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.black87),
                            SizedBox(width: 8),
                            Text('Change Type',
                                style: TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: user.isVerified ? 'unverify' : 'verify',
                        child: Row(
                          children: [
                            Icon(
                                user.isVerified ? Icons.cancel : Icons.verified,
                                color: Colors.black87),
                            const SizedBox(width: 8),
                            Text(user.isVerified ? 'Unverify' : 'Verify',
                                style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: user.isSuspended ? 'unsuspend' : 'suspend',
                        child: Row(
                          children: [
                            Icon(
                                user.isSuspended
                                    ? Icons.check_circle
                                    : Icons.block,
                                color: Colors.black87),
                            const SizedBox(width: 8),
                            Text(user.isSuspended ? 'Unsuspend' : 'Suspend',
                                style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToUserDetail(user),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(UserAdminModel user) {
    final status = user.statusText;
    final color = _getStatusColor(user.statusColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserTypeChip(UserType userType) {
    final color = _getUserTypeColor(userType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        userType.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.amber;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.red;
      case UserType.moderator:
        return Colors.orange;
      case UserType.artist:
        return Colors.purple;
      case UserType.gallery:
        return Colors.green;
      case UserType.regular:
        return Colors.blue;
    }
  }

  Future<void> _handleUserAction(UserAdminModel user, String action) async {
    try {
      switch (action) {
        case 'view':
          _navigateToUserDetail(user);
          break;
        case 'edit_type':
          _showChangeUserTypeDialog(user);
          break;
        case 'verify':
          await _adminService.verifyUser(user.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User verified successfully')),
          );
          _loadUsers();
          break;
        case 'unverify':
          await _adminService.unverifyUser(user.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unverified successfully')),
          );
          _loadUsers();
          break;
        case 'suspend':
          _showSuspendUserDialog(user);
          break;
        case 'unsuspend':
          await _adminService.unsuspendUser(user.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unsuspended successfully')),
          );
          _loadUsers();
          break;
        case 'delete':
          _showDeleteUserDialog(user);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _navigateToUserDetail(UserAdminModel user) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminUserDetailScreen(user: user),
      ),
    ).then((_) => _loadUsers());
  }

  void _showChangeUserTypeDialog(UserAdminModel user) {
    UserType? selectedType = _getUserTypeFromString(user.userType);

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change User Type for ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Current type: ${_getUserTypeFromString(user.userType).name.toUpperCase()}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserType>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'New User Type',
                  border: OutlineInputBorder(),
                ),
                items: UserType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedType != null &&
                      selectedType != _getUserTypeFromString(user.userType)
                  ? () async {
                      try {
                        await _adminService.updateUserType(
                            user.id, selectedType!);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('User type updated successfully')),
                          );
                          _loadUsers();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error updating user type: $e')),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuspendUserDialog(UserAdminModel user) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for suspension:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Suspension Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              try {
                await _adminService.suspendUser(user.id, reason, 'admin');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User suspended successfully')),
                  );
                  _loadUsers();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error suspending user: $e')),
                  );
                }
              }
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(UserAdminModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${user.fullName}'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _adminService.deleteUser(user.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                  _loadUsers();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting user: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Helper method to convert String? to UserType
  UserType _getUserTypeFromString(String? userTypeString) {
    if (userTypeString == null) return UserType.regular;
    return UserType.fromString(userTypeString);
  }
}
