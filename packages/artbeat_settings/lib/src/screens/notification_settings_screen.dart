import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniversalHeader(
        title: 'Notification Settings',
        showLogo: false,
      ),
      body: const Center(child: Text('Notification Settings Screen')),
    );
  }
}
