import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../services/simple_ad_service.dart';

/// Simple ad statistics screen showing key metrics
class SimpleAdStatisticsScreen extends StatefulWidget {
  const SimpleAdStatisticsScreen({super.key});

  @override
  State<SimpleAdStatisticsScreen> createState() =>
      _SimpleAdStatisticsScreenState();
}

class _SimpleAdStatisticsScreenState extends State<SimpleAdStatisticsScreen> {
  late SimpleAdService _adService;
  Map<String, int>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _adService = SimpleAdService();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _adService.getAdsStatistics();
      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshStatistics() async {
    setState(() => _isLoading = true);
    await _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // No bottom navigation for this screen
      appBar: EnhancedUniversalHeader(
        title: 'Ad Statistics',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatistics,
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics == null
          ? const Center(
              child: Text(
                'Failed to load statistics',
                style: TextStyle(fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ad System Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Real-time statistics for the simplified ad system',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    _buildStatisticsGrid(),
                    const SizedBox(height: 32),
                    _buildStatusBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsGrid() {
    final stats = _statistics!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Ads', stats['total'] ?? 0, Colors.blue),
        _buildStatCard('Pending Review', stats['pending'] ?? 0, Colors.orange),
        _buildStatCard('Approved', stats['approved'] ?? 0, Colors.green),
        _buildStatCard('Rejected', stats['rejected'] ?? 0, Colors.red),
        _buildStatCard('Expired', stats['expired'] ?? 0, Colors.grey),
        _buildStatCard(
          'Active',
          (stats['approved'] ?? 0) - (stats['expired'] ?? 0),
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    final stats = _statistics!;
    final total = stats['total'] ?? 0;

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No ads created yet',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusBar(
              'Pending',
              stats['pending'] ?? 0,
              total,
              Colors.orange,
            ),
            _buildStatusBar(
              'Approved',
              stats['approved'] ?? 0,
              total,
              Colors.green,
            ),
            _buildStatusBar(
              'Rejected',
              stats['rejected'] ?? 0,
              total,
              Colors.red,
            ),
            _buildStatusBar(
              'Expired',
              stats['expired'] ?? 0,
              total,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total > 0 ? count / total : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '$count ($percentage%)',
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
