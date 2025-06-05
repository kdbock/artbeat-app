import 'package:flutter/material.dart';

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
        backgroundImage: NetworkImage(avatarUrl),
        radius: radius,
      ),
    );
  }
}
