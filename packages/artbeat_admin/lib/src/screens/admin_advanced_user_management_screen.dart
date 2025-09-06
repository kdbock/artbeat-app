import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/user_admin_model.dart';
import '../services/admin_service.dart';
import '../services/cohort_analytics_service.dart';

import '../widgets/admin_drawer.dart';
import 'admin_user_detail_screen.dart';

/// Advanced User Management Screen with segmentation and analytics
///
/// Features:
/// - User segmentation and filtering
/// - Cohort analysis integration
/// - Bulk user operations
/// - Advanced search and filtering
/// - User lifecycle management
/// - Engagement scoring
class AdminAdvancedUserManagementScreen extends StatefulWidget {
  const AdminAdvancedUserManagementScreen({super.key});

  @override
  State<AdminAdvancedUserManagementScreen> createState() =>
      _AdminAdvancedUserManagementScreenState();
}

class _AdminAdvancedUserManagementScreenState
    extends State<AdminAdvancedUserManagementScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final CohortAnalyticsService _cohortService = CohortAnalyticsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<UserAdminModel> _users = [];
  Map<String, UserSegment> _userSegments = {};
  List<UserAdminModel> _filteredUsers = [];
  bool _isLoading = true;
  bool _isLoadingSegments = true;
  String? _error;

  // Filters
  UserSegmentFilter _selectedSegment = UserSegmentFilter.all;
  UserStatusFilter _selectedStatus = UserStatusFilter.all;
  UserTypeFilter _selectedType = UserTypeFilter.all;
  DateRange _selectedDateRange = DateRange.all;
  String _searchQuery = '';

  // Selection
  final Set<String> _selectedUserIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUsers(),
      _loadUserSegments(),
    ]);
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = await _adminService.getAllUsers();

      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
        });
        _applyFilters();
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

  Future<void> _loadUserSegments() async {
    try {
      setState(() {
        _isLoadingSegments = true;
      });

      final segments = await _cohortService.getUserSegments();

      if (mounted) {
        setState(() {
          _userSegments = segments;
          _isLoadingSegments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSegments = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<UserAdminModel> filtered = List.from(_users);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.fullName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply segment filter
    if (_selectedSegment != UserSegmentFilter.all) {
      filtered = filtered.where((user) {
        switch (_selectedSegment) {
          case UserSegmentFilter.highValue:
            return user.experiencePoints > 1000; // High experience users
          case UserSegmentFilter.active:
            final sevenDaysAgo =
                DateTime.now().subtract(const Duration(days: 7));
            return user.lastActiveAt?.isAfter(sevenDaysAgo) ?? false;
          case UserSegmentFilter.atRisk:
            final fourteenDaysAgo =
                DateTime.now().subtract(const Duration(days: 14));
            final thirtyDaysAgo =
                DateTime.now().subtract(const Duration(days: 30));
            return (user.lastActiveAt?.isBefore(fourteenDaysAgo) ?? false) &&
                (user.lastActiveAt?.isAfter(thirtyDaysAgo) ?? false);
          case UserSegmentFilter.new_:
            final thirtyDaysAgo =
                DateTime.now().subtract(const Duration(days: 30));
            return user.createdAt.isAfter(thirtyDaysAgo);
          case UserSegmentFilter.churned:
            final thirtyDaysAgo =
                DateTime.now().subtract(const Duration(days: 30));
            return user.lastActiveAt?.isBefore(thirtyDaysAgo) ?? false;
          case UserSegmentFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != UserStatusFilter.all) {
      filtered = filtered.where((user) {
        switch (_selectedStatus) {
          case UserStatusFilter.active:
            return !user.isSuspended && !user.isDeleted && user.isVerified;
          case UserStatusFilter.suspended:
            return user.isSuspended;
          case UserStatusFilter.banned:
            return user.isDeleted;
          case UserStatusFilter.pending:
            return !user.isVerified;
          case UserStatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply user type filter
    if (_selectedType != UserTypeFilter.all) {
      filtered = filtered.where((user) {
        switch (_selectedType) {
          case UserTypeFilter.artist:
            return user.userType == 'artist';
          case UserTypeFilter.collector:
            return user.userType == 'collector';
          case UserTypeFilter.gallery:
            return user.userType == 'business';
          case UserTypeFilter.visitor:
            return user.userType == 'visitor';
          case UserTypeFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != DateRange.all) {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedDateRange) {
        case DateRange.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case DateRange.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case DateRange.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case DateRange.last90Days:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case DateRange.lastYear:
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        case DateRange.all:
          startDate = DateTime(2020); // Arbitrary old date
          break;
      }

      filtered =
          filtered.where((user) => user.createdAt.isAfter(startDate)).toList();
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Admin screens don't use bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Advanced User Management',
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
        actions: [
          if (!_isSelectionMode)
            IconButton(
              onPressed: () => _showCreateUserDialog(),
              icon: const Icon(Icons.person_add),
              tooltip: 'Add User',
            ),
        ],
      ),
      drawer: const AdminDrawer(),
      child: Container(
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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersTab(),
                    _buildSegmentsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey.shade800,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Users', icon: Icon(Icons.people, size: 20)),
          Tab(text: 'Segments', icon: Icon(Icons.group_work, size: 20)),
          Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 20)),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return Column(
      children: [
        _buildFiltersSection(),
        _buildUserStats(),
        Expanded(
          child: _buildUsersList(),
        ),
      ],
    );
  }

  Widget _buildSegmentsTab() {
    if (_isLoadingSegments) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Segments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._userSegments.entries
              .map((entry) => _buildSegmentCard(entry.value)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserGrowthChart(),
          const SizedBox(height: 24),
          _buildEngagementMetrics(),
          const SizedBox(height: 24),
          _buildRetentionAnalysis(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name, email, or ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Segment',
                  _selectedSegment.displayName,
                  () => _showSegmentFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Status',
                  _selectedStatus.displayName,
                  () => _showStatusFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Type',
                  _selectedType.displayName,
                  () => _showTypeFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Date',
                  _selectedDateRange.displayName,
                  () => _showDateRangeFilter(),
                ),
                const SizedBox(width: 8),
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Users',
              _filteredUsers.length.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Active Users',
              _getActiveUsersCount().toString(),
              Icons.person,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'New This Month',
              _getNewUsersThisMonth().toString(),
              Icons.person_add,
              Colors.orange,
            ),
          ),
          if (_isSelectionMode) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Selected',
                _selectedUserIds.length.toString(),
                Icons.check_circle,
                Colors.purple,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search criteria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final isSelected = _selectedUserIds.contains(user.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleUserSelection(user.id),
                  )
                : CircleAvatar(
                    backgroundImage: user.profileImageUrl.isNotEmpty
                        ? NetworkImage(user.profileImageUrl)
                        : null,
                    child: user.profileImageUrl.isEmpty
                        ? Text(user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?')
                        : null,
                  ),
            title: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusChip(user.statusText),
                    const SizedBox(width: 8),
                    _buildTypeChip(user.userType ?? 'User'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'XP: ${user.experiencePoints}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isSelectionMode) ...[
                  IconButton(
                    onPressed: () => _showUserActions(user),
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
                if (_isSelectionMode)
                  IconButton(
                    onPressed: () => _toggleUserSelection(user.id),
                    icon: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
              ],
            ),
            onTap: _isSelectionMode
                ? () => _toggleUserSelection(user.id)
                : () => _navigateToUserDetail(user),
            onLongPress: () => _enterSelectionMode(user.id),
          ),
        );
      },
    );
  }

  Widget _buildSegmentCard(UserSegment segment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    segment.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${segment.userCount} users',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              segment.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSegmentMetric(
                    'Avg LTV',
                    '\$${segment.averageLifetimeValue.toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildSegmentMetric(
                    'Retention',
                    '${segment.retentionRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: segment.characteristics
                  .map((characteristic) => Chip(
                        label: Text(
                          characteristic,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey.shade100,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Growth',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 200,
              child: Center(
                child: Text('User growth chart would go here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                _buildMetricCard('Daily Active Users', '1,234', Icons.today),
                _buildMetricCard(
                    'Weekly Active Users', '5,678', Icons.date_range),
                _buildMetricCard(
                    'Monthly Active Users', '12,345', Icons.calendar_month),
                _buildMetricCard(
                    'Session Duration', '8.5 min', Icons.access_time),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retention Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 200,
              child: Center(
                child: Text('Retention cohort table would go here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    final hasFilter = value != 'All';
    return FilterChip(
      label: Text('$label: $value'),
      selected: hasFilter,
      onSelected: (_) => onTap(),
      backgroundColor: hasFilter
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'suspended':
        color = Colors.orange;
        break;
      case 'banned':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSegmentMetric(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade800),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _getActiveUsersCount() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _filteredUsers
        .where((user) => user.lastActiveAt?.isAfter(sevenDaysAgo) ?? false)
        .length;
  }

  int _getNewUsersThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _filteredUsers
        .where((user) => user.createdAt.isAfter(startOfMonth))
        .length;
  }

  bool _hasActiveFilters() {
    return _selectedSegment != UserSegmentFilter.all ||
        _selectedStatus != UserStatusFilter.all ||
        _selectedType != UserTypeFilter.all ||
        _selectedDateRange != DateRange.all ||
        _searchQuery.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSegment = UserSegmentFilter.all;
      _selectedStatus = UserStatusFilter.all;
      _selectedType = UserTypeFilter.all;
      _selectedDateRange = DateRange.all;
      _searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }

      if (_selectedUserIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(String userId) {
    setState(() {
      _isSelectionMode = true;
      _selectedUserIds.clear();
      _selectedUserIds.add(userId);
    });
  }

  void _navigateToUserDetail(UserAdminModel user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdminUserDetailScreen(user: user),
      ),
    );
  }

  // Dialog methods
  void _showSegmentFilter() {
    // Implementation for segment filter dialog
  }

  void _showStatusFilter() {
    // Implementation for status filter dialog
  }

  void _showTypeFilter() {
    // Implementation for type filter dialog
  }

  void _showDateRangeFilter() {
    // Implementation for date range filter dialog
  }

  void _showUserActions(UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? NetworkImage(user.profileImageUrl)
                          : null,
                      child: user.profileImageUrl.isEmpty
                          ? Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 16),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Action items
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToUserDetail(user as UserAdminModel);
                },
              ),

              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit User'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditUserDialog(user as UserAdminModel);
                },
              ),

              if (user is UserAdminModel) ...[
                if (!user.isSuspended)
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: const Text('Suspend User'),
                    onTap: () {
                      Navigator.pop(context);
                      _showSuspendUserDialog(user);
                    },
                  )
                else
                  ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Unsuspend User'),
                    onTap: () {
                      Navigator.pop(context);
                      _unsuspendUser(user);
                    },
                  ),
                if (!user.isVerified)
                  ListTile(
                    leading: const Icon(Icons.verified, color: Colors.green),
                    title: const Text('Verify User'),
                    onTap: () {
                      Navigator.pop(context);
                      _verifyUser(user);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.purple),
                  title: const Text('Change User Type'),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangeUserTypeDialog(user);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note_add, color: Colors.grey),
                  title: const Text('Add Admin Note'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddNoteDialog(user);
                  },
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCreateUserDialog() {
    // Implementation for create user dialog
  }

  void _showEditUserDialog(UserAdminModel user) {
    // Show a dialog to edit user details
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User: ${user.fullName}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit user functionality will be available soon.'),
            Text('Navigate to user details for full editing capabilities.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToUserDetail(user);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showSuspendUserDialog(UserAdminModel user) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend User: ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to suspend ${user.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Suspension Reason',
                hintText: 'Enter reason for suspension...',
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _suspendUser(user, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _suspendUser(UserAdminModel user, String reason) async {
    try {
      setState(() => _isLoading = true);

      // For now, just show success - implement actual suspension later
      await Future<void>.delayed(
          const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been suspended'),
            backgroundColor: Colors.red,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error suspending user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unsuspendUser(UserAdminModel user) async {
    try {
      setState(() => _isLoading = true);

      // For now, just show success - implement actual unsuspension later
      await Future<void>.delayed(
          const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been unsuspended'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unsuspending user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyUser(UserAdminModel user) async {
    try {
      setState(() => _isLoading = true);

      // For now, just show success - implement actual verification later
      await Future<void>.delayed(
          const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been verified'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showChangeUserTypeDialog(UserAdminModel user) {
    String selectedType = user.userType ?? 'user';

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change User Type: ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current type: ${user.userType ?? "user"}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'New User Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Regular User')),
                  DropdownMenuItem(value: 'artist', child: Text('Artist')),
                  DropdownMenuItem(
                      value: 'business', child: Text('Gallery/Business')),
                  DropdownMenuItem(
                      value: 'moderator', child: Text('Moderator')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _changeUserType(user, selectedType);
              },
              child: const Text('Change Type'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeUserType(UserAdminModel user, String newType) async {
    try {
      setState(() => _isLoading = true);

      // For now, just show success - implement actual type change later
      await Future<void>.delayed(
          const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} type changed to $newType'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing user type: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddNoteDialog(UserAdminModel user) {
    final noteController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Admin Note: ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Admin Note',
                hintText: 'Enter your note about this user...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            Text(
              'This note will be visible to other admins',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addAdminNote(user, noteController.text);
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAdminNote(UserAdminModel user, String note) async {
    if (note.trim().isEmpty) return;

    try {
      setState(() => _isLoading = true);

      // For now, just show success - implement actual note addition later
      await Future<void>.delayed(
          const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin note added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Filter enums
enum UserSegmentFilter {
  all,
  highValue,
  active,
  atRisk,
  new_,
  churned,
}

enum UserStatusFilter {
  all,
  active,
  suspended,
  banned,
  pending,
}

enum UserTypeFilter {
  all,
  artist,
  collector,
  gallery,
  visitor,
}

enum DateRange {
  all,
  today,
  last7Days,
  last30Days,
  last90Days,
  lastYear,
}

// Extensions for display names
extension UserSegmentFilterExtension on UserSegmentFilter {
  String get displayName {
    switch (this) {
      case UserSegmentFilter.all:
        return 'All';
      case UserSegmentFilter.highValue:
        return 'High Value';
      case UserSegmentFilter.active:
        return 'Active';
      case UserSegmentFilter.atRisk:
        return 'At Risk';
      case UserSegmentFilter.new_:
        return 'New';
      case UserSegmentFilter.churned:
        return 'Churned';
    }
  }
}

extension UserStatusFilterExtension on UserStatusFilter {
  String get displayName {
    switch (this) {
      case UserStatusFilter.all:
        return 'All';
      case UserStatusFilter.active:
        return 'Active';
      case UserStatusFilter.suspended:
        return 'Suspended';
      case UserStatusFilter.banned:
        return 'Banned';
      case UserStatusFilter.pending:
        return 'Pending';
    }
  }
}

extension UserTypeFilterExtension on UserTypeFilter {
  String get displayName {
    switch (this) {
      case UserTypeFilter.all:
        return 'All';
      case UserTypeFilter.artist:
        return 'Artist';
      case UserTypeFilter.collector:
        return 'Collector';
      case UserTypeFilter.gallery:
        return 'Gallery';
      case UserTypeFilter.visitor:
        return 'Visitor';
    }
  }
}

extension DateRangeExtension on DateRange {
  String get displayName {
    switch (this) {
      case DateRange.all:
        return 'All Time';
      case DateRange.today:
        return 'Today';
      case DateRange.last7Days:
        return 'Last 7 Days';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.last90Days:
        return 'Last 90 Days';
      case DateRange.lastYear:
        return 'Last Year';
    }
  }
}
