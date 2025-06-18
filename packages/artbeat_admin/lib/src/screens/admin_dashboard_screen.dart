import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_user_model.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRole;
  List<AdminUserModel>? _users;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminService = context.read<AdminService>();
      final users = await adminService.getUsers(
        searchQuery: _searchController.text,
        roleFilter: _selectedRole,
      );

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error loading users: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Store scaffold messenger and service before async gap
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final adminService = context.read<AdminService>();

              try {
                await adminService.signOut();
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _loadUsers(),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<UserRole>(
                  value: _selectedRole,
                  hint: const Text('Filter by role'),
                  items: UserRole.values
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.toString().split('.').last),
                        ),
                      )
                      .toList(),
                  onChanged: (role) {
                    setState(() {
                      _selectedRole = role;
                    });
                    _loadUsers();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_users == null || _users!.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return ListView.builder(
      itemCount: _users!.length,
      itemBuilder: (context, index) {
        final user = _users![index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(user.displayName?[0] ?? user.email[0].toUpperCase()),
          ),
          title: Text(user.displayName ?? user.email),
          subtitle: Text(user.role.toString().split('.').last),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  // TODO: Implement edit user dialog
                  break;
                case 'delete':
                  if (!mounted) return;
                  final adminService = context.read<AdminService>();
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text(
                        'Are you sure you want to delete this user? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await adminService.deleteUser(user.id);
                      if (mounted) {
                        await _loadUsers(); // Reload the list
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error deleting user: $e')),
                        );
                      }
                    }
                  }
                  break;
                case 'activity':
                  // TODO: Navigate to user activity screen
                  break;
                case 'payments':
                  // TODO: Navigate to user payments screen
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit User'),
                ),
              ),
              const PopupMenuItem(
                value: 'activity',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('View Activity'),
                ),
              ),
              const PopupMenuItem(
                value: 'payments',
                child: ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('View Payments'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete User',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
