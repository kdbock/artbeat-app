import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/challenge_model.dart';

/// Enhanced Daily Quest Card Widget
/// Displays the current daily challenge with progress, rewards, and time remaining
class DailyQuestCard extends StatefulWidget {
  final ChallengeModel? challenge;
  final VoidCallback? onTap;
  final bool showTimeRemaining;
  final bool showRewardPreview;

  const DailyQuestCard({
    super.key,
    this.challenge,
    this.onTap,
    this.showTimeRemaining = true,
    this.showRewardPreview = true,
  });

  @override
  State<DailyQuestCard> createState() => _DailyQuestCardState();
}

class _DailyQuestCardState extends State<DailyQuestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.challenge == null) {
      return _buildLoadingCard();
    }

    final challenge = widget.challenge!;
    final isCompleted = challenge.isCompleted;
    final progressPercent = challenge.progressPercentage;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCompleted
                ? [
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.9),
                    ArtbeatColors.primaryGreen,
                  ]
                : [
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.9),
                    ArtbeatColors.primaryBlue,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  (isCompleted
                          ? ArtbeatColors.primaryGreen
                          : ArtbeatColors.primaryPurple)
                      .withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _QuestPatternPainter(isCompleted: isCompleted),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Quest icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getQuestIcon(challenge.title),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '🎯 DAILY QUEST',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (isCompleted) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              challenge.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // XP reward badge
                      if (widget.showRewardPreview)
                        ScaleTransition(
                          scale: isCompleted
                              ? _pulseAnimation
                              : const AlwaysStoppedAnimation(1.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${challenge.rewardXP}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    challenge.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress section
                  if (!isCompleted) ...[
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: progressPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress text and time remaining
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${challenge.currentCount}/${challenge.targetCount} ${_getProgressUnit(challenge.title)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.showTimeRemaining)
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeRemaining(challenge.expiresAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ] else ...[
                    // Completion message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.celebration,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quest Complete!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  challenge.rewardDescription,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  IconData _getQuestIcon(String title) {
    if (title.contains('Explorer') || title.contains('Discover')) {
      return Icons.explore;
    } else if (title.contains('Photo') || title.contains('Hunter')) {
      return Icons.camera_alt;
    } else if (title.contains('Walk') || title.contains('Wanderer')) {
      return Icons.directions_walk;
    } else if (title.contains('Share') || title.contains('Social')) {
      return Icons.share;
    } else if (title.contains('Community') || title.contains('Connector')) {
      return Icons.people;
    } else if (title.contains('Step')) {
      return Icons.directions_run;
    } else if (title.contains('Early Bird')) {
      return Icons.wb_sunny;
    } else if (title.contains('Night Owl')) {
      return Icons.nightlight;
    } else if (title.contains('Golden Hour')) {
      return Icons.wb_twilight;
    } else if (title.contains('Critic')) {
      return Icons.rate_review;
    } else if (title.contains('Style')) {
      return Icons.palette;
    } else if (title.contains('Streak')) {
      return Icons.local_fire_department;
    } else if (title.contains('Neighborhood')) {
      return Icons.location_city;
    }
    return Icons.flag;
  }

  String _getProgressUnit(String title) {
    if (title.contains('Walk') && title.contains('km')) {
      return 'm';
    } else if (title.contains('Step')) {
      return 'steps';
    }
    return 'completed';
  }

  String _getTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else {
      return 'Expiring soon';
    }
  }
}

/// Custom painter for quest card background pattern
class _QuestPatternPainter extends CustomPainter {
  final bool isCompleted;

  _QuestPatternPainter({required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw decorative circles
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width - 30 - (i * 40), 30 + (i * 20)),
        20 + (i * 10),
        paint,
      );
    }

    // Draw decorative lines
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0.6,
      size.height * 0.4,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
