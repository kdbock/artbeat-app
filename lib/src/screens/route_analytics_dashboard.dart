import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/route_analytics_service.dart';

/// Analytics dashboard for monitoring route usage
class RouteAnalyticsDashboard extends StatefulWidget {
  const RouteAnalyticsDashboard({super.key});

  @override
  State<RouteAnalyticsDashboard> createState() =>
      _RouteAnalyticsDashboardState();
}

class _RouteAnalyticsDashboardState extends State<RouteAnalyticsDashboard> {
  final RouteAnalyticsService _analytics = RouteAnalyticsService();
  List<Map<String, dynamic>> _popularRoutes = [];
  Map<String, dynamic> _selectedRouteStats = {};
  String? _selectedRoute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final popularRoutes = await _analytics.getPopularRoutes(limit: 20);
      setState(() {
        _popularRoutes = popularRoutes;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $error')),
        );
      }
    }
  }

  Future<void> _loadRouteStats(String routeName) async {
    final stats = await _analytics.getRouteStatistics(routeName);
    setState(() {
      _selectedRoute = routeName;
      _selectedRouteStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const core.EnhancedUniversalHeader(
        title: 'Route Analytics',
        showLogo: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: _buildRoutesList()),
                      if (_selectedRoute != null) ...[
                        const VerticalDivider(width: 1),
                        Expanded(flex: 1, child: _buildRouteDetails()),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCards() {
    final totalVisits = _popularRoutes.fold<int>(
      0,
      (sum, route) => sum + (route['visit_count'] as int),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Routes',
              value: '${_popularRoutes.length}',
              icon: Icons.route,
              color: core.ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Visits',
              value: '$totalVisits',
              icon: Icons.visibility,
              color: core.ArtbeatColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Most Popular',
              value: _popularRoutes.isNotEmpty
                  ? _popularRoutes.first['route_name']
                        .toString()
                        .split('/')
                        .last
                  : 'N/A',
              icon: Icons.star,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRoutesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Routes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _popularRoutes.length,
              itemBuilder: (context, index) {
                final route = _popularRoutes[index];
                final routeName = route['route_name'] as String;
                final visitCount = route['visit_count'] as int;
                final isSelected = _selectedRoute == routeName;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected
                      ? core.ArtbeatColors.primaryPurple.withValues(alpha: 0.1)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: core.ArtbeatColors.primaryPurple,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      routeName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('$visitCount visits'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isSelected
                          ? core.ArtbeatColors.primaryPurple
                          : Colors.grey,
                    ),
                    onTap: () => _loadRouteStats(routeName),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetails() {
    if (_selectedRoute == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Route name
          _buildDetailCard(
            title: 'Route Name',
            value: _selectedRoute!,
            icon: Icons.route,
          ),

          const SizedBox(height: 16),

          // Statistics
          if (_selectedRouteStats.isNotEmpty) ...[
            _buildDetailCard(
              title: 'Visits Today',
              value: '${_selectedRouteStats['visits_today'] ?? 0}',
              icon: Icons.today,
            ),

            const SizedBox(height: 16),

            _buildDetailCard(
              title: 'Visits This Week',
              value: '${_selectedRouteStats['visits_this_week'] ?? 0}',
              icon: Icons.date_range,
            ),

            const SizedBox(height: 16),

            if (_selectedRouteStats['last_visited'] != null)
              _buildDetailCard(
                title: 'Last Visited',
                value: _formatDate(
                  _selectedRouteStats['last_visited'] as DateTime,
                ),
                icon: Icons.access_time,
              ),
          ],

          const Spacer(),

          // Actions
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, _selectedRoute!);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Visit Route'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: core.ArtbeatColors.primaryPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
