import 'package:flutter/material.dart';

/// Reusable metrics card widget for admin dashboard
class AdminMetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;
  final String? subtitle;
  final VoidCallback? onTap;

  const AdminMetricsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  if (trend != null) _buildTrendIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    if (trend == null || trend == 0) {
      return Icon(
        Icons.trending_flat,
        color: Colors.grey[400],
        size: 16,
      );
    }

    final isPositive = trend! > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 2),
        Text(
          '${trend!.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
