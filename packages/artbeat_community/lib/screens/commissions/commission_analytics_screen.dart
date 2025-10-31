import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';

class CommissionAnalyticsScreen extends StatefulWidget {
  const CommissionAnalyticsScreen({super.key});

  @override
  State<CommissionAnalyticsScreen> createState() =>
      _CommissionAnalyticsScreenState();
}

class _CommissionAnalyticsScreenState extends State<CommissionAnalyticsScreen> {
  final DirectCommissionService _commissionService = DirectCommissionService();

  bool _isLoading = true;
  CommissionAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final analytics = await _commissionService.getCommissionAnalytics(
          user.uid,
        );
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: CommunityColors.communityGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Commission Analytics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Track your commission performance',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      backgroundColor: CommunityColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
          ? const Center(child: Text('No analytics data available'))
          : _buildAnalyticsContent(),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Commissions',
                  _analytics!.totalCommissions.toString(),
                  Icons.assignment,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  _analytics!.completedCommissions.toString(),
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active',
                  _analytics!.activeCommissions.toString(),
                  Icons.pending,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Cancelled',
                  _analytics!.cancelledCommissions.toString(),
                  Icons.cancel,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Financial Overview
          const Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CommunityColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFinancialRow(
                    'Total Revenue',
                    '\$${_analytics!.totalRevenue.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildFinancialRow(
                    'Total Spent',
                    '\$${_analytics!.totalSpent.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildFinancialRow(
                    'Average Commission',
                    '\$${_analytics!.averageCommissionValue.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildFinancialRow(
                    'Revision Rate',
                    '${(_analytics!.revisionRate * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Monthly Trends
          if (_analytics!.monthlyTrends.isNotEmpty) ...[
            const Text(
              'Monthly Trends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CommunityColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _analytics!.monthlyTrends.map((trend) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${trend.month.month}/${trend.month.year}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text('${trend.commissionCount} commissions'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color ?? CommunityColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color ?? CommunityColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: CommunityColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CommunityColors.primary,
          ),
        ),
      ],
    );
  }
}
