import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'profile_view_screen.dart';

/// Profile tab implementation that uses ProfileViewScreen
class ProfileTab extends ProfileTabInterface {
  const ProfileTab({
    super.key,
    required super.userId,
    super.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileViewScreen(
      userId: userId,
      isCurrentUser: isCurrentUser,
    );
  }
}
