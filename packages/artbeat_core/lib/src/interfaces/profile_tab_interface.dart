import 'package:flutter/material.dart';

/// Interface for the profile tab implementation
abstract class ProfileTabInterface extends StatelessWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileTabInterface({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });
}
