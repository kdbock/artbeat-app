import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Widget that displays active streaks (login, challenge, category)
class StreakDisplay extends StatelessWidget {
  final int loginStreak;
  final int challengeStreak;
  final int categoryStreak;
  final String? categoryName;

  const StreakDisplay({
    super.key,
    required this.loginStreak,
    required this.challengeStreak,
    this.categoryStreak = 0,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              SizedBox(width: 6),
              Text(
                'Active Streaks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakItem('🔥', loginStreak, 'Login', Colors.orange),
              _buildStreakItem(
                '⚡',
                challengeStreak,
                'Challenge',
                Colors.yellow,
              ),
              if (categoryStreak > 0)
                _buildStreakItem(
                  '🎨',
                  categoryStreak,
                  categoryName ?? 'Category',
                  ArtbeatColors.primaryPurple,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String emoji, int count, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
