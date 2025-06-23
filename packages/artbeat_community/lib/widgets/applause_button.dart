import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ApplauseButton extends StatelessWidget {
  final String postId;
  final String userId;
  final VoidCallback onTap;
  final int count;
  final int maxApplause;
  final Color? color;

  const ApplauseButton({
    super.key,
    required this.postId,
    required this.userId,
    required this.onTap,
    required this.count,
    this.maxApplause = 5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final applauseColor = color ?? ArtbeatColors.accentYellow;
    
    return TextButton.icon(
      onPressed: count < maxApplause ? onTap : null,
      icon: Icon(Icons.front_hand, color: applauseColor),
      label: Text(
        '$count', 
        style: TextStyle(
          color: applauseColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
