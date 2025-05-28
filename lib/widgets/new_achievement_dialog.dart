import 'package:flutter/material.dart';
import 'package:artbeat/models/achievement_model.dart';
import 'package:artbeat/widgets/achievement_badge.dart';

/// Widget to display a newly earned achievement with animation
class NewAchievementDialog extends StatefulWidget {
  final AchievementModel achievement;
  final VoidCallback onDismiss;

  const NewAchievementDialog({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  // Static method to show the dialog
  static Future<void> show(
    BuildContext context,
    AchievementModel achievement,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewAchievementDialog(
        achievement: achievement,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<NewAchievementDialog> createState() => _NewAchievementDialogState();
}

class _NewAchievementDialogState extends State<NewAchievementDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Achievement badge
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: AchievementBadge(
                  achievement: widget.achievement,
                  size: 120,
                ),
              ),

              // Achievement title
              const Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Achievement details
              Text(
                widget.achievement.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.achievement.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
