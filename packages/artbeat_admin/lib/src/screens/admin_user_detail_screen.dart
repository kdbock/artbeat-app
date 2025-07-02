import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_admin_model.dart';
import '../services/admin_service.dart';

/// Detailed view of a user for admin management
class AdminUserDetailScreen extends StatefulWidget {
  final UserAdminModel user;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  late UserAdminModel _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUser = widget.user;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshUser() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = await _adminService.getUserById(_currentUser.id);
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing user: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser.fullName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUser,
          ),
          PopupMenuButton<String>(
            onSelected: _handleAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _currentUser.isVerified ? 'unverify' : 'verify',
                child: Row(
                  children: [
                    Icon(_currentUser.isVerified
                        ? Icons.cancel
                        : Icons.verified),
                    const SizedBox(width: 8),
                    Text(_currentUser.isVerified ? 'Unverify' : 'Verify'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _currentUser.isSuspended ? 'unsuspend' : 'suspend',
                child: Row(
                  children: [
                    Icon(_currentUser.isSuspended
                        ? Icons.check_circle
                        : Icons.block),
                    const SizedBox(width: 8),
                    Text(_currentUser.isSuspended ? 'Unsuspend' : 'Suspend'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_type',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Change Type'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit_experience',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Edit Experience'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_note',
                child: Row(
                  children: [
                    Icon(Icons.note_add),
                    SizedBox(width: 8),
                    Text('Add Note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.person)),
            Tab(text: 'Details', icon: Icon(Icons.info)),
            Tab(text: 'Activity', icon: Icon(Icons.history)),
            Tab(text: 'Admin', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDetailsTab(),
                _buildActivityTab(),
                _buildAdminTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _getUserTypeColor(_currentUser.userType),
                child: _currentUser.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _currentUser.profileImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            _currentUser.fullName.isNotEmpty
                                ? _currentUser.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _currentUser.fullName.isNotEmpty
                            ? _currentUser.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.fullName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildUserTypeChip(_currentUser.userType),
                        const SizedBox(width: 8),
                        _buildStatusChip(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Level',
                _currentUser.level.toString(),
                Icons.star,
                Colors.orange,
              ),
              _buildStatCard(
                'Experience',
                '${_currentUser.experiencePoints} XP',
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatCard(
                'Followers',
                _currentUser.followersCount.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Following',
                _currentUser.followingCount.toString(),
                Icons.person_add,
                Colors.purple,
              ),
              _buildStatCard(
                'Posts',
                _currentUser.postsCount.toString(),
                Icons.post_add,
                Colors.teal,
              ),
              _buildStatCard(
                'Captures',
                _currentUser.capturesCount.toString(),
                Icons.camera_alt,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Personal Information', [
            _buildDetailRow('Full Name', _currentUser.fullName),
            _buildDetailRow('Username', _currentUser.username ?? 'Not set'),
            _buildDetailRow('Email', _currentUser.email),
            _buildDetailRow('Location', _currentUser.location ?? 'Not set'),
            _buildDetailRow('Zip Code', _currentUser.zipCode ?? 'Not set'),
            _buildDetailRow('Gender', _currentUser.gender ?? 'Not set'),
            if (_currentUser.birthDate != null)
              _buildDetailRow('Birth Date',
                  '${_currentUser.birthDate!.day}/${_currentUser.birthDate!.month}/${_currentUser.birthDate!.year}'),
          ]),
          const SizedBox(height: 24),
          _buildDetailSection('Account Information', [
            _buildDetailRow(
                'User Type', _currentUser.userType.name.toUpperCase()),
            _buildDetailRow('Status', _currentUser.statusText),
            _buildDetailRow('Verified', _currentUser.isVerified ? 'Yes' : 'No'),
            _buildDetailRow(
                'Created At', _formatDateTime(_currentUser.createdAt)),
            if (_currentUser.updatedAt != null)
              _buildDetailRow(
                  'Updated At', _formatDateTime(_currentUser.updatedAt!)),
            if (_currentUser.lastActiveAt != null)
              _buildDetailRow(
                  'Last Active', _formatDateTime(_currentUser.lastActiveAt!)),
            if (_currentUser.lastLoginAt != null)
              _buildDetailRow(
                  'Last Login', _formatDateTime(_currentUser.lastLoginAt!)),
          ]),
          if (_currentUser.bio != null && _currentUser.bio!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('Biography', [
              Text(_currentUser.bio!),
            ]),
          ],
          if (_currentUser.achievements.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('Achievements', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentUser.achievements
                    .map((achievement) => Chip(
                          label: Text(achievement),
                          backgroundColor: Colors.amber.shade100,
                        ))
                    .toList(),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Activity timeline would go here
          // For now, show basic activity info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (_currentUser.lastActiveAt != null)
                    _buildActivityItem(
                      'Last Active',
                      _formatDateTime(_currentUser.lastActiveAt!),
                      Icons.access_time,
                      Colors.green,
                    ),
                  if (_currentUser.lastLoginAt != null)
                    _buildActivityItem(
                      'Last Login',
                      _formatDateTime(_currentUser.lastLoginAt!),
                      Icons.login,
                      Colors.blue,
                    ),
                  _buildActivityItem(
                    'Account Created',
                    _formatDateTime(_currentUser.createdAt),
                    Icons.person_add,
                    Colors.purple,
                  ),
                  if (_currentUser.updatedAt != null)
                    _buildActivityItem(
                      'Profile Updated',
                      _formatDateTime(_currentUser.updatedAt!),
                      Icons.edit,
                      Colors.orange,
                    ),
                  _buildActivityItem(
                    'Active User',
                    _currentUser.isActiveUser ? 'Yes' : 'No',
                    Icons.check_circle,
                    _currentUser.isActiveUser ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_currentUser.isSuspended) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'User Suspended',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (_currentUser.suspensionReason != null) ...[
                      const SizedBox(height: 8),
                      Text('Reason: ${_currentUser.suspensionReason}'),
                    ],
                    if (_currentUser.suspendedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          'Suspended: ${_formatDateTime(_currentUser.suspendedAt!)}'),
                    ],
                    if (_currentUser.suspendedBy != null) ...[
                      const SizedBox(height: 4),
                      Text('By: ${_currentUser.suspendedBy}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildAdminActionTile(
                    'Report Count',
                    '${_currentUser.reportCount} reports',
                    Icons.report,
                    Colors.red,
                  ),
                  _buildAdminActionTile(
                    'Admin Flags',
                    '${_currentUser.adminFlags.length} flags',
                    Icons.flag,
                    Colors.orange,
                  ),
                  _buildAdminActionTile(
                    'Email Verified',
                    _currentUser.emailVerifiedAt != null ? 'Yes' : 'No',
                    Icons.email,
                    _currentUser.emailVerifiedAt != null
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildAdminActionTile(
                    'Password Reset Required',
                    _currentUser.requiresPasswordReset ? 'Yes' : 'No',
                    Icons.lock_reset,
                    _currentUser.requiresPasswordReset
                        ? Colors.red
                        : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          if (_currentUser.adminNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Notes',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ..._currentUser.adminNotes.entries.map((entry) {
                      final noteData = entry.value as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              noteData['note']?.toString() ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By: ${noteData['addedBy'] ?? 'Unknown'} • ${noteData['addedAt'] != null ? _formatDateTime((noteData['addedAt'] as Timestamp).toDate()) : 'Unknown time'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
          if (_currentUser.adminFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Flags',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentUser.adminFlags
                          .map((flag) => Chip(
                                label: Text(flag),
                                backgroundColor: Colors.red.shade100,
                                labelStyle:
                                    TextStyle(color: Colors.red.shade700),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionTile(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  Widget _buildStatusChip() {
    final status = _currentUser.statusText;
    final color = _getStatusColor(_currentUser.statusColor);

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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAction(String action) async {
    // Implementation for handling actions would go here
    // Similar to the user management screen actions
    debugPrint('Handling action: $action for user: ${_currentUser.id}');
  }
}
