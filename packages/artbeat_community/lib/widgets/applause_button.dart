import 'package:flutter/material.dart';

class ApplauseButton extends StatelessWidget {
  final String postId;
  final String userId;
  final VoidCallback onTap;
  final int count;
  final int maxApplause;
  final Color color;

  const ApplauseButton({
    super.key,
    required this.postId,
    required this.userId,
    required this.onTap,
    required this.count,
    this.maxApplause = 5,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: count < maxApplause ? onTap : null,
      icon: Icon(Icons.emoji_emotions, color: color),
      label: Text('$count', style: TextStyle(color: color)),
    );
  }
}
