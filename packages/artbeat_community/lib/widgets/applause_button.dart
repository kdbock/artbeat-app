import 'package:flutter/material.dart';

class ApplauseButton extends StatelessWidget {
  final String postId;
  final String userId;
  final VoidCallback onTap;
  final int count;
  final int maxApplause;

  const ApplauseButton({
    super.key,
    required this.postId,
    required this.userId,
    required this.onTap,
    required this.count,
    this.maxApplause = 5,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: count < maxApplause ? onTap : null,
      icon: const Icon(Icons.emoji_emotions_outlined),
      label: Text('$count'),
    );
  }
}
