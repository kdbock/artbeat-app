import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: EnhancedUniversalHeader(
        title: 'Settings',
        showLogo: false,
      ),
      body: Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}
