import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarWidget extends StatelessWidget {
  final String avatarUrl;
  final double radius;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.avatarUrl,
    this.radius = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        radius: radius,
        child: ClipOval(
          child: (avatarUrl.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: radius * 2,
                    height: radius * 2,
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: radius * 2,
                    height: radius * 2,
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 25),
                    child: const Center(
                      child: Icon(Icons.person, size: 24, color: Colors.grey),
                    ),
                  ),
                )
              : const Icon(Icons.person, size: 24, color: Colors.grey),
        ),
      ),
    );
  }
}
