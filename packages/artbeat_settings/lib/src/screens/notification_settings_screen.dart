import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: EnhancedUniversalHeader(
        title: 'Notification Settings',
        showLogo: false,
      ),
      body: Center(child: Text('Notification Settings Screen')),
    );
  }
}
