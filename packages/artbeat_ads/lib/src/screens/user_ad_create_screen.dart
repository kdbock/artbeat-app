import 'package:flutter/material.dart';
import '../models/ad_type.dart';
import 'base_ad_create_screen.dart';

/// User ad creation screen - redirects to unified architecture
class UserAdCreateScreen extends StatelessWidget {
  const UserAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.square,
      userType: 'user',
      screenTitle: 'Create User Ad',
    );
  }
}
