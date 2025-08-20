import 'package:flutter/material.dart';
import '../models/ad_type.dart';
import 'base_ad_create_screen.dart';

/// Admin ad creation screen - redirects to unified architecture
class AdminAdCreateScreen extends StatelessWidget {
  const AdminAdCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseAdCreateScreen(
      initialAdType: AdType.square,
      userType: 'admin',
      screenTitle: 'Create Admin Ad',
    );
  }
}
