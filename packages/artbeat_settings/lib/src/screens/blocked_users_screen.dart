import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: EnhancedUniversalHeader(title: 'Blocked Users', showLogo: false),
      body: Center(child: Text('Blocked Users Screen')),
    );
  }
}
