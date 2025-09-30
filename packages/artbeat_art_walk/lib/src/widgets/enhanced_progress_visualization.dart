import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced progress visualization widget with animated indicators
class EnhancedProgressVisualization extends StatefulWidget {
  final int visitedCount;
  final int totalCount;
  final double progressPercentage;
  final bool isNavigationMode;
  final VoidCallback? onTap;

  const EnhancedProgressVisualization({
    super.key,
    required this.visitedCount,
    required this.totalCount,
    required this.progressPercentage,
    this.isNavigationMode = false,
    this.onTap,
  });

  @override
  State<EnhancedProgressVisualization> createState() =>
      _EnhancedProgressVisualizationState();
}

class _EnhancedProgressVisualizationState
    extends State<EnhancedProgressVisualization>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.progressPercentage).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start progress animation
    _progressController.forward();
  }

  @override
  void didUpdateWidget(EnhancedProgressVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.progressPercentage != widget.progressPercentage) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progressPercentage,
            end: widget.progressPercentage,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );

      _progressController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress: ${widget.visitedCount}/${widget.totalCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.isNavigationMode)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'NAV',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Enhanced progress bar with animated rings
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  // Circular progress indicator
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: CircularProgressPainter(
                            progress: _progressAnimation.value,
                            isCompleted: widget.progressPercentage >= 1.0,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Linear progress bar with gradient
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[200],
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: widget.progressPercentage >= 1.0
                                          ? [
                                              Colors.green,
                                              Colors.green.shade300,
                                            ]
                                          : [Colors.blue, Colors.blue.shade300],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 4),

                        // Progress percentage text
                        Text(
                          '${(widget.progressPercentage * 100).round()}% Complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Achievement indicators
            if (widget.progressPercentage >= 1.0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Walk Completed! 🎉',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ] else if (widget.visitedCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.visitedCount} art piece${widget.visitedCount == 1 ? '' : 's'} discovered!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
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
}

/// Custom painter for circular progress indicator
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isCompleted;

  CircularProgressPainter({required this.progress, this.isCompleted = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = isCompleted ? Colors.green : Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      progressAngle,
      false,
      progressPaint,
    );

    // Center dot for completed walks
    if (isCompleted) {
      final centerDotPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, 6, centerDotPaint);
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isCompleted != isCompleted;
  }
}

/// Mini progress indicator for compact views
class MiniProgressIndicator extends StatelessWidget {
  final int visitedCount;
  final int totalCount;
  final double progressPercentage;

  const MiniProgressIndicator({
    super.key,
    required this.visitedCount,
    required this.totalCount,
    required this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small circular progress
          SizedBox(
            width: 24,
            height: 24,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: progressPercentage,
                isCompleted: progressPercentage >= 1.0,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Progress text
          Text(
            '$visitedCount/$totalCount',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
