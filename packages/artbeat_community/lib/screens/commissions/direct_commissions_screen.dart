import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';
import 'commission_detail_screen.dart';

class DirectCommissionsScreen extends StatefulWidget {
  const DirectCommissionsScreen({super.key});

  @override
  State<DirectCommissionsScreen> createState() =>
      _DirectCommissionsScreenState();
}

class _DirectCommissionsScreenState extends State<DirectCommissionsScreen>
    with SingleTickerProviderStateMixin {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;

  List<DirectCommissionModel> _allCommissions = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to view commissions')),
          );
        }
        return;
      }

      _currentUserId = user.uid;
      final commissions = await _commissionService.getCommissionsByUser(
        user.uid,
      );

      setState(() {
        _allCommissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading commissions: $e')),
        );
      }
    }
  }

  List<DirectCommissionModel> _getCommissionsByStatus(
    List<CommissionStatus> statuses,
  ) {
    return _allCommissions.where((c) => statuses.contains(c.status)).toList();
  }

  bool _isUserArtist(DirectCommissionModel commission) {
    return commission.artistId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 3,
      scaffoldKey: _scaffoldKey,
      appBar: const core.EnhancedUniversalHeader(
        title: 'Direct Commissions',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const core.ArtbeatDrawer(),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showArtistSelection(),
          backgroundColor: CommunityColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('New Commission'),
        ),
        body: Column(
          children: [
            // Summary Cards
            if (!_isLoading) _buildSummaryCards(),

            // Tabs for filtering commissions
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending_actions, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Active (${_getCommissionsByStatus([CommissionStatus.pending, CommissionStatus.quoted, CommissionStatus.accepted, CommissionStatus.inProgress]).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Pending (${_getCommissionsByStatus([CommissionStatus.pending, CommissionStatus.quoted]).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Completed (${_getCommissionsByStatus([CommissionStatus.completed, CommissionStatus.delivered]).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list, size: 16),
                      const SizedBox(width: 4),
                      Text('All (${_allCommissions.length})'),
                    ],
                  ),
                ),
              ],
            ),

            // Commission list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Active commissions
                        _buildCommissionList(
                          _getCommissionsByStatus([
                            CommissionStatus.pending,
                            CommissionStatus.quoted,
                            CommissionStatus.accepted,
                            CommissionStatus.inProgress,
                          ]),
                        ),
                        // Pending commissions
                        _buildCommissionList(
                          _getCommissionsByStatus([
                            CommissionStatus.pending,
                            CommissionStatus.quoted,
                          ]),
                        ),
                        // Completed commissions
                        _buildCommissionList(
                          _getCommissionsByStatus([
                            CommissionStatus.completed,
                            CommissionStatus.delivered,
                          ]),
                        ),
                        // All commissions
                        _buildCommissionList(_allCommissions),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final activeCount = _getCommissionsByStatus([
      CommissionStatus.pending,
      CommissionStatus.quoted,
      CommissionStatus.accepted,
      CommissionStatus.inProgress,
    ]).length;

    final completedCount = _getCommissionsByStatus([
      CommissionStatus.completed,
      CommissionStatus.delivered,
    ]).length;

    final totalEarnings = _allCommissions
        .where(
          (c) =>
              c.artistId == _currentUserId &&
              [
                CommissionStatus.completed,
                CommissionStatus.delivered,
              ].contains(c.status),
        )
        .fold(0.0, (sum, c) => sum + c.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Active',
              activeCount.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Completed',
              completedCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Earnings',
              '\$${totalEarnings.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionList(List<DirectCommissionModel> commissions) {
    if (commissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.art_track, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No commissions found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by requesting a commission from an artist',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: commissions.length,
        itemBuilder: (context, index) {
          final commission = commissions[index];
          return _buildCommissionCard(commission);
        },
      ),
    );
  }

  Widget _buildCommissionCard(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);
    final statusColor = _getStatusColor(commission.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openCommissionDetail(commission),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commission.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isArtist
                              ? 'Client: ${commission.clientName}'
                              : 'Artist: ${commission.artistName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      commission.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Commission Details
              Row(
                children: [
                  Icon(
                    _getTypeIcon(commission.type),
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    commission.type.displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(commission.requestedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Price and Progress
              Row(
                children: [
                  if (commission.totalPrice > 0) ...[
                    Text(
                      '\$${commission.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (commission.deadline != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: _isDeadlineClose(commission.deadline!)
                          ? Colors.red.shade600
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDate(commission.deadline!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isDeadlineClose(commission.deadline!)
                            ? Colors.red.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),

              // Progress Bar for Active Commissions
              if ([
                CommissionStatus.accepted,
                CommissionStatus.inProgress,
              ].contains(commission.status)) ...[
                const SizedBox(height: 12),
                _buildProgressBar(commission),
              ],

              // Action Buttons
              if (_shouldShowActionButtons(commission)) ...[
                const SizedBox(height: 12),
                _buildActionButtons(commission),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(DirectCommissionModel commission) {
    final completedMilestones = commission.milestones
        .where(
          (m) =>
              m.status == MilestoneStatus.completed ||
              m.status == MilestoneStatus.paid,
        )
        .length;
    final totalMilestones = commission.milestones.length;
    final progress = totalMilestones > 0
        ? completedMilestones / totalMilestones
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '$completedMilestones/$totalMilestones milestones',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(CommunityColors.primary),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);

    return Row(
      children: [
        if (commission.status == CommissionStatus.pending && isArtist)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _provideQuote(commission),
              icon: const Icon(Icons.request_quote, size: 16),
              label: const Text('Provide Quote'),
            ),
          ),
        if (commission.status == CommissionStatus.quoted && !isArtist)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptCommission(commission),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Accept Quote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (commission.status == CommissionStatus.inProgress && isArtist)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markCompleted(commission),
              icon: const Icon(Icons.done, size: 16),
              label: const Text('Mark Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CommunityColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldShowActionButtons(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);
    return (commission.status == CommissionStatus.pending && isArtist) ||
        (commission.status == CommissionStatus.quoted && !isArtist) ||
        (commission.status == CommissionStatus.inProgress && isArtist);
  }

  Color _getStatusColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Colors.orange;
      case CommissionStatus.quoted:
        return Colors.blue;
      case CommissionStatus.accepted:
        return Colors.green;
      case CommissionStatus.inProgress:
        return Colors.purple;
      case CommissionStatus.revision:
        return Colors.amber;
      case CommissionStatus.completed:
        return Colors.green;
      case CommissionStatus.delivered:
        return Colors.teal;
      case CommissionStatus.cancelled:
        return Colors.red;
      case CommissionStatus.disputed:
        return Colors.red.shade800;
    }
  }

  IconData _getTypeIcon(CommissionType type) {
    switch (type) {
      case CommissionType.digital:
        return Icons.computer;
      case CommissionType.physical:
        return Icons.brush;
      case CommissionType.portrait:
        return Icons.person;
      case CommissionType.commercial:
        return Icons.business;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isDeadlineClose(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays <= 3;
  }

  void _openCommissionDetail(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommissionDetailScreen(commission: commission),
      ),
    ).then((_) => _loadCommissions());
  }

  void _showArtistSelection() {
    // TODO: Implement artist selection screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artist selection coming soon!')),
    );
  }

  Future<void> _provideQuote(DirectCommissionModel commission) async {
    // TODO: Implement quote provision screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote provision coming soon!')),
    );
  }

  Future<void> _acceptCommission(DirectCommissionModel commission) async {
    try {
      await _commissionService.acceptCommission(commission.id);
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission accepted! Proceed to payment.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting commission: $e')),
        );
      }
    }
  }

  Future<void> _markCompleted(DirectCommissionModel commission) async {
    try {
      await _commissionService.completeCommission(commission.id);
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing commission: $e')),
        );
      }
    }
  }
}
