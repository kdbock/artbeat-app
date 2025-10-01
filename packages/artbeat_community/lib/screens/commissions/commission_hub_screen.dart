import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_artist/artbeat_artist.dart';
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';
import 'direct_commissions_screen.dart';
import 'artist_commission_settings_screen.dart';
import 'commission_detail_screen.dart';
import 'commission_analytics_screen.dart';

class CommissionHubScreen extends StatefulWidget {
  const CommissionHubScreen({super.key});

  @override
  State<CommissionHubScreen> createState() => _CommissionHubScreenState();
}

class _CommissionHubScreenState extends State<CommissionHubScreen> {
  final DirectCommissionService _commissionService = DirectCommissionService();

  bool _isLoading = true;
  bool _isArtist = false;
  ArtistCommissionSettings? _artistSettings;
  List<DirectCommissionModel> _recentCommissions = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Check if user is an artist by trying to load settings
      try {
        final settings = await _commissionService.getArtistSettings(user.uid);
        setState(() {
          _isArtist = settings != null;
          _artistSettings = settings;
        });
      } catch (e) {
        // User is not an artist or hasn't set up commission settings
        setState(() => _isArtist = false);
      }

      // Load recent commissions
      final commissions = await _commissionService.getCommissionsByUser(
        user.uid,
      );
      final recentCommissions = commissions.take(5).toList();

      // Calculate stats
      final activeCount = commissions
          .where(
            (c) => [
              CommissionStatus.pending,
              CommissionStatus.quoted,
              CommissionStatus.accepted,
              CommissionStatus.inProgress,
            ].contains(c.status),
          )
          .length;

      final completedCount = commissions
          .where(
            (c) => [
              CommissionStatus.completed,
              CommissionStatus.delivered,
            ].contains(c.status),
          )
          .length;

      final totalEarnings = commissions
          .where(
            (c) =>
                c.artistId == user.uid &&
                [
                  CommissionStatus.completed,
                  CommissionStatus.delivered,
                ].contains(c.status),
          )
          .fold(0.0, (sum, c) => sum + c.totalPrice);

      setState(() {
        _recentCommissions = recentCommissions;
        _stats = {
          'active': activeCount,
          'completed': completedCount,
          'total': commissions.length,
          'earnings': totalEarnings.round(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 3,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome Card
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),

                  // Stats Cards
                  _buildStatsCards(),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 16),

                  // Artist Settings (if artist)
                  if (_isArtist) ...[
                    _buildArtistSection(),
                    const SizedBox(height: 16),
                  ],

                  // Recent Commissions
                  _buildRecentCommissions(),
                  const SizedBox(height: 16),

                  // Getting Started (if no commissions)
                  if (_stats['total'] == 0) _buildGettingStarted(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              CommunityColors.primary.withValues(alpha: 0.1),
              CommunityColors.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.palette,
                  size: 32,
                  color: CommunityColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArtist
                            ? 'Manage your commission requests and settings'
                            : 'Request custom artwork from talented artists',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isArtist) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _setupArtistProfile,
                icon: const Icon(Icons.brush),
                label: const Text('Become an Artist'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CommunityColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active',
            _stats['active']?.toString() ?? '0',
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Completed',
            _stats['completed']?.toString() ?? '0',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Total',
            _stats['total']?.toString() ?? '0',
            Icons.art_track,
            Colors.blue,
          ),
        ),
        if (_isArtist) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Earnings',
              '\$${_stats['earnings']?.toString() ?? '0'}',
              Icons.attach_money,
              Colors.purple,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
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

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'View All Commissions',
                    Icons.list,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<DirectCommissionsScreen>(
                        builder: (context) => const DirectCommissionsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Browse Artists',
                    Icons.search,
                    _browseArtists,
                  ),
                ),
              ],
            ),
            if (_isArtist) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Commission Settings',
                      Icons.settings,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<ArtistCommissionSettingsScreen>(
                          builder: (context) =>
                              const ArtistCommissionSettingsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Analytics',
                      Icons.analytics,
                      _viewAnalytics,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  Widget _buildArtistSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.brush, color: CommunityColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Artist Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_artistSettings != null) ...[
              Row(
                children: [
                  Icon(
                    _artistSettings!.acceptingCommissions
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: _artistSettings!.acceptingCommissions
                        ? Colors.green
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _artistSettings!.acceptingCommissions
                        ? 'Currently accepting commissions'
                        : 'Not accepting commissions',
                    style: TextStyle(
                      color: _artistSettings!.acceptingCommissions
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Base Price: \$${_artistSettings!.basePrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Available Types: ${_artistSettings!.availableTypes.map((t) => t.displayName).join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                'Commission settings not configured',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.orange.shade700),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<ArtistCommissionSettingsScreen>(
                    builder: (context) =>
                        const ArtistCommissionSettingsScreen(),
                  ),
                ),
                icon: const Icon(Icons.settings),
                label: const Text('Setup Commission Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CommunityColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCommissions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Commissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_recentCommissions.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<DirectCommissionsScreen>(
                        builder: (context) => const DirectCommissionsScreen(),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentCommissions.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.art_track,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No commissions yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...(_recentCommissions.map(
                (commission) => _buildCommissionTile(commission),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTile(DirectCommissionModel commission) {
    final statusColor = _getStatusColor(commission.status);
    final isArtist =
        commission.artistId == FirebaseAuth.instance.currentUser?.uid;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(
          _getStatusIcon(commission.status),
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        commission.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArtist
                ? 'Client: ${commission.clientName}'
                : 'Artist: ${commission.artistName}',
          ),
          Text(
            commission.status.displayName,
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ],
      ),
      trailing: commission.totalPrice > 0
          ? Text(
              '\$${commission.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) =>
                CommissionDetailScreen(commission: commission),
          ),
        );
      },
    );
  }

  Widget _buildGettingStarted() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.amber.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Getting Started with Commissions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isArtist
                  ? 'Set up your commission settings to start receiving requests from clients.'
                  : 'Browse artists and request custom artwork tailored to your needs.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isArtist
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute<ArtistCommissionSettingsScreen>(
                        builder: (context) =>
                            const ArtistCommissionSettingsScreen(),
                      ),
                    )
                  : _browseArtists,
              icon: Icon(_isArtist ? Icons.settings : Icons.search),
              label: Text(
                _isArtist ? 'Setup Commission Settings' : 'Browse Artists',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CommunityColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  IconData _getStatusIcon(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Icons.schedule;
      case CommissionStatus.quoted:
        return Icons.request_quote;
      case CommissionStatus.accepted:
        return Icons.handshake;
      case CommissionStatus.inProgress:
        return Icons.brush;
      case CommissionStatus.revision:
        return Icons.edit;
      case CommissionStatus.completed:
        return Icons.check_circle;
      case CommissionStatus.delivered:
        return Icons.local_shipping;
      case CommissionStatus.cancelled:
        return Icons.cancel;
      case CommissionStatus.disputed:
        return Icons.warning;
    }
  }

  void _setupArtistProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<ArtistCommissionSettingsScreen>(
        builder: (context) => const ArtistCommissionSettingsScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _browseArtists() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ArtistBrowseScreen(mode: 'commissions'),
      ),
    );
  }

  void _viewAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const CommissionAnalyticsScreen(),
      ),
    );
  }
}
