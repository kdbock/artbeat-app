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
    final isEnabled =
        count < maxApplause && postId.isNotEmpty && userId.isNotEmpty;

    // Safety check for required data
    if (postId.isEmpty) {
      AppLogger.warning('⚠️ ApplauseButton: postId is empty');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(77), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.front_hand, size: 18, color: Colors.grey),
            SizedBox(width: 4),
            Text('--', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isEnabled
          ? () {
              debugPrint(
                'ApplauseButton onTap called - postId: $postId, userId: $userId, enabled: $isEnabled',
              );
              onTap();
            }
          : () {
              debugPrint(
                'ApplauseButton disabled - postId: $postId, userId: $userId, count: $count, maxApplause: $maxApplause',
              );
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: applauseColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: applauseColor.withAlpha(77), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.front_hand,
              size: 18,
              color: isEnabled ? applauseColor : applauseColor.withAlpha(128),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: isEnabled ? applauseColor : applauseColor.withAlpha(128),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
