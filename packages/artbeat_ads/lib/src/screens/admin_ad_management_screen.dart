import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_admin/artbeat_admin.dart';
import '../models/ad_model.dart';
import '../models/ad_status.dart';
import '../models/ad_type.dart';
import '../models/ad_display_type.dart';
import '../services/ad_service.dart';
import '../widgets/ad_display_widget.dart';
import '../widgets/ad_status_widget.dart';

/// Comprehensive admin screen for ad management with stats and approvals
class AdminAdManagementScreen extends StatefulWidget {
  const AdminAdManagementScreen({super.key});

  @override
  State<AdminAdManagementScreen> createState() =>
      _AdminAdManagementScreenState();
}

class _AdminAdManagementScreenState extends State<AdminAdManagementScreen>
    with TickerProviderStateMixin {
  final AdService _adService = AdService();
  late TabController _tabController;

  List<AdModel> _allAds = [];
  List<AdModel> _pendingAds = [];
  List<AdModel> _approvedAds = [];
  List<AdModel> _rejectedAds = [];
  List<AdModel> _runningAds = [];
  List<AdModel> _expiredAds = [];

  bool _loading = true;
  String? _error;

  // Stats
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Listen to all ads stream
      _adService.getAllAds().listen((ads) {
        if (mounted) {
          setState(() {
            _allAds = ads;
            _categorizeAds();
            _calculateStats();
            _loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ads: $e';
          _loading = false;
        });
      }
    }
  }

  void _categorizeAds() {
    _pendingAds = _allAds.where((ad) => ad.status == AdStatus.pending).toList();
    _approvedAds = _allAds
        .where((ad) => ad.status == AdStatus.approved)
        .toList();
    _rejectedAds = _allAds
        .where((ad) => ad.status == AdStatus.rejected)
        .toList();
    _runningAds = _allAds.where((ad) => ad.status == AdStatus.running).toList();
    _expiredAds = _allAds.where((ad) => ad.status == AdStatus.expired).toList();
  }

  void _calculateStats() {
    _stats = {
      'total': _allAds.length,
      'pending': _pendingAds.length,
      'approved': _approvedAds.length,
      'rejected': _rejectedAds.length,
      'running': _runningAds.length,
      'expired': _expiredAds.length,
      'totalRevenue': _calculateTotalRevenue(),
      'activeRevenue': _calculateActiveRevenue(),
    };
  }

  int _calculateTotalRevenue() {
    return _allAds
        .where(
          (ad) =>
              ad.status == AdStatus.running || ad.status == AdStatus.expired,
        )
        .fold(
          0,
          (sum, ad) => sum + (ad.pricePerDay * ad.duration.days).round(),
        );
  }

  int _calculateActiveRevenue() {
    return _runningAds.fold(
      0,
      (sum, ad) => sum + (ad.pricePerDay * ad.duration.days).round(),
    );
  }

  Future<void> _approveAd(AdModel ad) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Ad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to approve "${ad.title}"?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Approval Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _adService.updateAd(ad.id, {
          'status': AdStatus.running.index, // Changed from approved to running
          'approvalId': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          'approvedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve ad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectAd(AdModel ad) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Ad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to reject "${ad.title}"?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection *',
                  border: OutlineInputBorder(),
                  hintText: 'Please provide a reason...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for rejection'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _adService.updateAd(ad.id, {
          'status': AdStatus.rejected.index,
          'approvalId': reasonController.text.trim(),
          'rejectedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject ad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAd(AdModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ad'),
          content: Text(
            'Are you sure you want to permanently delete "${ad.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _adService.deleteAd(ad.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad deleted permanently'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete ad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _activateAd(AdModel ad) async {
    try {
      await _adService.updateAd(ad.id, {
        'status': AdStatus.running.index,
        'startDate': DateTime.now(),
        'activatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad activated successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewAdDetails(AdModel ad) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Ad Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ad Preview
                        AdDisplayWidget(
                          imageUrl: ad.imageUrl,
                          artworkUrls: ad.artworkUrls,
                          title: ad.title,
                          description: ad.description,
                          displayType: ad.type == AdType.square
                              ? AdDisplayType.square
                              : AdDisplayType.rectangle,
                        ),

                        const SizedBox(height: 16),

                        // Details
                        _buildDetailRow('Title', ad.title),
                        _buildDetailRow('Description', ad.description),
                        _buildDetailRow('Status', ad.status.name.toUpperCase()),
                        _buildDetailRow('Type', ad.type.name.toUpperCase()),
                        _buildDetailRow(
                          'Location',
                          ad.location.name.toUpperCase(),
                        ),
                        _buildDetailRow('Duration', '${ad.duration.days} days'),
                        _buildDetailRow(
                          'Price per Day',
                          '\$${ad.pricePerDay.toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Total Price',
                          '\$${(ad.pricePerDay * ad.duration.days).toStringAsFixed(2)}',
                        ),
                        _buildDetailRow(
                          'Start Date',
                          ad.startDate.toLocal().toString(),
                        ),
                        _buildDetailRow(
                          'End Date',
                          ad.endDate.toLocal().toString(),
                        ),
                        if (ad.approvalId != null)
                          _buildDetailRow(
                            ad.status == AdStatus.rejected
                                ? 'Rejection Reason'
                                : 'Approval Notes',
                            ad.approvalId!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatsCard(
                'Total Ads',
                _stats['total']?.toString() ?? '0',
                Icons.campaign,
                Colors.blue,
              ),
              _buildStatsCard(
                'Pending Approval',
                _stats['pending']?.toString() ?? '0',
                Icons.schedule,
                Colors.orange,
              ),
              _buildStatsCard(
                'Currently Running',
                _stats['running']?.toString() ?? '0',
                Icons.play_circle,
                Colors.green,
              ),
              _buildStatsCard(
                'Total Revenue',
                '\$${_stats['totalRevenue']?.toString() ?? '0'}',
                Icons.attach_money,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdsList(List<AdModel> ads, String emptyMessage) {
    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(emptyMessage, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('All caught up!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ad.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('Type: ${ad.type.name}'),
                      Text('Location: ${ad.location.name}'),
                      Text('Duration: ${ad.duration.days} days'),
                      Text('Price: \$${ad.pricePerDay.toStringAsFixed(2)}/day'),
                      Text(
                        'Start: ${ad.startDate.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AdStatusWidget(status: ad.status),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _viewAdDetails(ad),
                      icon: const Icon(Icons.visibility),
                      tooltip: 'View Details',
                    ),
                    if (ad.status == AdStatus.pending) ...[
                      IconButton(
                        onPressed: () => _approveAd(ad),
                        icon: const Icon(Icons.check_circle),
                        color: Colors.green,
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        onPressed: () => _rejectAd(ad),
                        icon: const Icon(Icons.cancel),
                        color: Colors.orange,
                        tooltip: 'Reject',
                      ),
                    ],
                    if (ad.status == AdStatus.approved) ...[
                      IconButton(
                        onPressed: () => _activateAd(ad),
                        icon: const Icon(Icons.play_circle),
                        color: Colors.blue,
                        tooltip: 'Activate',
                      ),
                    ],
                    IconButton(
                      onPressed: () => _deleteAd(ad),
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: AdminHeader(
        title: 'Ad Management',
        showBackButton: true,
        showSearch: true,
        showChat: true,
        showDeveloper: true,
        onMenuPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        onBackPressed: () {
          // Navigate back to admin dashboard
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        },
        onSearchPressed: () => Navigator.pushNamed(context, '/search'),
        onChatPressed: () => Navigator.pushNamed(context, '/messaging'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF8FBFF),
              Color(0xFFE1F5FE),
              Color(0xFFBBDEFB),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAds,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Tab bar
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: [
                        const Tab(
                          icon: Icon(Icons.dashboard),
                          text: 'Overview',
                        ),
                        Tab(
                          icon: const Icon(Icons.schedule),
                          text: 'Pending (${_stats['pending'] ?? 0})',
                        ),
                        Tab(
                          icon: const Icon(Icons.check_circle),
                          text: 'Approved (${_stats['approved'] ?? 0})',
                        ),
                        Tab(
                          icon: const Icon(Icons.play_circle),
                          text: 'Running (${_stats['running'] ?? 0})',
                        ),
                        Tab(
                          icon: const Icon(Icons.cancel),
                          text: 'Rejected (${_stats['rejected'] ?? 0})',
                        ),
                        Tab(
                          icon: const Icon(Icons.history),
                          text: 'Expired (${_stats['expired'] ?? 0})',
                        ),
                      ],
                    ),
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStatsOverview(),
                        _buildAdsList(_pendingAds, 'No pending ads'),
                        _buildAdsList(_approvedAds, 'No approved ads'),
                        _buildAdsList(_runningAds, 'No running ads'),
                        _buildAdsList(_rejectedAds, 'No rejected ads'),
                        _buildAdsList(_expiredAds, 'No expired ads'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAds,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
