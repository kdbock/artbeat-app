import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:intl/intl.dart' as intl;
import '../widgets/admin_drawer.dart';

/// Admin Ads Management Screen
///
/// Comprehensive advertising system administration interface with ad approval,
/// revenue tracking, bulk operations, and performance analytics.
class AdminAdsManagementScreen extends StatefulWidget {
  const AdminAdsManagementScreen({super.key});

  @override
  State<AdminAdsManagementScreen> createState() =>
      _AdminAdsManagementScreenState();
}

class _AdminAdsManagementScreenState extends State<AdminAdsManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Services
  final SimpleAdService _adService = SimpleAdService();

  // State management
  List<AdModel> _pendingAds = [];
  List<AdModel> _allAds = [];
  final Map<String, bool> _selectedAds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    try {
      // Stream all ads from the service
      _adService.getAllAds().listen((ads) {
        if (mounted) {
          setState(() {
            _allAds = ads;
            _pendingAds =
                ads.where((ad) => ad.status == AdStatus.pending).toList();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ads: $e')),
        );
      }
    }
  }

  Future<void> _approveAd(String adId) async {
    try {
      await _adService.updateAd(adId, {'status': AdStatus.approved.index});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving ad: $e')),
        );
      }
    }
  }

  Future<void> _rejectAd(String adId, String reason) async {
    try {
      await _adService.updateAd(adId, {
        'status': AdStatus.rejected.index,
        'rejectionReason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting ad: $e')),
        );
      }
    }
  }

  Future<void> _bulkApproveAds() async {
    final selectedAdIds = _selectedAds.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedAdIds.isEmpty) return;

    try {
      for (final adId in selectedAdIds) {
        await _adService.updateAd(adId, {'status': AdStatus.approved.index});
      }
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedAdIds.length} ads approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bulk approving ads: $e')),
        );
      }
    }
  }

  Future<void> _bulkRejectAds(String reason) async {
    final selectedAdIds = _selectedAds.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedAdIds.isEmpty) return;

    try {
      for (final adId in selectedAdIds) {
        await _adService.updateAd(adId, {
          'status': AdStatus.rejected.index,
          'rejectionReason': reason,
        });
      }
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedAdIds.length} ads rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bulk rejecting ads: $e')),
        );
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedAds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: const EnhancedUniversalHeader(
        title: 'Ads Management',
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
      ),
      body: Column(
        children: [
          // Admin header with purple branding
          Material(
            color: const Color(0xFF8C52FF),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00BF63),
              unselectedLabelColor:
                  const Color(0xFF00BF63).withValues(alpha: 0.7),
              indicatorColor: const Color(0xFF00BF63),
              tabs: const [
                Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
                Tab(text: 'All Ads', icon: Icon(Icons.ads_click)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                Tab(text: 'Revenue', icon: Icon(Icons.attach_money)),
              ],
            ),
          ),

          // Action bar for bulk operations
          if (_isSelectionMode) _buildActionBar(),

          // Search and filter bar
          _buildSearchAndFilterBar(),

          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingAdsTab(),
                _buildAllAdsTab(),
                _buildAnalyticsTab(),
                _buildRevenueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final selectedCount =
        _selectedAds.values.where((selected) => selected).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF8C52FF).withValues(alpha: 0.1),
      child: Row(
        children: [
          Text('$selectedCount selected'),
          const Spacer(),
          TextButton.icon(
            onPressed: _bulkApproveAds,
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text('Approve'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _showBulkRejectDialog(),
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Reject'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _clearSelection,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search ads...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              DropdownMenuItem(value: 'expired', child: Text('Expired')),
            ],
            onChanged: (value) {
              setState(() => _selectedFilter = value ?? 'all');
              _loadAds();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAdsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingAds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ads_click, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending ads',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'All ads have been reviewed',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingAds.length,
      itemBuilder: (context, index) {
        final ad = _pendingAds[index];
        return _buildAdCard(ad, isPending: true);
      },
    );
  }

  Widget _buildAllAdsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Selection toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => _isSelectionMode = !_isSelectionMode);
                  if (!_isSelectionMode) _clearSelection();
                },
                icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
                label: Text(
                    _isSelectionMode ? 'Cancel Selection' : 'Select Multiple'),
              ),
              const Spacer(),
              Text('Total Ads: ${_allAds.length}'),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _allAds.length,
            itemBuilder: (context, index) {
              final ad = _allAds[index];
              return _buildAdCard(ad);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdCard(AdModel ad, {bool isPending = false}) {
    final isSelected = _selectedAds[ad.id] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedAds[ad.id] = value ?? false;
                  });
                },
              )
            : CircleAvatar(
                backgroundColor: _getAdStatusColor(ad.status),
                child: Icon(
                  _getAdStatusIcon(ad.status),
                  color: Colors.white,
                  size: 16,
                ),
              ),
        title: Text(
          ad.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advertiser: ${ad.ownerId}'),
            Text('Price/Day: \$${ad.pricePerDay.toStringAsFixed(2)}'),
            Text('Status: ${ad.status.name.toUpperCase()}'),
            Text('Start: ${ad.startDate.toString().substring(0, 16)}'),
          ],
        ),
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _approveAd(ad.id),
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () => _showRejectDialog(ad.id),
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Reject',
                  ),
                ],
              )
            : IconButton(
                onPressed: () => _showAdDetails(ad),
                icon: const Icon(Icons.more_vert),
              ),
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  _selectedAds[ad.id] = !isSelected;
                });
              }
            : () => _showAdDetails(ad),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Ad Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Analytics dashboard coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Revenue Tracking',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Revenue dashboard coming soon',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getAdStatusColor(AdStatus status) {
    switch (status) {
      case AdStatus.approved:
      case AdStatus.running:
        return Colors.green;
      case AdStatus.rejected:
        return Colors.red;
      case AdStatus.pending:
        return Colors.orange;
      case AdStatus.expired:
        return Colors.grey;
      case AdStatus.paused:
        return Colors.blue;
      case AdStatus.draft:
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }

  IconData _getAdStatusIcon(AdStatus status) {
    switch (status) {
      case AdStatus.approved:
      case AdStatus.running:
        return Icons.check_circle;
      case AdStatus.rejected:
        return Icons.cancel;
      case AdStatus.pending:
        return Icons.pending;
      case AdStatus.expired:
        return Icons.history;
      case AdStatus.paused:
        return Icons.pause_circle;
      case AdStatus.draft:
        return Icons.edit;
      default:
        return Icons.help_outline;
    }
  }

  void _showAdDetails(AdModel ad) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ad.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Advertiser: ${ad.ownerId}'),
              const SizedBox(height: 8),
              Text('Budget: \$${ad.pricePerDay.toStringAsFixed(2)}/day'),
              const SizedBox(height: 8),
              Text('Status: ${ad.status.name.toUpperCase()}'),
              const SizedBox(height: 8),
              Text(
                  'Start Date: ${intl.DateFormat('MMM dd, yyyy').format(ad.startDate)}'),
              const SizedBox(height: 8),
              Text(
                  'End Date: ${intl.DateFormat('MMM dd, yyyy').format(ad.endDate)}'),
              const SizedBox(height: 8),
              Text('Target Location: ${ad.location}'),
              const SizedBox(height: 8),
              if (ad.description.isNotEmpty)
                Text('Description: ${ad.description}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (ad.status == AdStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveAd(ad.id);
              },
              child:
                  const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showRejectDialog(ad.id);
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(String adId) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Ad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectAd(adId, reasonController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showBulkRejectDialog() {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Reject Ads'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting selected ads:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bulkRejectAds(reasonController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject Selected'),
          ),
        ],
      ),
    );
  }
}
