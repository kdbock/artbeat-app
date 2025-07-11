import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: EnhancedUniversalHeader(
        title: 'Privacy Settings',
        showLogo: false,
      ),
      body: Center(
        child: Text('Privacy Settings Screen'),
      ),
    );
  }
}
