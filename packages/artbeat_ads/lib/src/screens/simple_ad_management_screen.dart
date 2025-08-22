import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ad_model.dart';
import '../models/ad_status.dart';
import '../models/ad_size.dart';
import '../models/ad_location.dart';
import '../services/simple_ad_service.dart';
import '../widgets/simple_ad_display_widget.dart';

/// Simplified admin screen for managing ads
class SimpleAdManagementScreen extends StatefulWidget {
  const SimpleAdManagementScreen({super.key});

  @override
  State<SimpleAdManagementScreen> createState() =>
      _SimpleAdManagementScreenState();
}

class _SimpleAdManagementScreenState extends State<SimpleAdManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SimpleAdService _adService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adService = SimpleAdService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'All Ads'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingAdsTab(),
          _buildAllAdsTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildPendingAdsTab() {
    return StreamBuilder<List<AdModel>>(
      stream: _adService.getPendingAds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No pending ads to review'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildPendingAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildAllAdsTab() {
    return StreamBuilder<List<AdModel>>(
      stream: _adService.getAllAds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return const Center(child: Text('No ads found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, int>>(
      future: _adService.getAdsStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ad Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildStatCard('Total Ads', stats['total'] ?? 0, Colors.blue),
              _buildStatCard(
                'Pending Review',
                stats['pending'] ?? 0,
                Colors.orange,
              ),
              _buildStatCard('Approved', stats['approved'] ?? 0, Colors.green),
              _buildStatCard('Rejected', stats['rejected'] ?? 0, Colors.red),
              _buildStatCard('Expired', stats['expired'] ?? 0, Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingAdCard(AdModel ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ad preview
                Container(
                  width: 80,
                  height: 60,
                  child: SimpleAdDisplayWidget(ad: ad),
                ),
                const SizedBox(width: 16),
                // Ad details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ad.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildAdDetailsText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _buildDurationText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectAd(ad),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveAd(ad),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(AdModel ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ad preview
                Container(
                  width: 80,
                  height: 60,
                  child: SimpleAdDisplayWidget(ad: ad),
                ),
                const SizedBox(width: 16),
                // Ad details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ad.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(ad.status),
                        ],
                      ),
                      Text(
                        ad.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildAdDetailsText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _buildDurationText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _buildDateRangeText(ad),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ad.status == AdStatus.approved)
                  TextButton(
                    onPressed: () => _pauseAd(ad),
                    child: const Text('Pause'),
                  ),
                if (ad.status == AdStatus.paused)
                  TextButton(
                    onPressed: () => _resumeAd(ad),
                    child: const Text('Resume'),
                  ),
                TextButton(
                  onPressed: () => _deleteAd(ad),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 4, height: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AdStatus status) {
    Color color;
    String text;

    switch (status) {
      case AdStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case AdStatus.approved:
        color = Colors.green;
        text = 'Approved';
        break;
      case AdStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case AdStatus.running:
        color = Colors.blue;
        text = 'Running';
        break;
      case AdStatus.paused:
        color = Colors.grey;
        text = 'Paused';
        break;
      case AdStatus.expired:
        color = Colors.grey.shade600;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _approveAd(AdModel ad) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _adService.approveAd(ad.id, user.uid);

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
            content: Text('Error approving ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAd(AdModel ad) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _adService.rejectAd(ad.id, user.uid);

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
            content: Text('Error rejecting ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseAd(AdModel ad) async {
    try {
      await _adService.updateAdStatus(ad.id, AdStatus.paused);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ad paused')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeAd(AdModel ad) async {
    try {
      await _adService.updateAdStatus(ad.id, AdStatus.approved);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ad resumed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming ad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAd(AdModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text(
          'Are you sure you want to delete this ad? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adService.deleteAd(ad.id);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ad deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting ad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _buildAdDetailsText(AdModel ad) {
    try {
      final typeName = ad.type.name;
      final sizeDisplay = ad.size.displayName;
      final locationDisplay = ad.location.displayName;
      return '$typeName • $sizeDisplay • $locationDisplay';
    } catch (e) {
      // Fallback if any property access fails
      return 'Ad Details • ${ad.id.substring(0, 8)}...';
    }
  }

  String _buildDurationText(AdModel ad) {
    try {
      final days = ad.duration.days;
      final pricePerDay = ad.pricePerDay;
      final totalPrice = pricePerDay * days;
      return 'Duration: $days days (\$${totalPrice.toStringAsFixed(2)})';
    } catch (e) {
      // Fallback if any calculation fails
      return 'Duration: N/A';
    }
  }

  String _buildDateRangeText(AdModel ad) {
    try {
      final startDate = _formatDate(ad.startDate);
      final endDate = _formatDate(ad.endDate);
      return 'Dates: $startDate - $endDate';
    } catch (e) {
      // Fallback if date formatting fails
      return 'Dates: N/A';
    }
  }
}
