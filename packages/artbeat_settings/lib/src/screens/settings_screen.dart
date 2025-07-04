import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniversalHeader(
        title: 'Settings',
        showLogo: false,
      ),
      body: const Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}
