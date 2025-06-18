import 'package:flutter/material.dart';

/// Base class for profile tab implementations
abstract class ProfileTabInterface extends StatelessWidget {
  final String userId;
  final bool isCurrentUser;

  const ProfileTabInterface({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });
}
